#include <cuda_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <vector>
#include <string>
#include <iostream>

#define CUDA_CHECK(call)                                                         \
    do {                                                                         \
        cudaError_t err__ = (call);                                              \
        if (err__ != cudaSuccess) {                                              \
            std::fprintf(stderr, "CUDA error at %s:%d: %s\n",                    \
                         __FILE__, __LINE__, cudaGetErrorString(err__));         \
            std::exit(1);                                                        \
        }                                                                        \
    } while (0)

__global__ void global_stride_sweep_kernel(float* data, int stride, int n) {
    int gid = blockIdx.x * blockDim.x + threadIdx.x;
    int idx = gid * stride;

    if (idx < n) {
        float v = data[idx];
        data[idx] = v + 1.0f;
    }
}

static float run_once(float* d_data,
                      int stride,
                      int logical_n,
                      int block_size,
                      int grid_size,
                      int iters) {
    cudaEvent_t start, stop;
    CUDA_CHECK(cudaEventCreate(&start));
    CUDA_CHECK(cudaEventCreate(&stop));

    CUDA_CHECK(cudaEventRecord(start));
    for (int i = 0; i < iters; ++i) {
        global_stride_sweep_kernel<<<grid_size, block_size>>>(d_data, stride, logical_n);
        CUDA_CHECK(cudaGetLastError());
    }
    CUDA_CHECK(cudaEventRecord(stop));
    CUDA_CHECK(cudaEventSynchronize(stop));

    float ms = 0.0f;
    CUDA_CHECK(cudaEventElapsedTime(&ms, start, stop));

    CUDA_CHECK(cudaEventDestroy(start));
    CUDA_CHECK(cudaEventDestroy(stop));
    return ms / static_cast<float>(iters);
}

int main(int argc, char** argv) {
    int max_stride  = 256;
    int block_size  = 256;
    int grid_size   = 256;
    int warmup      = 10;
    int repeat      = 50;
    int logical_n   = 1 << 20;
    int stride_mode = 0;

    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        auto need_value = [&](const char* name) {
            if (i + 1 >= argc) {
                std::cerr << "Missing value for " << name << "\n";
                std::exit(1);
            }
        };

        if (arg == "--max-stride") {
            need_value("--max-stride");
            max_stride = std::atoi(argv[++i]);
        } else if (arg == "--block") {
            need_value("--block");
            block_size = std::atoi(argv[++i]);
        } else if (arg == "--grid") {
            need_value("--grid");
            grid_size = std::atoi(argv[++i]);
        } else if (arg == "--warmup") {
            need_value("--warmup");
            warmup = std::atoi(argv[++i]);
        } else if (arg == "--repeat") {
            need_value("--repeat");
            repeat = std::atoi(argv[++i]);
        } else if (arg == "--logical-n") {
            need_value("--logical-n");
            logical_n = std::atoi(argv[++i]);
        } else if (arg == "--linear") {
            stride_mode = 1;
        } else {
            std::cerr << "Unknown arg: " << arg << "\n";
            return 1;
        }
    }

    if (max_stride < 1 || block_size < 1 || grid_size < 1 || logical_n < 1) {
        std::cerr << "Invalid configuration.\n";
        return 1;
    }

    size_t total_elems = static_cast<size_t>(logical_n) * static_cast<size_t>(max_stride);
    size_t total_bytes = total_elems * sizeof(float);

    float* d_data = nullptr;
    CUDA_CHECK(cudaMalloc(&d_data, total_bytes));
    CUDA_CHECK(cudaMemset(d_data, 0, total_bytes));

    int device = 0;
    cudaDeviceProp prop{};
    CUDA_CHECK(cudaGetDevice(&device));
    CUDA_CHECK(cudaGetDeviceProperties(&prop, device));

    std::printf("{\n");
    std::printf("  \"probe\": \"global_stride_sweep\",\n");
    std::printf("  \"device\": {\n");
    std::printf("    \"id\": %d,\n", device);
    std::printf("    \"name\": \"%s\",\n", prop.name);
    std::printf("    \"cc_major\": %d,\n", prop.major);
    std::printf("    \"cc_minor\": %d\n", prop.minor);
    std::printf("  },\n");
    std::printf("  \"config\": {\n");
    std::printf("    \"max_stride\": %d,\n", max_stride);
    std::printf("    \"block_size\": %d,\n", block_size);
    std::printf("    \"grid_size\": %d,\n", grid_size);
    std::printf("    \"warmup\": %d,\n", warmup);
    std::printf("    \"repeat\": %d,\n", repeat);
    std::printf("    \"logical_n\": %d,\n", logical_n);
    std::printf("    \"stride_mode\": \"%s\"\n", stride_mode == 0 ? "powers_of_two" : "linear");
    std::printf("  },\n");
    std::printf("  \"results\": [\n");

    bool first = true;

    if (stride_mode == 0) {
        for (int stride = 1; stride <= max_stride; stride *= 2) {
            for (int i = 0; i < warmup; ++i) {
                global_stride_sweep_kernel<<<grid_size, block_size>>>(d_data, stride, logical_n);
                CUDA_CHECK(cudaGetLastError());
            }
            CUDA_CHECK(cudaDeviceSynchronize());

            float avg_ms = run_once(d_data, stride, logical_n, block_size, grid_size, repeat);

            if (!first) std::printf(",\n");
            first = false;
            std::printf("    {\"stride\": %d, \"avg_ms\": %.6f}", stride, avg_ms);
        }
    } else {
        for (int stride = 1; stride <= max_stride; ++stride) {
            for (int i = 0; i < warmup; ++i) {
                global_stride_sweep_kernel<<<grid_size, block_size>>>(d_data, stride, logical_n);
                CUDA_CHECK(cudaGetLastError());
            }
            CUDA_CHECK(cudaDeviceSynchronize());

            float avg_ms = run_once(d_data, stride, logical_n, block_size, grid_size, repeat);

            if (!first) std::printf(",\n");
            first = false;
            std::printf("    {\"stride\": %d, \"avg_ms\": %.6f}", stride, avg_ms);
        }
    }

    std::printf("\n  ]\n");
    std::printf("}\n");

    CUDA_CHECK(cudaFree(d_data));
    return 0;
}