# P3 — Register Pressure Sweep
GPU Probing Lab Experiment

---

# 1. Goal

Register 사용량을 점진적으로 증가시키면서 실행 시간을 측정하여 다음 GPU 특성을 추정한다.

- register file size per SM
- register allocation behavior
- occupancy cliff 발생 지점
- register spilling onset

이 실험은 GPU compute resource 구조를 관측하는 핵심 실험이다.

---

# 2. Hypothesis

GPU는 SM당 제한된 register file을 가지고 있으며  
thread가 사용하는 register 수가 증가하면 다음 현상이 발생한다.

1. 동시에 실행 가능한 warp 수 감소
2. occupancy 감소
3. 특정 지점에서 성능 급락 (performance cliff)
4. register spilling 발생 시 latency 증가

특히 register 사용량이 특정 임계값을 넘으면 성능이 계단형(stepwise)으로 감소한다.

---

# 3. Controlled Variable

이 실험에서 변화시키는 변수는 다음이다.


register_count


register sweep 값


8
16
24
32
40
48
64
80
96
128


register 사용량은 커널 내부 변수 개수로 제어한다.

예


float r0, r1, r2, ..., rN


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

- compute workload 유지
- memory access 최소화
- instruction mix 일정 유지

---

# 5. Kernel Pattern

register 수를 증가시키기 위해 다음 패턴을 사용한다.

CUDA pseudo kernel

```cpp
__global__ void register_test()
{
    float r0=0, r1=1, r2=2, r3=3;
    float r4=4, r5=5, r6=6, r7=7;

    int tid = threadIdx.x;

    #pragma unroll
    for(int i=0;i<1000;i++)
    {
        r0 = r0 * 1.01f + r1;
        r2 = r2 * 1.02f + r3;
        r4 = r4 * 1.03f + r5;
        r6 = r6 * 1.04f + r7;
    }
}

register 수를 증가시키기 위해 변수 개수를 늘린다.

6. Measurement

각 register_count에 대해 다음 값을 측정한다.

Runtime Metrics

kernel execution time

Hardware Metrics (Nsight Compute)
achieved_occupancy
registers_per_thread
sm_efficiency
Derived Metrics
performance_drop_ratio
occupancy
7. Expected Pattern

register sweep 결과는 다음과 같은 그래프 패턴을 보일 것으로 예상된다.

performance
│
│ ──────────
│          │
│          └──────
│                 │
│                 └────
└────────────────────────
           registers

특징

낮은 register → 성능 안정

특정 지점 → occupancy 감소

이후 성능 계단형 하락

8. Inference Rule
Rule 1 — Register Cliff Detection

성능 급락 지점을 찾는다.

performance_drop > threshold

이 지점은 register pressure cliff를 나타낸다.

Rule 2 — SM Register Capacity Estimate

register cliff 위치를 통해 다음 값을 추정한다.

register_file_size ≈
(register_per_thread × threads_per_block × active_blocks)
Rule 3 — Register Allocation Granularity

occupancy 감소가 **계단형(stepwise)**이면 다음을 추정한다.

allocation_unit = step_size

예

register step = 8
9. Output Format

실험 결과는 다음 JSON 형태로 저장한다.

{
  "probe": "register_pressure_sweep",
  "device": "sm86",
  "register_values": [8,16,24,32,48,64,80,96,128],
  "runtime_ms": [0.11,0.11,0.11,0.12,0.18,0.22,0.30,0.35,0.41],
  "metrics": {
    "occupancy": [],
    "sm_efficiency": []
  }
}
10. Derived Property Output

analysis 단계에서 다음 property 후보를 생성한다.

{
  "device": "sm86",
  "properties": {
    "register_file_size_per_sm": 65536,
    "register_allocation_granularity": 8,
    "register_pressure_cliff": 64
  },
  "confidence": {
    "register_file_size_per_sm": 0.71
  }
}
11. Notes

주의 사항

register spilling 발생 시 local memory access가 증가한다.

nvcc optimization이 register allocation을 변경할 수 있다.

--maxrregcount 옵션을 사용하여 register usage를 제어할 수 있다.

12. Next Experiments

다음 실험

P4_branch_divergence_sweep

이 실험은 GPU execution policy를 관측한다.

P3_register_pressure_sweep
      │
      ▼
compute resource model

---

# 지금까지 구축된 실험

현재 GPU Probing Lab에서 정의된 실험


P1_global_stride_sweep
→ global memory hierarchy

P2_shared_bank_stride_sweep
→ shared memory bank structure

P3_register_pressure_sweep
→ register pressure / occupancy cliff


이 세 개는 GPU 구조를 이렇게 나눠서 관측합니다.


memory hierarchy
shared memory
compute resource
