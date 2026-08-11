"""Build a smooth, asymmetric damper-force lookup matrix for MATLAB.

The digitized dyno traces contain points on both sides of zero.  Do not use a
cubic spline on those points: small digitizing errors close to zero then cause
large, nonphysical force overshoots.  Each compression and rebound trace is
instead interpolated independently with a monotone, shape-preserving spline.
This keeps the measured low-speed knee (and its corresponding damping-ratio
variation) without the oscillation produced by a cubic spline.
"""

from pathlib import Path

import numpy as np
import pandas as pd
from scipy.interpolate import PchipInterpolator
from scipy.io import savemat


DATA_FILE = Path("damper_sweep_dataset.csv")
OUTPUT_FILE = Path("damper_3D_matrix.mat")

# Standard MATLAB lookup vector, in mm/s.
VEL_MM = np.linspace(-250.0, 250.0, 501)
# The source plots are digitized images, so this spacing retains the damper
# trend while rejecting individual-pixel noise near zero velocity.
SHAPE_KNOTS_MM = np.linspace(0.0, 250.0, 11)

# Columns are zero-based positions in the CSV after its X/Y row is used as
# the header.  The 4.3 high-speed setting is the reference condition in the
# low-speed sweep.
LS_SETTINGS = np.array([0.0, 2.0, 4.0, 6.0, 10.0, 15.0, 25.0])
LS_POS_COLS = [0, 2, 4, 6, 8, 10, 12]
LS_NEG_COLS = [26, 24, 22, 20, 18, 16, 14]

HS_SETTINGS = np.array([0.0, 1.0, 2.0, 3.0, 4.3])
HS_POS_COLS = [36, 34, 32, 30, 28]
HS_NEG_COLS = [38, 40, 42, 44, 46]


def get_side_points(df, velocity_col, force_col, side):
    """Return one signed sweep as positive velocity/force magnitudes.

    WebPlotDigitizer occasionally leaves a point from the other side of a
    trace at the end of a CSV column.  Requiring the expected force sign
    removes those points before fitting.  The model is constrained to pass
    through (0, 0), which is required for a damper force lookup used in ODEs.
    """
    velocity = df.iloc[:, velocity_col].dropna().astype(float).to_numpy()
    force = df.iloc[:, force_col].dropna().astype(float).to_numpy()

    if side == "compression":
        keep = (velocity > 0.0) & (force > 0.0)
        velocity_abs = velocity[keep]
        force_abs = force[keep]
    elif side == "rebound":
        # The raw rebound velocity may be exported as a positive magnitude.
        velocity_abs = np.abs(velocity)
        keep = (velocity_abs > 0.0) & (force < 0.0)
        velocity_abs = velocity_abs[keep]
        force_abs = -force[keep]
    else:
        raise ValueError(f"Unknown side: {side}")

    if velocity_abs.size < 3:
        raise ValueError(
            f"Not enough valid {side} points in columns {velocity_col}/{force_col}."
        )

    order = np.argsort(velocity_abs)
    return velocity_abs[order], force_abs[order]


def interpolate_side(velocity_abs, force_abs, query_velocity_abs):
    """Return a smooth, monotonic force magnitude at the requested speeds."""
    # Insert the physically required zero-force point, combine any duplicate
    # digitizer points, and remove tiny backwards steps from trace noise.
    velocity_abs = np.concatenate(([0.0], velocity_abs))
    force_abs = np.concatenate(([0.0], force_abs))
    unique_velocity, inverse = np.unique(velocity_abs, return_inverse=True)
    unique_force = np.array(
        [np.median(force_abs[inverse == index]) for index in range(unique_velocity.size)]
    )
    unique_force = np.maximum.accumulate(unique_force)

    interpolant = PchipInterpolator(unique_velocity, unique_force, extrapolate=False)

    def evaluate_raw_curve(query):
        clamped_query = np.clip(query, unique_velocity[0], unique_velocity[-1])
        result = interpolant(clamped_query)

        # The plot data sometimes ends a few mm/s before 250.  Extend only
        # the final local trend rather than allowing polynomial extrapolation.
        beyond_data = query > unique_velocity[-1]
        terminal_slope = (
            (unique_force[-1] - unique_force[-2])
            / (unique_velocity[-1] - unique_velocity[-2])
        )
        result[beyond_data] = unique_force[-1] + terminal_slope * (
            query[beyond_data] - unique_velocity[-1]
        )
        return result

    # Re-sample every trace on the same 25 mm/s knot vector before its final
    # PCHIP.  Directly evaluating image-pixel points near zero makes F/v
    # artificially noisy, even when the force curve itself is well behaved.
    knot_force = evaluate_raw_curve(SHAPE_KNOTS_MM)
    return PchipInterpolator(SHAPE_KNOTS_MM, knot_force)(query_velocity_abs)


def get_curve(df, pos_col, neg_col):
    """Interpolate independent compression/rebound traces and join at zero."""
    pos_velocity, pos_force = get_side_points(df, pos_col, pos_col + 1, "compression")
    neg_velocity, neg_force = get_side_points(df, neg_col, neg_col + 1, "rebound")

    curve = np.zeros_like(VEL_MM)
    compression = VEL_MM > 0.0
    rebound = VEL_MM < 0.0
    curve[compression] = interpolate_side(
        pos_velocity, pos_force, VEL_MM[compression]
    )
    curve[rebound] = -interpolate_side(
        neg_velocity, neg_force, -VEL_MM[rebound]
    )
    return curve


def build_matrix():
    df = pd.read_csv(DATA_FILE, header=1)

    # Low-speed curves are all measured at HSC/HSR = 4.3.
    low_speed_curves = {
        setting: get_curve(df, pos_col, neg_col)
        for setting, pos_col, neg_col in zip(LS_SETTINGS, LS_POS_COLS, LS_NEG_COLS)
    }

    # High-speed curves are all measured at LSC/LSR = 0.
    high_speed_curves = {
        setting: get_curve(df, pos_col, neg_col)
        for setting, pos_col, neg_col in zip(HS_SETTINGS, HS_POS_COLS, HS_NEG_COLS)
    }

    # Use the high-speed sweep's own 4.3 curve as its reference.  A direct
    # additive delta can make a soft low-speed setting change force sign when
    # a high-speed setting is opened.  Therefore apply that delta as a local
    # force ratio instead: it is equivalent to a normalized delta, retains
    # both measured boundary sweeps, and guarantees dissipative force signs.
    hs_reference = high_speed_curves[4.3]
    force_3d = np.empty((VEL_MM.size, LS_SETTINGS.size, HS_SETTINGS.size))
    for ls_index, ls_setting in enumerate(LS_SETTINGS):
        for hs_index, hs_setting in enumerate(HS_SETTINGS):
            high_speed_ratio = np.ones_like(VEL_MM)
            nonzero_reference = np.abs(hs_reference) > 1e-9
            high_speed_ratio[nonzero_reference] = (
                high_speed_curves[hs_setting][nonzero_reference]
                / hs_reference[nonzero_reference]
            )
            force_3d[:, ls_index, hs_index] = (
                low_speed_curves[ls_setting] * high_speed_ratio
            )

            # Multiplying independently digitized sweeps can leave a small
            # local reversal.  Enforce the physical requirement that damping
            # force increases continuously as relative velocity increases.
            rebound = VEL_MM < 0.0
            compression = VEL_MM > 0.0
            force_3d[rebound, ls_index, hs_index] = np.maximum.accumulate(
                force_3d[rebound, ls_index, hs_index]
            )
            force_3d[compression, ls_index, hs_index] = np.maximum.accumulate(
                force_3d[compression, ls_index, hs_index]
            )

    # A damper must exert zero force at zero relative velocity.  Retain this
    # explicit invariant after superposition to prevent any numerical drift.
    force_3d[VEL_MM == 0.0, :, :] = 0.0
    return force_3d


if __name__ == "__main__":
    force_3d = build_matrix()
    savemat(
        OUTPUT_FILE,
        {
            "vel_mm": VEL_MM.reshape(1, -1),
            "ls_settings": LS_SETTINGS.reshape(1, -1),
            "hs_settings": HS_SETTINGS.reshape(1, -1),
            "Force_3D": force_3d,
        },
    )
    print(f"Wrote {OUTPUT_FILE} with shape {force_3d.shape}.")
