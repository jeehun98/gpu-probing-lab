# P6 — Global Vector Load Compare
GPU Probing Lab Experiment

---

# 1. Goal

Scalar load와 vectorized load를 비교하여 GPU global memory transaction 구조를 분석한다.

이 실험을 통해 다음 특성을 관측한다.

- memory transaction size
- vectorized load efficiency
- alignment sensitivity
- memory coalescing behavior

이 실험은 GPU global memory subsystem의 **transaction granularity**를 관측한다.

---

# 2. Hypothesis

GPU global memory는 warp 단위 memory transaction을 사용한다.

memory access 패턴에 따라 다음 현상이 발생한다.


scalar load → 더 많은 transaction
vector load → transaction 감소


하지만 다음 조건이 만족되어야 한다.


alignment
coalescing
transaction boundary


alignment가 맞지 않으면 vector load는 오히려 성능이 나빠질 수 있다.

---

# 3. Controlled Variable

이 실험에서 변화시키는 변수


load_type


load type sweep


float
float2
float4


추가 실험


aligned load
misaligned load


---

# 4. Fixed Conditions

| Parameter | Value |
|---|---|
Block Size | 256 |
Grid Size | 256 |
Memory Size | ≥ 128MB |
Iterations | 100 |
Repeat Count | 50 |
Warmup Runs | 10 |

---

# 5. Kernel Pattern

Scalar load kernel

```cpp
__global__ void scalar_load(float* data)
{
    int idx = threadIdx.x + blockIdx.x * blockDim.x;

    float v = data[idx];

    data[idx] = v + 1.0f;
}

Vector load kernel

__global__ void vector_load(float4* data)
{
    int idx = threadIdx.x + blockIdx.x * blockDim.x;

    float4 v = data[idx];

    v.x += 1.0f;

    data[idx] = v;
}
6. Measurement

각 load type에 대해 다음 값을 측정한다.

Runtime Metrics

kernel execution time

Hardware Metrics (Nsight Compute)

dram__throughput
dram__transactions
l2_tex__hit_rate

Derived Metrics

memory_bandwidth
transaction_efficiency
7. Expected Pattern

vector width 증가에 따른 성능 변화

bandwidth
│
│      ┌──────
│     /
│    /
│   /
└────────────────
 float float2 float4

특징

scalar load → baseline

float2 → improvement

float4 → best performance (aligned case)

misaligned case에서는

bandwidth
│
│   ──────
│        │
│        └───
│            │
│            └──

vector load가 오히려 느려질 수 있다.

8. Inference Rule

Rule 1 — Memory Transaction Size

transaction count 비교

transaction_reduction =
scalar_transactions / vector_transactions

이를 통해

memory_transaction_bytes

추정 가능

Rule 2 — Vectorization Efficiency

efficiency =
bandwidth_vector / bandwidth_scalar

예

efficiency ≈ 1.7x

Rule 3 — Alignment Sensitivity

aligned vs misaligned 비교

alignment_penalty =
time_misaligned / time_aligned

alignment 조건이 vector load에 얼마나 중요한지 판단 가능

9. Output Format

실험 결과 JSON

{
  "probe": "global_vector_load_compare",
  "device": "sm86",
  "load_types": ["float","float2","float4"],
  "runtime_ms": [0.18,0.12,0.09],
  "metrics": {
    "dram_transactions": [],
    "bandwidth": []
  }
}
10. Derived Property Output

analysis 결과

{
  "device": "sm86",
  "properties": {
    "memory_transaction_bytes": 32,
    "optimal_vector_width": 4,
    "alignment_requirement": 16
  },
  "confidence": {
    "memory_transaction_bytes": 0.73
  }
}
11. Notes

주의 사항

vector load는 반드시 alignment를 맞춰야 한다.

warp coalescing 패턴에 따라 결과가 달라질 수 있다.

L2 cache hit rate가 결과에 영향을 줄 수 있다.

추가 실험

stride + vector load
12. Next Experiments

다음 실험

P7_l2_working_set_sweep

이 실험은 GPU L2 cache 구조를 분석한다.

P6_global_vector_load_compare
        │
        ▼
memory transaction model

---

# 지금까지 GPU probing 실험

현재 구축된 실험


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


이 6개는 GPU 구조를 이렇게 분해합니다.


memory access pattern
memory latency
memory transaction
shared memory
compute resources
execution policy