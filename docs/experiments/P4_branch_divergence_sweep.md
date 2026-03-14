# P4 — Branch Divergence Sweep
GPU Probing Lab Experiment

---

# 1. Goal

Warp 내부 thread들의 branch divergence 비율을 변화시키면서 실행 시간을 측정하여 다음 GPU 특성을 추정한다.

- warp divergence penalty
- SIMT execution efficiency
- branch execution policy
- warp serialization cost

이 실험은 GPU의 **SIMT execution model**을 관측하는 기본 실험이다.

---

# 2. Hypothesis

GPU warp는 일반적으로 32개의 thread로 구성되며  
warp 내부 thread가 서로 다른 branch path를 선택하면 다음 현상이 발생한다.

1. warp execution serialization
2. instruction replay 증가
3. execution latency 증가

특히 divergence ratio가 증가할수록 warp execution efficiency가 감소한다.

---

# 3. Controlled Variable

이 실험에서 변화시키는 변수


divergence_ratio


divergence ratio sweep


0% (uniform execution)
25%
50%
75%
100% (maximum divergence)


branch 패턴


if ((threadIdx.x % K) == 0)


K 값을 변화시키며 divergence ratio를 조절한다.

---

# 4. Fixed Conditions

| Parameter | Value |
|---|---|
Block Size | 256 |
Grid Size | 256 |
Loop Iterations | 1000 |
Repeat Count | 50 |
Warmup Runs | 10 |

추가 조건

- compute workload 일정 유지
- memory access 최소화
- instruction mix 동일

---

# 5. Kernel Pattern

CUDA pseudo kernel

```cpp
__global__ void divergence_test(int K)
{
    int tid = threadIdx.x;

    float x = 1.0f;

    #pragma unroll
    for(int i=0;i<1000;i++)
    {
        if((tid % K) == 0)
        {
            x = x * 1.01f + 1.0f;
        }
        else
        {
            x = x * 1.02f + 2.0f;
        }
    }
}

warp 내부 thread가 서로 다른 경로를 선택한다.

6. Measurement

각 divergence_ratio에 대해 다음 값을 측정한다.

Runtime Metrics

kernel execution time

Hardware Metrics (Nsight Compute)

warp_execution_efficiency
branch_efficiency
smsp__inst_executed

Derived Metrics

divergence_penalty
warp_efficiency
7. Expected Pattern

divergence ratio 증가에 따라 다음 그래프가 예상된다.

execution time
│
│      /
│     /
│    /
│   /
└────────────────
     divergence ratio

특징

uniform branch → fastest

divergence 증가 → execution time 증가

full divergence → worst performance

8. Inference Rule

Rule 1 — Divergence Penalty

divergence_penalty =
time_divergent / time_uniform

예

penalty ≈ 1.8x

Rule 2 — Warp Execution Efficiency

warp_efficiency =
active_threads / warp_size

이 값이 낮을수록 divergence 영향이 큼.

Rule 3 — Branch Serialization

execution time 증가 패턴이 선형인지 확인한다.

linear increase → serialized execution
nonlinear increase → scheduler optimization
9. Output Format

실험 결과 JSON

{
  "probe": "branch_divergence_sweep",
  "device": "sm86",
  "divergence_ratio": [0,25,50,75,100],
  "runtime_ms": [0.12,0.15,0.18,0.22,0.25],
  "metrics": {
    "warp_efficiency": [],
    "branch_efficiency": []
  }
}
10. Derived Property Output

analysis 단계에서 다음 property 후보 생성

{
  "device": "sm86",
  "properties": {
    "warp_size": 32,
    "divergence_penalty": 1.9,
    "warp_execution_efficiency": 0.78
  },
  "confidence": {
    "divergence_penalty": 0.68
  }
}
11. Notes

주의 사항

warp size는 GPU architecture마다 다를 수 있음

divergence pattern은 scheduler behavior에 영향을 받을 수 있음

memory access가 섞이면 결과가 왜곡될 수 있음

12. Next Experiments

다음 실험

P5_pointer_chasing_latency

이 실험은 GPU memory hierarchy의 실제 latency 구조를 분석한다.

P4_branch_divergence_sweep
        │
        ▼
SIMT execution model

---

# 현재 GPU Probing Lab의 핵심 실험 4개

지금까지 만든 실험들은 GPU 구조를 이렇게 분해합니다.


P1_global_stride_sweep
→ global memory hierarchy

P2_shared_bank_stride_sweep
→ shared memory bank structure

P3_register_pressure_sweep
→ register pressure / occupancy

P4_branch_divergence_sweep
→ SIMT execution behavior


이 네 개만 있어도 이미 GPU 구조를 다음 네 축으로 관측합니다.


memory hierarchy
shared memory
compute resources
execution policy