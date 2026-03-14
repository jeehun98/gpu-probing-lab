import subprocess
import sys

def run_probe(kernel):

    exe = kernel.replace(".cu","")

    subprocess.run([
        "nvcc",
        kernel,
        "-O3",
        "-o",
        exe
    ])

    subprocess.run(["./"+exe])


if __name__ == "__main__":

    kernel = sys.argv[1]

    run_probe(kernel)