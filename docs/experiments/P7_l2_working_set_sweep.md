# P7 — L2 Working Set Sweep
GPU Probing Lab Experiment

---

# 1. Goal

Working set 크기를 점진적으로 증가시키면서 memory throughput 변화를 측정하여 다음 GPU 특성을 추정한다.

- effective L2 cache capacity
- cache thrashing threshold
- memory reuse effectiveness
- cache residency behavior

이 실험은 GPU cache subsystem의 **working set tolerance**를 관측한다.

---

# 2. Hypothesis

GPU L2 cache는 일정 크기의 working set까지는 높은 hit rate를 유지한다.

하지만 working set이 cache capacity를 초과하면 다음 현상이 발생한다.

1. cache hit rate 감소
2. memory bandwidth 감소
3. DRAM access 증가

따라서 working set sweep을 수행하면 다음 패턴이 나타난다.


high bandwidth plateau
↓
throughput drop


---

# 3. Controlled Variable

이 실험에서 변화시키는 변수


working_set_size


working set sweep


64 KB
128 KB
256 KB
512 KB
1 MB
2 MB
4 MB
8 MB
16 MB
32 MB
64 MB


---

# 4. Fixed Conditions

| Parameter | Value |
|---|---|
Block Size | 256 |
Grid Size | 256 |
Iterations | 100 |
Repeat Count | 50 |
Warmup Runs | 10 |

추가 조건

- 동일 memory reuse pattern 유지
- coalesced memory access
- L1 cache 영향 최소화

---

# 5. Kernel Pattern

working set을 반복적으로 접근한다.

CUDA pseudo kernel

```cpp
__global__ void working_set_test(float* data, int size)
{
    int idx = threadIdx.x + blockIdx.x * blockDim.x;

    float sum = 0.0f;

    for(int i=0;i<100;i++)
    {
        sum += data[(idx + i) % size];
    }

    data[idx] = sum;
}

access pattern

repeated access within working set
``` id="0h5zt6"

---

# 6. Measurement

각 working_set_size에 대해 다음 값을 측정한다.

Runtime Metrics

- kernel execution time

Hardware Metrics (Nsight Compute)

``` id="scqgo6"
l2_tex__hit_rate
dram__throughput
dram__transactions

Derived Metrics

memory_bandwidth
cache_hit_ratio
7. Expected Pattern

working set vs bandwidth 그래프

bandwidth
│
│──────────────
│              │
│              └──────
│                     │
│                     └─────
└────────────────────────────
      working set size

특징

작은 working set → 높은 bandwidth

cache capacity 근처 → throughput 감소

large working set → DRAM bound

8. Inference Rule

Rule 1 — Effective L2 Cache Size

throughput drop 지점 탐지

L2_capacity ≈ working_set_at_drop

Rule 2 — Cache Thrashing Threshold

bandwidth 급락 지점

thrashing_point =
working_set_size > cache_capacity

Rule 3 — Memory Reuse Efficiency

cache hit rate 기반

reuse_efficiency =
L2_hit_rate
9. Output Format

실험 결과 JSON

{
  "probe": "l2_working_set_sweep",
  "device": "sm86",
  "working_set_bytes": [
    65536,
    131072,
    262144,
    524288,
    1048576,
    2097152,
    4194304
  ],
  "bandwidth_gbps": [
    850,
    840,
    830,
    810,
    760,
    520,
    310
  ]
}
10. Derived Property Output

analysis 결과

{
  "device": "sm86",
  "properties": {
    "l2_cache_effective_capacity": 3145728,
    "cache_thrashing_threshold": 4194304
  },
  "confidence": {
    "l2_cache_effective_capacity": 0.76
  }
}
11. Notes

주의 사항

L1 cache 영향 제거 필요

prefetch behavior 결과 왜곡 가능

access pattern이 sequential이면 결과가 달라질 수 있음

추가 실험

randomized working set
12. Next Experiments

다음 실험

P8_fp32_fma_throughput

이 실험은 GPU compute unit의 실제 처리량을 측정한다.

P7_l2_working_set_sweep
        │
        ▼
cache reuse model

---

# 현재 GPU probing 실험 (7개)


P1_global_stride_sweep
→ cache line / coalescing

P2_shared_bank_stride_sweep
→ shared memory bank mapping

P3_register_pressure_sweep
→ register pressure / occupancy

P4_branch_divergence_sweep
→ SIMT divergence behavior

P5_pointer_chasing_latency
→ memory latency hierarchy

P6_global_vector_load_compare
→ memory transaction structure

P7_l2_working_set_sweep
→ cache working set capacity


이 7개만 있어도 GPU를 다음 구조로 관측합니다.


memory hierarchy
memory latency
memory transaction
shared memory
compute resource
execution policy
cache reuse behavior


---

# 다음 단계

다음 실험


P8_fp32_fma_throughput


이 실험은 GPU의


FP32 compute peak
instruction throughput
pipeline saturation


을 측정합니다.

이 실험부터는 **memory → compute subsystem probing**으로 넘어갑니다.