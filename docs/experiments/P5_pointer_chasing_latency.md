# P5 — Pointer Chasing Latency
GPU Probing Lab Experiment

---

# 1. Goal

Pointer chasing access pattern을 사용하여 GPU memory hierarchy의 실제 latency 구조를 추정한다.

이 실험을 통해 다음 특성을 관측한다.

- L1 cache latency
- L2 cache latency
- DRAM latency
- cache hierarchy transition

이 실험은 GPU memory subsystem의 **실제 지연 구조(latency structure)**를 드러내는 핵심 실험이다.

---

# 2. Hypothesis

일반적인 memory access benchmark는 여러 요청이 동시에 실행되기 때문에 실제 latency가 숨겨진다.

하지만 pointer chasing 패턴에서는


next = data[next]


형태로 memory access가 **strict dependency chain**을 가지게 된다.

따라서

- memory-level parallelism 제거
- true latency 측정 가능

working set 크기를 증가시키면 다음 현상이 나타난다.

1. L1 cache 영역 → 낮은 latency
2. L2 cache 영역 → latency 증가
3. DRAM 영역 → latency 급증

---

# 3. Controlled Variable

이 실험에서 변화시키는 변수


working_set_size


working set sweep


1 KB
2 KB
4 KB
8 KB
16 KB
32 KB
64 KB
128 KB
256 KB
512 KB
1 MB
2 MB
4 MB
8 MB
16 MB


---

# 4. Fixed Conditions

| Parameter | Value |
|---|---|
Block Size | 1 |
Grid Size | 1 |
Iterations | 1M |
Repeat Count | 30 |
Warmup Runs | 10 |

주의

pointer chasing latency를 정확히 측정하기 위해


single thread execution


을 사용한다.

---

# 5. Kernel Pattern

pointer chasing kernel

```cpp
__global__ void pointer_chase(int* next, int iterations)
{
    int idx = 0;

    #pragma unroll 1
    for(int i = 0; i < iterations; i++)
    {
        idx = next[idx];
    }

    next[0] = idx;
}

access pattern

next = data[next]

각 memory access는 이전 결과에 의존한다.

6. Measurement

각 working set size에 대해 다음 값을 측정한다.

Runtime Metrics

kernel execution time

Derived Metrics

latency_per_access

계산

latency = total_time / iterations
7. Expected Pattern

working set size에 따른 latency 그래프

latency
│
│   ──────
│         │
│         └──────
│                │
│                └────────
└────────────────────────
     working set size

이 그래프는 memory hierarchy 단계를 보여준다.

예

L1 cache
L2 cache
DRAM
8. Inference Rule

Rule 1 — L1 Cache Size

첫 번째 latency jump 지점

L1_size ≈ working_set_at_first_jump

Rule 2 — L2 Cache Size

두 번째 latency jump 지점

L2_size ≈ working_set_at_second_jump

Rule 3 — DRAM Latency

최대 plateau 영역

dram_latency ≈ plateau_latency
9. Output Format

실험 결과 JSON

{
  "probe": "pointer_chasing_latency",
  "device": "sm86",
  "working_set_bytes": [
    1024,
    2048,
    4096,
    8192,
    16384,
    32768,
    65536,
    131072,
    262144
  ],
  "latency_cycles": [
    30,
    31,
    32,
    45,
    48,
    90,
    95,
    220,
    230
  ]
}
10. Derived Property Output

analysis 결과

{
  "device": "sm86",
  "properties": {
    "l1_cache_size": 128000,
    "l2_cache_size": 4194304,
    "dram_latency_cycles": 230
  },
  "confidence": {
    "l1_cache_size": 0.64,
    "l2_cache_size": 0.72
  }
}
11. Notes

주의 사항

pointer chasing 구조를 반드시 랜덤 permutation으로 구성해야 한다.

sequential pattern은 prefetch 영향을 받을 수 있다.

GPU clock scaling이 latency 측정에 영향을 줄 수 있다.

추가 개선

randomized pointer chain
12. Next Experiments

다음 실험

P6_global_vector_load_compare

이 실험은 GPU global memory transaction 구조를 분석한다.

P5_pointer_chasing_latency
        │
        ▼
memory latency model

---

# 지금까지 구축된 GPU probing 실험

현재 GPU Probing Lab의 핵심 실험


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


이 5개만 있어도 GPU 구조를 다음 다섯 축으로 관측합니다.


memory bandwidth behavior
shared memory structure
compute resource limits
SIMT execution behavior
memory latency hierarchy