#include <cuda_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <iostream>
#include <cstdint>

#define CUDA_CHECK(call)                                                         \
    do {                                                                         \
        cudaError_t err__ = (call);                                              \
        if (err__ != cudaSuccess) {                                              \
            std::fprintf(stderr, "CUDA error at %s:%d: %s\n",                    \
                         __FILE__, __LINE__, cudaGetErrorString(err__));         \
            std::exit(1);                                                        \
        }                                                                        \
    } while (0)

// Fixed-work version:
// - total number of accesses is fixed across strides
// - launch geometry is fixed across strides
// - only address pattern changes with stride
//
// idx = (base + i * stride) % total_elems
// to ensure we stay inside bounds while preserving stride pattern.
//
// We keep one load + one store per access.

__global__ void global_stride_sweep_fixed_work_kernel(float* data,
                                                      int stride,
                                                      int total_accesses,
                                                      int total_elems,
                                                      int base_offset) {
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    int num_threads = gridDim.x * blockDim.x;

    long long total_elems64 = static_cast<long long>(total_elems);
    long long base64 = static_cast<long long>(base_offset);
    long long stride64 = static_cast<long long>(stride);

    for (int i = tid; i < total_accesses; i += num_threads) {
        long long idx64 = base64 + static_cast<long long>(i) * stride64;
        idx64 %= total_elems64;

        int idx = static_cast<int>(idx64);

        float v = data[idx];
        data[idx] = v + 1.0f;
    }
}

static float run_once(float* d_data,
                      int stride,
                      int total_accesses,
                      int total_elems,
                      int base_offset,
                      int block_size,
                      int grid_size,
                      int iters) {
    cudaEvent_t start, stop;
    CUDA_CHECK(cudaEventCreate(&start));
    CUDA_CHECK(cudaEventCreate(&stop));

    CUDA_CHECK(cudaEventRecord(start));
    for (int i = 0; i < iters; ++i) {
        global_stride_sweep_fixed_work_kernel<<<grid_size, block_size>>>(
            d_data, stride, total_accesses, total_elems, base_offset);
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
    // Defaults
    int max_stride     = 256;
    int block_size     = 256;
    int grid_size      = 256;
    int warmup         = 10;
    int repeat         = 50;
    int total_accesses = 1 << 24;   // 16,777,216 accesses
    int total_elems    = 1 << 26;   // 67,108,864 floats ~= 256 MB
    int stride_mode    = 0;         // 0 => powers of two, 1 => linear [1..max_stride]
    int base_offset    = 0;

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
        } else if (arg == "--total-accesses") {
            need_value("--total-accesses");
            total_accesses = std::atoi(argv[++i]);
        } else if (arg == "--total-elems") {
            need_value("--total-elems");
            total_elems = std::atoi(argv[++i]);
        } else if (arg == "--base-offset") {
            need_value("--base-offset");
            base_offset = std::atoi(argv[++i]);
        } else if (arg == "--linear") {
            stride_mode = 1;
        } else {
            std::cerr << "Unknown arg: " << arg << "\n";
            return 1;
        }
    }

    if (max_stride < 1 || block_size < 1 || grid_size < 1 ||
        total_accesses < 1 || total_elems < 1) {
        std::cerr << "Invalid configuration.\n";
        return 1;
    }

    // Need enough backing memory for modulo-indexed accesses.
    size_t total_bytes = static_cast<size_t>(total_elems) * sizeof(float);

    float* d_data = nullptr;
    CUDA_CHECK(cudaMalloc(&d_data, total_bytes));
    CUDA_CHECK(cudaMemset(d_data, 0, total_bytes));

    int device = 0;
    cudaDeviceProp prop{};
    CUDA_CHECK(cudaGetDevice(&device));
    CUDA_CHECK(cudaGetDeviceProperties(&prop, device));

    const int launched_threads = block_size * grid_size;
    const double bytes_per_access = 2.0 * sizeof(float); // 1 load + 1 store
    const double total_bytes_requested = static_cast<double>(total_accesses) * bytes_per_access;

    std::printf("{\n");
    std::printf("  \"probe\": \"global_stride_sweep_fixed_work\",\n");
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
    std::printf("    \"launched_threads\": %d,\n", launched_threads);
    std::printf("    \"warmup\": %d,\n", warmup);
    std::printf("    \"repeat\": %d,\n", repeat);
    std::printf("    \"total_accesses\": %d,\n", total_accesses);
    std::printf("    \"total_elems\": %d,\n", total_elems);
    std::printf("    \"base_offset\": %d,\n", base_offset);
    std::printf("    \"bytes_per_access\": %.0f,\n", bytes_per_access);
    std::printf("    \"total_bytes_requested\": %.0f,\n", total_bytes_requested);
    std::printf("    \"stride_mode\": \"%s\"\n", stride_mode == 0 ? "powers_of_two" : "linear");
    std::printf("  },\n");
    std::printf("  \"results\": [\n");

    bool first = true;

    auto emit_result = [&](int stride, float avg_ms) {
        double avg_s = static_cast<double>(avg_ms) / 1000.0;
        double requested_bw_gbps = (avg_s > 0.0)
            ? (total_bytes_requested / avg_s) / 1.0e9
            : 0.0;

        if (!first) std::printf(",\n");
        first = false;

        std::printf(
            "    {\"stride\": %d, \"avg_ms\": %.6f, \"requested_bw_gbps\": %.3f}",
            stride, avg_ms, requested_bw_gbps);
    };

    if (stride_mode == 0) {
        for (int stride = 1; stride <= max_stride; stride *= 2) {
            for (int i = 0; i < warmup; ++i) {
                global_stride_sweep_fixed_work_kernel<<<grid_size, block_size>>>(
                    d_data, stride, total_accesses, total_elems, base_offset);
                CUDA_CHECK(cudaGetLastError());
            }
            CUDA_CHECK(cudaDeviceSynchronize());

            float avg_ms = run_once(d_data,
                                    stride,
                                    total_accesses,
                                    total_elems,
                                    base_offset,
                                    block_size,
                                    grid_size,
                                    repeat);

            emit_result(stride, avg_ms);
        }
    } else {
        for (int stride = 1; stride <= max_stride; ++stride) {
            for (int i = 0; i < warmup; ++i) {
                global_stride_sweep_fixed_work_kernel<<<grid_size, block_size>>>(
                    d_data, stride, total_accesses, total_elems, base_offset);
                CUDA_CHECK(cudaGetLastError());
            }
            CUDA_CHECK(cudaDeviceSynchronize());

            float avg_ms = run_once(d_data,
                                    stride,
                                    total_accesses,
                                    total_elems,
                                    base_offset,
                                    block_size,
                                    grid_size,
                                    repeat);

            emit_result(stride, avg_ms);
        }
    }

    std::printf("\n  ]\n");
    std::printf("}\n");

    CUDA_CHECK(cudaFree(d_data));
    return 0;
}