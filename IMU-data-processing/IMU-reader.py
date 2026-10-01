#!/usr/bin/env python3
"""Parse three-axis IMU acceleration CSV exports and save overview and g-g plots.

Each CSV is expected to contain ``timestamp,value`` rows, with an axis encoded
in its file name (for example ``...-acceleration_x.csv``).  The timestamp is
assumed to be milliseconds when the median sample interval is greater than 10;
otherwise it is treated as seconds.  The plot always uses elapsed time, so the
absolute start time in the export does not matter.

Acceleration defaults to mg. The g-g projection defaults to sensor Z horizontally
and sensor Y vertically. Use --lateral-axis and --longitudinal-axis together to
label a confirmed vehicle-axis mapping. Raw samples are not filtered or corrected
for sensor bias, mounting tilt, or gravity.

Examples
--------
    # Run from the repository root.  uv supplies matplotlib for this command.
    uv run --with matplotlib python IMU-data-processing/IMU-reader.py \
        IMU-data-processing/IMU-data-First-Motor-Spin

    # Choose where to write the PNG and override timestamp units if needed.
    uv run --with matplotlib python IMU-data-processing/IMU-reader.py \
        IMU-data-processing/IMU-data-First-Motor-Spin \
        --output artifacts/first-motor-spin-imu.png --time-unit milliseconds

    # Rear node mounted vertically: inspect all axis pairs before assigning directions.
    uv run --with matplotlib python IMU-data-processing/IMU-reader.py \
        IMU-data-processing/9-20_testing_data --time-unit milliseconds \
        --acceleration-unit mg
"""

from __future__ import annotations

import argparse
import csv
import math
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from statistics import median
from typing import Literal

import matplotlib

# This is a command-line report generator; a display server is not required.
matplotlib.use("Agg")
import matplotlib.pyplot as plt


Axis = Literal["x", "y", "z"]
AXES: tuple[Axis, Axis, Axis] = ("x", "y", "z")
AXIS_COLORS = {"x": "#0072B2", "y": "#D55E00", "z": "#009E73"}


@dataclass(frozen=True)
class ImuSeries:
    """Acceleration samples aligned by timestamp across the three axes."""

    timestamps: list[float]
    values: dict[Axis, list[float]]
    time_seconds: list[float]
    sample_rate_hz: float


def axis_from_filename(path: Path) -> str | None:
    """Return x, y, or z when it appears as a distinct suffix in *path*."""

    match = re.search(r"(?:^|[_-])([xyz])(?:$|[_-])", path.stem.lower())
    return match.group(1) if match else None


def read_axis_csv(path: Path) -> dict[float, float]:
    """Read one timestamp/value export, reporting malformed input precisely."""

    samples: dict[float, float] = {}
    with path.open(newline="", encoding="utf-8-sig") as csv_file:
        reader = csv.DictReader(csv_file)
        if not reader.fieldnames or not {"timestamp", "value"}.issubset(reader.fieldnames):
            raise ValueError("expected CSV headers named 'timestamp' and 'value'")

        for line_number, row in enumerate(reader, start=2):
            try:
                timestamp = float(row["timestamp"])
                value = float(row["value"])
            except (KeyError, TypeError, ValueError) as error:
                raise ValueError(f"line {line_number} has a non-numeric timestamp or value") from error
            if not math.isfinite(timestamp) or not math.isfinite(value):
                raise ValueError(f"line {line_number} has a non-finite timestamp or value")
            if timestamp in samples:
                raise ValueError(f"line {line_number} repeats timestamp {timestamp:g}")
            samples[timestamp] = value

    if not samples:
        raise ValueError("contains no samples")
    return samples


def find_axis_files(input_directory: Path) -> dict[Axis, Path]:
    """Find exactly one CSV for each acceleration axis."""

    matches: dict[Axis, list[Path]] = {axis: [] for axis in AXES}
    for path in input_directory.glob("*.csv"):
        axis = axis_from_filename(path)
        if axis in matches:
            matches[axis].append(path)

    problems: list[str] = []
    for axis in AXES:
        if not matches[axis]:
            problems.append(f"no {axis}-axis CSV found")
        elif len(matches[axis]) > 1:
            names = ", ".join(path.name for path in matches[axis])
            problems.append(f"multiple {axis}-axis CSVs found: {names}")
    if problems:
        raise ValueError("; ".join(problems))

    return {axis: matches[axis][0] for axis in AXES}


def timestamp_scale(interval: float, time_unit: str) -> float:
    """Convert a source timestamp interval into seconds."""

    if time_unit == "auto":
        return 0.001 if interval > 10 else 1.0
    return {"seconds": 1.0, "milliseconds": 0.001, "microseconds": 0.000001}[time_unit]


def parse_imu(input_directory: Path, time_unit: str) -> ImuSeries:
    """Parse and timestamp-align the three acceleration CSV exports."""

    axis_files = find_axis_files(input_directory)
    data = {axis: read_axis_csv(axis_files[axis]) for axis in AXES}
    shared_timestamps = sorted(set.intersection(*(set(data[axis]) for axis in AXES)))
    if len(shared_timestamps) < 2:
        raise ValueError("fewer than two timestamps are shared by all three axes")
    for axis in AXES:
        dropped = len(data[axis]) - len(shared_timestamps)
        if dropped:
            print(f"Warning: excluded {dropped} unaligned {axis}-axis samples", file=sys.stderr)

    intervals = [
        current - previous
        for previous, current in zip(shared_timestamps, shared_timestamps[1:])
        if current > previous
    ]
    if not intervals:
        raise ValueError("timestamps must increase")

    sample_interval = median(intervals)
    scale = timestamp_scale(sample_interval, time_unit)
    elapsed = [(timestamp - shared_timestamps[0]) * scale for timestamp in shared_timestamps]
    return ImuSeries(
        timestamps=shared_timestamps,
        values={axis: [data[axis][timestamp] for timestamp in shared_timestamps] for axis in AXES},
        time_seconds=elapsed,
        sample_rate_hz=1 / (sample_interval * scale),
    )


def plot_imu(series: ImuSeries, output_path: Path, title: str, acceleration_unit: str = "mg") -> None:
    """Create a four-panel acceleration plot, one panel per component plus norm."""

    figure, axes = plt.subplots(4, 1, figsize=(12, 10), sharex=True, layout="constrained")
    figure.suptitle(
        f"{title}\n{len(series.timestamps):,} aligned samples  •  estimated sampling rate: {series.sample_rate_hz:.2f} Hz"
    )

    for axis_name, axis_plot in zip(AXES, axes[:3]):
        axis_plot.plot(series.time_seconds, series.values[axis_name], color=AXIS_COLORS[axis_name], linewidth=1)
        axis_plot.set_ylabel(f"{axis_name.upper()} acceleration\n({acceleration_unit})")
        axis_plot.grid(alpha=0.3)

    magnitude = [
        (x_value**2 + y_value**2 + z_value**2) ** 0.5
        for x_value, y_value, z_value in zip(series.values["x"], series.values["y"], series.values["z"])
    ]
    axes[3].plot(series.time_seconds, magnitude, color="#4D4D4D", linewidth=1, label="√(x² + y² + z²)")
    axes[3].set_ylabel(f"Magnitude\n({acceleration_unit})")
    axes[3].set_xlabel("Elapsed time (s)")
    axes[3].grid(alpha=0.3)
    axes[3].legend(loc="upper right")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    figure.savefig(output_path, dpi=180, bbox_inches="tight")
    plt.close(figure)


def plot_gg(series: ImuSeries, output_path: Path, title: str, args: argparse.Namespace) -> None:
    """Plot paired raw samples in g with equal scales and reference circles."""

    lateral_axis = args.lateral_axis or "z"
    longitudinal_axis = args.longitudinal_axis or "y"
    confirmed_mapping = args.lateral_axis is not None
    scale = {"mg": 0.001, "g": 1.0, "m/s2": 1 / 9.80665}[args.acceleration_unit]
    horizontal = [value * scale * args.lateral_sign for value in series.values[lateral_axis]]
    vertical = [value * scale * args.longitudinal_sign for value in series.values[longitudinal_axis]]

    figure, axis = plt.subplots(figsize=(9, 8), layout="constrained")
    plot_title = "G-g diagram" if confirmed_mapping else "Provisional g-g projection"
    axis.set_title(f"{plot_title}: {title}\n{len(horizontal):,} raw samples over {series.time_seconds[-1]:.1f} s")
    points = axis.scatter(horizontal, vertical, c=series.time_seconds, cmap="viridis",
                          s=10, alpha=0.65, linewidths=0, zorder=3)
    figure.colorbar(points, ax=axis, label="Elapsed time (s)", shrink=0.82)
    limit = max(0.5, math.ceil(max(map(abs, horizontal + vertical)) * 1.05 * 2) / 2)
    for index in range(1, int(limit / 0.5) + 1):
        radius = index * 0.5
        axis.add_patch(plt.Circle((0, 0), radius, fill=False, color="#9CA3AF",
                                  linewidth=0.7, linestyle="--", zorder=1))
    axis.axhline(0, color="#6B7280", linewidth=0.8)
    axis.axvline(0, color="#6B7280", linewidth=0.8)
    horizontal_label = "Lateral" if confirmed_mapping else "Sensor"
    vertical_label = "Longitudinal" if confirmed_mapping else "Sensor"
    axis.set_xlabel(f"{horizontal_label} {args.lateral_sign:+d} × {lateral_axis.upper()} acceleration (g)")
    axis.set_ylabel(f"{vertical_label} {args.longitudinal_sign:+d} × {longitudinal_axis.upper()} acceleration (g)")
    axis.set(xlim=(-limit, limit), ylim=(-limit, limit), aspect="equal")
    axis.grid(alpha=0.15)
    mapping_note = "" if confirmed_mapping else "Vehicle-axis mapping unconfirmed. "
    figure.supxlabel(
        f"{mapping_note}Input units: {args.acceleration_unit}. Reference circles: 0.5 g intervals.\n"
        "Raw acceleration; no bias, tilt, or gravity correction.", fontsize=9,
    )
    output_path.parent.mkdir(parents=True, exist_ok=True)
    figure.savefig(output_path, dpi=180, bbox_inches="tight")
    plt.close(figure)
    print(f"G-g horizontal {lateral_axis.upper()}: {min(horizontal):.3f} to {max(horizontal):.3f} g; "
          f"vertical {longitudinal_axis.upper()}: {min(vertical):.3f} to {max(vertical):.3f} g")


def plot_axis_comparison(series: ImuSeries, output_path: Path, title: str, unit: str) -> None:
    """Compare every sensor-axis pair without assuming vehicle directions."""

    scale = {"mg": 0.001, "g": 1.0, "m/s2": 1 / 9.80665}[unit]
    values = {axis: [value * scale for value in series.values[axis]] for axis in AXES}
    figure, plots = plt.subplots(1, 3, figsize=(15, 5.8), layout="constrained")
    limit = max(0.5, math.ceil(max(abs(v) for data in values.values() for v in data) * 1.05 * 2) / 2)
    for plot, (horizontal, vertical) in zip(plots, (("x", "y"), ("x", "z"), ("z", "y"))):
        points = plot.scatter(values[horizontal], values[vertical], c=series.time_seconds,
                              cmap="viridis", s=7, alpha=0.65, linewidths=0)
        plot.axhline(0, color="#6B7280", linewidth=0.8)
        plot.axvline(0, color="#6B7280", linewidth=0.8)
        plot.set(xlim=(-limit, limit), ylim=(-limit, limit), aspect="equal",
                 xlabel=f"Sensor {horizontal.upper()} acceleration (g)",
                 ylabel=f"Sensor {vertical.upper()} acceleration (g)",
                 title=f"{horizontal.upper()} / {vertical.upper()}")
        plot.grid(alpha=0.2)
    figure.colorbar(points, ax=plots, label="Elapsed time (s)", shrink=0.75)
    figure.suptitle(f"Sensor-axis comparison: {title}\n{len(series.timestamps):,} aligned samples; input units: {unit}")
    figure.supxlabel("Raw acceleration, including gravity. Vehicle directions are not assigned.", fontsize=10)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    figure.savefig(output_path, dpi=180, bbox_inches="tight")
    plt.close(figure)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Plot three-axis IMU acceleration CSV exports.")
    parser.add_argument("input_directory", type=Path, help="Folder containing one x, y, and z CSV export")
    parser.add_argument(
        "--output",
        type=Path,
        help="PNG to create (default: imu-acceleration-overview.png in the input folder)",
    )
    parser.add_argument(
        "--gg-output", type=Path,
        help="G-g PNG to create (default: imu-gg-diagram.png beside the overview PNG)",
    )
    parser.add_argument("--comparison-output", type=Path,
                        help="Axis-pair PNG (default: imu-axis-comparison.png beside the overview PNG)")
    parser.add_argument("--acceleration-unit", choices=("mg", "g", "m/s2"), default="mg",
                        help="Units of source values (default: mg)")
    parser.add_argument("--lateral-axis", choices=AXES,
                        help="Confirmed lateral axis; supply with --longitudinal-axis")
    parser.add_argument("--longitudinal-axis", choices=AXES,
                        help="Confirmed longitudinal axis; otherwise plot provisional Z/Y projection")
    parser.add_argument("--lateral-sign", type=int, choices=(-1, 1), default=1)
    parser.add_argument("--longitudinal-sign", type=int, choices=(-1, 1), default=1)
    parser.add_argument(
        "--time-unit",
        choices=("auto", "seconds", "milliseconds", "microseconds"),
        default="auto",
        help="Units of the timestamp column; auto treats intervals over 10 as milliseconds (default: auto)",
    )
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    if (args.lateral_axis is None) != (args.longitudinal_axis is None):
        parser.error("supply both --lateral-axis and --longitudinal-axis")
    if args.lateral_axis is not None and args.lateral_axis == args.longitudinal_axis:
        parser.error("lateral and longitudinal axes must differ")
    if not args.input_directory.is_dir():
        print(f"Error: input directory does not exist: {args.input_directory}", file=sys.stderr)
        return 2

    output_path = args.output or args.input_directory / "imu-acceleration-overview.png"
    gg_output_path = args.gg_output or output_path.parent / "imu-gg-diagram.png"
    comparison_path = args.comparison_output or output_path.parent / "imu-axis-comparison.png"
    output_paths = (output_path, gg_output_path, comparison_path)
    source_paths = {path.resolve() for path in args.input_directory.glob("*.csv")}
    if len({path.resolve() for path in output_paths}) != len(output_paths):
        parser.error("overview, g-g, and comparison output paths must differ")
    if any(path.resolve() in source_paths for path in output_paths):
        parser.error("output paths must not overwrite source CSVs")
    try:
        series = parse_imu(args.input_directory, args.time_unit)
        plot_imu(series, output_path, f"IMU acceleration: {args.input_directory.name}", args.acceleration_unit)
        plot_gg(series, gg_output_path, args.input_directory.name, args)
        plot_axis_comparison(series, comparison_path, args.input_directory.name, args.acceleration_unit)
    except (OSError, ValueError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 2

    print(f"Saved {output_path} ({len(series.timestamps):,} aligned samples at {series.sample_rate_hz:.2f} Hz)")
    print(f"Saved {gg_output_path}")
    print(f"Saved {comparison_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
