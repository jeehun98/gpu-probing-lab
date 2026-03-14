# P8 — FP32 FMA Throughput
GPU Probing Lab Experiment

---

# 1. Goal

FP32 fused multiply-add(FMA) 연산을 반복 수행하는 커널을 통해 GPU의 실제 FP32 compute throughput을 측정한다.

이 실험을 통해 다음 특성을 관측한다.

- peak FP32 throughput
- instruction pipeline saturation point
- unrolling sensitivity
- compute-bound kernel의 기준 성능

이 실험은 GPU compute subsystem의 **기본 처리량 ceiling**을 정의하는 실험이다.

---

# 2. Hypothesis

충분히 많은 FP32 FMA 연산을 메모리 접근 없이 반복하면 커널은 memory-bound가 아니라 compute-bound 상태에 들어간다.

이때 다음 현상이 나타난다.

1. unroll factor 증가에 따라 throughput 증가
2. 일정 지점 이후 throughput plateau 형성
3. plateau 값이 해당 GPU의 effective FP32 throughput에 근접

즉, 이 실험은 memory bottleneck을 제거한 상태에서 **연산 유닛의 실제 최대 처리량**을 관측한다.

---

# 3. Controlled Variable

이 실험에서 변화시키는 변수

```text
unroll_factor

unroll sweep 예시

1
2
4
8
16
32
64

추가로 선택적으로 변화시킬 수 있는 변수

register_count
instruction_chain_count

하지만 첫 버전에서는 unroll factor만 sweep한다.

4. Fixed Conditions
Parameter	Value
Block Size	256
Grid Size	GPU saturation 기준으로 충분히 크게 설정
Iterations	4096 이상
Repeat Count	30
Warmup Runs	10

추가 조건

global memory access 최소화

shared memory 사용 금지

dependency chain과 independent chain을 분리해 실험 가능

compiler dead-code elimination 방지

5. Kernel Pattern

핵심 아이디어는 register 안에서만 FP32 FMA를 반복하는 것이다.

CUDA pseudo kernel

__global__ void fp32_fma_test(float* out)
{
    int tid = threadIdx.x + blockIdx.x * blockDim.x;

    float a0 = 1.001f, b0 = 1.002f, x0 = (float)tid;
    float a1 = 1.003f, b1 = 1.004f, x1 = (float)tid + 1.0f;
    float a2 = 1.005f, b2 = 1.006f, x2 = (float)tid + 2.0f;
    float a3 = 1.007f, b3 = 1.008f, x3 = (float)tid + 3.0f;

    #pragma unroll
    for (int i = 0; i < 4096; i++)
    {
        x0 = a0 * x0 + b0;
        x1 = a1 * x1 + b1;
        x2 = a2 * x2 + b2;
        x3 = a3 * x3 + b3;
    }

    out[tid] = x0 + x1 + x2 + x3;
}

중요 포인트

FMA 연산 수가 명확해야 함

independent accumulation chain을 여러 개 두어 ILP를 확보

결과를 최종적으로 global memory에 한 번만 기록하여 DCE 방지

6. Measurement

각 unroll_factor에 대해 다음 값을 측정한다.

Runtime Metrics

kernel execution time

Hardware Metrics (Nsight Compute)

smsp__inst_executed_pipe_fma
sm__throughput
smsp__issue_active
smsp__cycles_elapsed
achieved_occupancy

Derived Metrics

GFLOPS
issue_efficiency
compute_utilization

GFLOPS 계산 예시

GFLOPS =
(total_FMA_count × 2) / execution_time

주의:
FMA 1개는 일반적으로 2 FLOPs로 계산한다.

7. Expected Pattern

unroll factor 증가에 따른 throughput 그래프

GFLOPS
│
│           ┌──────────
│         ┌─┘
│      ┌──┘
│   ┌──┘
│───┘
└──────────────────────
    1  2  4  8  16  32  64
         unroll factor

특징

낮은 unroll → pipeline 활용 부족

중간 구간 → throughput 빠르게 증가

높은 unroll → plateau

plateau 구간이 effective FP32 peak

8. Inference Rule

Rule 1 — Effective FP32 Peak

plateau 구간의 평균 GFLOPS를 계산한다.

effective_fp32_peak =
mean(GFLOPS in plateau region)

Rule 2 — Pipeline Saturation Point

GFLOPS 증가율이 작아지는 첫 지점을 찾는다.

saturation_point =
first unroll where delta_gflops < threshold

이 지점은 instruction pipeline이 충분히 포화된 지점이다.

Rule 3 — ILP Sensitivity

independent chain 수를 달리한 실험에서 throughput 차이를 비교한다.

high ILP gain
→ scheduler / pipeline이 independent issue를 잘 활용

low ILP gain
→ dependency 또는 issue bottleneck 존재
9. Output Format

실험 결과 JSON

{
  "probe": "fp32_fma_throughput",
  "device": "sm86",
  "unroll_factors": [1,2,4,8,16,32,64],
  "runtime_ms": [1.82,1.01,0.61,0.39,0.31,0.30,0.30],
  "gflops": [4200,7600,12600,18100,22300,22900,22850],
  "metrics": {
    "issue_active": [],
    "sm_throughput": []
  }
}
10. Derived Property Output

analysis 결과

{
  "device": "sm86",
  "properties": {
    "effective_fp32_peak_gflops": 22880,
    "fp32_pipeline_saturation_unroll": 16,
    "fp32_issue_efficiency": 0.83
  },
  "confidence": {
    "effective_fp32_peak_gflops": 0.79
  }
}
11. Notes

주의 사항

compiler가 FMA를 다른 instruction sequence로 바꾸지 않도록 확인 필요

-lineinfo, --ptxas-options=-v 등으로 register usage와 instruction 형태를 확인

지나친 unroll은 register pressure를 증가시켜 오히려 throughput을 떨어뜨릴 수 있음

clock variation이 peak GFLOPS 추정에 영향을 줄 수 있음

추가 검증

disassembly 확인
→ 실제 FFMA instruction 비율 점검
12. Next Experiments

다음 실험

P9_fp16_tensorcore_throughput

이 실험은 FP16 / Tensor Core 경로의 실제 처리량을 측정한다.

P8_fp32_fma_throughput
        │
        ▼
compute throughput model

---

# 현재까지의 흐름

지금까지 GPU Probing Lab은 이렇게 쌓였습니다.

```text
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

P8_fp32_fma_throughput
→ FP32 compute ceiling

이제 memory 쪽만이 아니라 compute ceiling도 잡히기 시작했습니다.