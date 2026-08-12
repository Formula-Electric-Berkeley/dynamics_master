#!/usr/bin/env python3
"""Parse three-axis IMU acceleration CSV exports and save an overview plot.

Each CSV is expected to contain ``timestamp,value`` rows, with an axis encoded
in its file name (for example ``...-acceleration_x.csv``).  The timestamp is
assumed to be milliseconds when the median sample interval is greater than 10;
otherwise it is treated as seconds.  The plot always uses elapsed time, so the
absolute start time in the export does not matter.

Examples
--------
    # Run from the repository root.  uv supplies matplotlib for this command.
    uv run --with matplotlib python IMU-data-processing/IMU-reader.py \
        IMU-data-processing/IMU-data-First-Motor-Spin

    # Choose where to write the PNG and override timestamp units if needed.
    uv run --with matplotlib python IMU-data-processing/IMU-reader.py \
        IMU-data-processing/IMU-data-First-Motor-Spin \
        --output artifacts/first-motor-spin-imu.png --time-unit milliseconds
"""

from __future__ import annotations

import argparse
import csv
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


def plot_imu(series: ImuSeries, output_path: Path, title: str) -> None:
    """Create a four-panel acceleration plot, one panel per component plus norm."""

    figure, axes = plt.subplots(4, 1, figsize=(12, 10), sharex=True, layout="constrained")
    figure.suptitle(
        f"{title}\n{len(series.timestamps):,} aligned samples  •  estimated sampling rate: {series.sample_rate_hz:.2f} Hz"
    )

    for axis_name, axis_plot in zip(AXES, axes[:3]):
        axis_plot.plot(series.time_seconds, series.values[axis_name], color=AXIS_COLORS[axis_name], linewidth=1)
        axis_plot.set_ylabel(f"{axis_name.upper()} acceleration\n(mg)")
        axis_plot.grid(alpha=0.3)

    magnitude = [
        (x_value**2 + y_value**2 + z_value**2) ** 0.5
        for x_value, y_value, z_value in zip(series.values["x"], series.values["y"], series.values["z"])
    ]
    axes[3].plot(series.time_seconds, magnitude, color="#4D4D4D", linewidth=1, label="√(x² + y² + z²)")
    axes[3].set_ylabel("Magnitude\n(mg)")
    axes[3].set_xlabel("Elapsed time (s)")
    axes[3].grid(alpha=0.3)
    axes[3].legend(loc="upper right")

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
        "--time-unit",
        choices=("auto", "seconds", "milliseconds", "microseconds"),
        default="auto",
        help="Units of the timestamp column; auto treats intervals over 10 as milliseconds (default: auto)",
    )
    return parser


def main() -> int:
    args = build_parser().parse_args()
    if not args.input_directory.is_dir():
        print(f"Error: input directory does not exist: {args.input_directory}", file=sys.stderr)
        return 2

    output_path = args.output or args.input_directory / "imu-acceleration-overview.png"
    try:
        series = parse_imu(args.input_directory, args.time_unit)
        plot_imu(series, output_path, f"IMU acceleration: {args.input_directory.name}")
    except (OSError, ValueError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 2

    print(f"Saved {output_path} ({len(series.timestamps):,} aligned samples at {series.sample_rate_hz:.2f} Hz)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
