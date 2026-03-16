# harness/run_probe.py
import json
import os
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
BUILD_DIR = ROOT / "build"

PROBES = {
    "global_stride_sweep": {
        "src": ROOT / "probes" / "memory" / "global_stride_sweep.cu",
        "exe": BUILD_DIR / ("global_stride_sweep.exe" if os.name == "nt" else "global_stride_sweep"),
        "args": [
            "--max-stride", "256",
            "--block", "256",
            "--grid", "256",
            "--warmup", "10",
            "--repeat", "50",
            "--logical-n", str(1 << 20),
        ],
    },
    "global_stride_sweep_fixed_work": {
        "src": ROOT / "probes" / "memory" / "global_stride_sweep_fixed_work.cu",
        "exe": BUILD_DIR / ("global_stride_sweep_fixed_work.exe" if os.name == "nt" else "global_stride_sweep_fixed_work"),
        "args": [
            "--max-stride", "256",
            "--block", "256",
            "--grid", "256",
            "--warmup", "10",
            "--repeat", "30",
            "--total-accesses", str(1 << 24),
            "--total-elems", str(1 << 26),
        ],
    },
}


def detect_cuda_arch():
    # RTX 3060 / RTX 3080 Ti Laptop both SM 86
    return "sm_86"


def build_probe(src_path: pathlib.Path, exe_path: pathlib.Path):
    BUILD_DIR.mkdir(parents=True, exist_ok=True)

    arch = detect_cuda_arch()

    cmd = [
        "nvcc",
        str(src_path),
        "-O3",
        "-std=c++17",
        f"-arch={arch}",
        "-o",
        str(exe_path),
    ]

    print("[build]", " ".join(cmd))
    subprocess.run(cmd, check=True)



def run_probe(exe_path: pathlib.Path, args):
    cmd = [str(exe_path)] + args
    print("[run]", " ".join(cmd))

    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.stdout.strip():
        print(result.stdout)

    if result.stderr.strip():
        print("[stderr]")
        print(result.stderr)

    if result.returncode != 0:
        raise RuntimeError(f"Probe failed with exit code {result.returncode}")

    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError:
        print("[warn] output is not valid JSON")
        return None


def main():
    probe_name = "global_stride_sweep_fixed_work"
    if len(sys.argv) >= 2:
        probe_name = sys.argv[1]

    if probe_name not in PROBES:
        print(f"Unknown probe: {probe_name}")
        print("Available probes:")
        for name in PROBES:
            print("  -", name)
        sys.exit(1)

    probe = PROBES[probe_name]

    build_probe(probe["src"], probe["exe"])
    run_probe(probe["exe"], probe["args"])


if __name__ == "__main__":
    main()