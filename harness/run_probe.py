import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path
from datetime import datetime


def run(cmd, cwd=None):
    result = subprocess.run(
        cmd,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )
    return result


def ensure_nvcc():
    if shutil.which("nvcc") is None:
        print("Error: nvcc not found in PATH.", file=sys.stderr)
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="Build and run a GPU probing kernel.")
    parser.add_argument(
        "--source",
        default="probes/memory/global_stride_sweep.cu",
        help="Path to CUDA probe source",
    )
    parser.add_argument(
        "--output-dir",
        default="results/raw",
        help="Directory for raw JSON outputs",
    )
    parser.add_argument("--max-stride", type=int, default=256)
    parser.add_argument("--block", type=int, default=256)
    parser.add_argument("--grid", type=int, default=256)
    parser.add_argument("--warmup", type=int, default=10)
    parser.add_argument("--repeat", type=int, default=50)
    parser.add_argument("--logical-n", type=int, default=1 << 20)
    parser.add_argument(
        "--linear",
        action="store_true",
        help="Use linear stride sweep [1..max_stride] instead of powers-of-two",
    )
    args = parser.parse_args()

    ensure_nvcc()

    source = Path(args.source)
    if not source.exists():
        print(f"Error: source file not found: {source}", file=sys.stderr)
        sys.exit(1)

    build_dir = Path("build")
    build_dir.mkdir(parents=True, exist_ok=True)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    exe_name = source.stem
    exe_path = build_dir / exe_name

    compile_cmd = [
        "nvcc",
        str(source),
        "-O3",
        "-std=c++17",
        "-o",
        str(exe_path),
    ]

    print(f"[build] {' '.join(compile_cmd)}")
    compile_res = run(compile_cmd)
    if compile_res.returncode != 0:
        print(compile_res.stdout)
        print(compile_res.stderr, file=sys.stderr)
        sys.exit(compile_res.returncode)

    probe_cmd = [
        str(exe_path),
        "--max-stride", str(args.max_stride),
        "--block", str(args.block),
        "--grid", str(args.grid),
        "--warmup", str(args.warmup),
        "--repeat", str(args.repeat),
        "--logical-n", str(args.logical_n),
    ]
    if args.linear:
        probe_cmd.append("--linear")

    print(f"[run] {' '.join(probe_cmd)}")
    run_res = run(probe_cmd)
    if run_res.returncode != 0:
        print(run_res.stdout)
        print(run_res.stderr, file=sys.stderr)
        sys.exit(run_res.returncode)

    try:
        data = json.loads(run_res.stdout)
    except json.JSONDecodeError as e:
        print("Failed to parse probe output as JSON.", file=sys.stderr)
        print(run_res.stdout)
        print(run_res.stderr, file=sys.stderr)
        raise e

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    device_name = data.get("device", {}).get("name", "unknown").replace(" ", "_")
    out_file = output_dir / f"{source.stem}_{device_name}_{timestamp}.json"

    with out_file.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)

    print(f"[saved] {out_file}")


if __name__ == "__main__":
    main()