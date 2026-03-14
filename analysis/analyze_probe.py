import argparse
import json
from pathlib import Path

import matplotlib.pyplot as plt


def load_result(path: Path):
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def infer_stride_boundary(strides, avg_ms):
    if len(strides) < 2:
        return None, None

    diffs = [avg_ms[i + 1] - avg_ms[i] for i in range(len(avg_ms) - 1)]
    max_idx = max(range(len(diffs)), key=lambda i: diffs[i])

    boundary_stride = strides[max_idx + 1]
    confidence = None

    baseline = max(avg_ms[max_idx], 1e-12)
    jump_ratio = avg_ms[max_idx + 1] / baseline if max_idx + 1 < len(avg_ms) else 1.0
    confidence = min(max((jump_ratio - 1.0) / 1.0, 0.0), 1.0)

    return boundary_stride, confidence


def main():
    parser = argparse.ArgumentParser(description="Analyze GPU probe JSON result.")
    parser.add_argument("result_json", help="Path to raw JSON result")
    parser.add_argument(
        "--plot-out",
        default=None,
        help="Optional output PNG path. Default: alongside JSON with .png suffix",
    )
    args = parser.parse_args()

    result_path = Path(args.result_json)
    data = load_result(result_path)

    results = data["results"]
    strides = [r["stride"] for r in results]
    avg_ms = [r["avg_ms"] for r in results]

    boundary_stride, confidence = infer_stride_boundary(strides, avg_ms)

    element_size = 4  # float
    inferred_boundary_bytes = boundary_stride * element_size if boundary_stride else None

    print("=== GPU Probing Analysis ===")
    print(f"Probe: {data.get('probe')}")
    print(f"Device: {data.get('device', {}).get('name', 'unknown')}")
    print(f"Inferred first major boundary stride: {boundary_stride}")
    print(f"Inferred boundary bytes (float stride * 4B): {inferred_boundary_bytes}")
    print(f"Confidence: {confidence:.3f}" if confidence is not None else "Confidence: N/A")

    plt.figure(figsize=(8, 5))
    plt.plot(strides, avg_ms, marker="o")
    plt.xscale("log", base=2)
    plt.xlabel("Stride (elements)")
    plt.ylabel("Average kernel time (ms)")
    plt.title("Global Stride Sweep")

    if boundary_stride is not None:
        plt.axvline(boundary_stride, linestyle="--")
        plt.annotate(
            f"boundary ~ {boundary_stride} elems\n~ {inferred_boundary_bytes} bytes",
            xy=(boundary_stride, avg_ms[strides.index(boundary_stride)]),
            xytext=(10, 10),
            textcoords="offset points",
        )

    plt.tight_layout()

    plot_out = Path(args.plot_out) if args.plot_out else result_path.with_suffix(".png")
    plt.savefig(plot_out, dpi=150)
    print(f"Plot saved to: {plot_out}")


if __name__ == "__main__":
    main()