# P2 — Shared Memory Bank Stride Sweep
GPU Probing Lab Experiment

---

# 1. Goal

Shared memory 접근 패턴을 변화시키면서 실행 시간을 측정하여 다음 하드웨어 특성을 추정한다.

- shared memory bank count
- bank mapping rule
- bank conflict penalty

이 실험은 shared memory의 **bank 구조와 conflict 패턴**을 관측하는 기본 실험이다.

---

# 2. Hypothesis

Shared memory는 여러 개의 memory bank로 구성되어 있으며  
동일한 bank에 여러 thread가 동시에 접근하면 **bank conflict**가 발생한다.

특정 stride에서 다음 현상이 나타난다.

1. shared memory access latency 증가
2. warp execution time 증가
3. bank conflict metric 증가

특히 **stride 값이 bank 수와 정렬될 때 latency spike**가 발생한다.

---

# 3. Controlled Variable

이 실험에서 변화시키는 변수는 다음 하나이다.

stride

stride sweep 값

1  
2  
4  
8  
16  
32  
64  

접근 패턴


thread i → smem[i * stride]


---

# 4. Fixed Conditions

| Parameter | Value |
|---|---|
Block Size | 256 |
Grid Size | 256 |
Shared Memory Size | ≥ 8KB |
Repeat Count | 100 |
Warmup Runs | 10 |

추가 조건

- 동일 warp 내 thread가 동시에 접근
- bank conflict만 관찰하기 위해 연산 최소화
- global memory 접근 제거

---

# 5. Kernel Pattern

각 thread는 shared memory 배열을 stride 간격으로 접근한다.

CUDA pseudo kernel

```cpp
__global__ void shared_stride_test(int stride)
{
    __shared__ float smem[4096];

    int tid = threadIdx.x;

    float v = smem[tid * stride];

    smem[tid] = v + 1.0f;
}

각 thread는

address = smem_base + (thread_id * stride)

위 주소를 접근한다.

6. Measurement

각 stride에 대해 다음 값을 측정한다.

Runtime Metrics

kernel execution time

Hardware Metrics (optional)

Nsight Compute metrics

shared_load_transactions
shared_store_transactions
smsp__shared_conflict

Derived Metrics

latency_per_access
conflict_ratio
7. Expected Pattern

stride sweep 결과는 다음과 같은 그래프 패턴을 보일 것으로 예상된다.

latency
│
│       ▲
│       │
│  ─────┘
│
└────────────────
       stride

특징

작은 stride → latency 낮음

특정 stride → latency spike

이후 다시 안정

특히 다음 stride에서 spike가 예상된다.

stride ≈ bank_count
stride ≈ bank_count × k
8. Inference Rule

실험 결과에서 다음 규칙으로 hardware property를 추정한다.

Rule 1 — Bank Count

latency spike가 발생하는 stride를 찾는다.

bank_count ≈ spike_stride

예

stride = 32
→ bank_count ≈ 32

Rule 2 — Bank Mapping

shared memory 주소는 일반적으로 다음과 같이 mapping 된다.

bank_id = (address / bank_width) % bank_count

stride 변화에 따른 conflict 패턴을 통해 bank_width 추정 가능

Rule 3 — Conflict Penalty

latency 증가 비율을 측정한다.

conflict_penalty = latency_conflict / latency_no_conflict
9. Output Format

실험 결과는 다음 JSON 형태로 저장한다.

{
  "probe": "shared_bank_stride_sweep",
  "device": "sm86",
  "stride_values": [1,2,4,8,16,32,64],
  "runtime_ms": [0.11,0.12,0.12,0.13,0.15,0.35,0.14],
  "metrics": {
    "shared_conflict": [],
    "shared_transactions": []
  }
}
10. Derived Property Output

analysis 단계에서 다음 property 후보를 생성한다.

{
  "device": "sm86",
  "properties": {
    "shared_memory_bank_count": 32,
    "shared_bank_conflict_penalty": 2.7
  },
  "confidence": {
    "shared_memory_bank_count": 0.82
  }
}
11. Notes

주의 사항

bank conflict는 warp 단위로 발생한다.

block size가 warp multiple이 아닌 경우 결과가 왜곡될 수 있다.

shared memory padding 실험과 함께 수행하면 더 정확하다.

12. Next Experiments

이 실험 이후 다음 실험을 진행한다.

P3_register_pressure_sweep

이 실험은 GPU compute resource 구조를 분석한다.

P2_shared_bank_stride_sweep
      │
      ▼
shared memory structure