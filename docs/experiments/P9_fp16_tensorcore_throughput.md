# P9 — FP16 / Tensor Core Throughput
GPU Probing Lab Experiment

---

# 1. Goal

FP16 arithmetic path 및 Tensor Core path의 실제 처리량을 측정하여 GPU mixed-precision compute subsystem의 특성을 추정한다.

이 실험을 통해 다음 특성을 관측한다.

- effective FP16 throughput
- Tensor Core peak throughput
- Tensor Core saturation point
- Tensor Core utilization sensitivity
- mixed precision compute efficiency

이 실험은 GPU compute subsystem 중 **FP16 / Tensor Core 실행 경로의 ceiling**을 정의하는 실험이다.

---

# 2. Hypothesis

GPU는 FP32 pipeline 외에 FP16 연산 경로 또는 Tensor Core 전용 경로를 가진다.

충분히 큰 matrix multiply 또는 repeated MMA workload를 사용하면 다음 현상이 나타난다.

1. 일반 FP16 FMA path보다 Tensor Core path가 훨씬 높은 throughput을 보인다.
2. tile shape, alignment, fragment layout이 맞을 때 peak에 가까워진다.
3. 작은 workload 또는 잘못된 shape에서는 Tensor Core가 충분히 포화되지 않는다.
4. saturation 이후 throughput은 plateau를 형성한다.

즉, 이 실험은 Tensor Core가 **언제 실제로 이득을 주는지**를 측정하는 실험이다.

---

# 3. Controlled Variable

이 실험에서 변화시키는 변수

```text
tile_count

또는

mma_repeat

sweep 예시

1
2
4
8
16
32
64
128

선택적으로 함께 바꿀 수 있는 변수

tile_shape
warp_count
fragment_layout
alignment

첫 버전에서는 다음 두 모드로 나눈다.

Mode A: FP16 FMA loop
Mode B: Tensor Core MMA loop
4. Fixed Conditions
Parameter	Value
Block Size	warp multiple
Grid Size	GPU saturation 기준으로 충분히 크게 설정
Iterations	2048 이상
Repeat Count	30
Warmup Runs	10

추가 조건

memory traffic 최소화

fragment load/store 외에는 shared/global memory 접근 최소화

Tensor Core path와 non-Tensor Core path를 분리 측정

compiler dead-code elimination 방지

5. Kernel Pattern
Mode A — FP16 Arithmetic Baseline

FP16 연산 경로의 baseline 측정용

CUDA pseudo kernel

__global__ void fp16_fma_test(half* out)
{
    int tid = threadIdx.x + blockIdx.x * blockDim.x;

    half a0 = __float2half(1.001f);
    half b0 = __float2half(1.002f);
    half x0 = __float2half((float)tid);

    #pragma unroll
    for (int i = 0; i < 4096; i++)
    {
        x0 = __hfma(a0, x0, b0);
    }

    out[tid] = x0;
}
Mode B — Tensor Core MMA Path

WMMA 또는 MMA instruction 기반 microkernel

CUDA pseudo kernel

#include <mma.h>
using namespace nvcuda;

__global__ void tensorcore_mma_test(half* A, half* B, float* C)
{
    wmma::fragment<wmma::matrix_a, 16, 16, 16, half, wmma::row_major> a_frag;
    wmma::fragment<wmma::matrix_b, 16, 16, 16, half, wmma::col_major> b_frag;
    wmma::fragment<wmma::accumulator, 16, 16, 16, float> c_frag;

    wmma::fill_fragment(c_frag, 0.0f);
    wmma::load_matrix_sync(a_frag, A, 16);
    wmma::load_matrix_sync(b_frag, B, 16);

    #pragma unroll
    for (int i = 0; i < MMA_REPEAT; i++)
    {
        wmma::mma_sync(c_frag, a_frag, b_frag, c_frag);
    }

    wmma::store_matrix_sync(C, c_frag, 16, wmma::mem_row_major);
}

중요 포인트

WMMA shape가 architecture 지원 shape와 일치해야 함

fragment load/store 비용과 MMA cost를 분리해서 해석해야 함

Tensor Core path에 실제로 매핑되었는지 disassembly로 확인 필요

6. Measurement

각 repeat/tile_count에 대해 다음 값을 측정한다.

Runtime Metrics

kernel execution time

Hardware Metrics (Nsight Compute)

sm__pipe_tensor_throughput
smsp__inst_executed_pipe_tensor
smsp__inst_executed_pipe_fp16
smsp__issue_active
achieved_occupancy

Derived Metrics

effective_fp16_tflops
effective_tensorcore_tflops
tensor_utilization

계산 예시

FP16 FMA mode
TFLOPS =
(total_fp16_fma_count × 2) / execution_time
Tensor Core mode
TFLOPS =
(total_mma_flops) / execution_time

주의:
MMA 한 번의 FLOP 수는 tile shape에 따라 정확히 계산해야 한다.

7. Expected Pattern
FP16 arithmetic baseline
TFLOPS
│
│         ┌────────
│      ┌──┘
│   ┌──┘
│───┘
└────────────────────
   repeat / unroll
Tensor Core path
TFLOPS
│
│             ┌────────────
│         ┌───┘
│      ┌──┘
│   ┌──┘
│───┘
└──────────────────────────
      repeat / tile count

특징

FP16 arithmetic path보다 Tensor Core path plateau가 훨씬 높음

alignment나 tile mismatch가 있으면 plateau가 낮아짐

saturation 전에는 throughput이 급격히 증가

saturation 이후에는 plateau 형성

8. Inference Rule
Rule 1 — Effective FP16 Peak

FP16 arithmetic baseline의 plateau 평균

effective_fp16_peak =
mean(TFLOPS in plateau region)
Rule 2 — Effective Tensor Core Peak

Tensor Core mode의 plateau 평균

effective_tensorcore_peak =
mean(TFLOPS in plateau region)
Rule 3 — Tensor Core Gain
tensorcore_gain =
effective_tensorcore_peak / effective_fp16_peak

이 값이 크면 Tensor Core path의 실제 이점이 큼.

Rule 4 — Tensor Saturation Point
tensor_saturation_point =
first repeat where delta_tflops < threshold
Rule 5 — Shape / Alignment Sensitivity

shape 또는 alignment를 달리한 실험 비교

shape_penalty =
peak_tflops_optimal / peak_tflops_misaligned

이를 통해 Tensor Core path가 얼마나 제약적인지 평가할 수 있다.

9. Output Format

실험 결과 JSON

{
  "probe": "fp16_tensorcore_throughput",
  "device": "sm86",
  "mode": ["fp16_fma", "tensorcore_mma"],
  "repeat_values": [1,2,4,8,16,32,64,128],
  "runtime_ms": {
    "fp16_fma": [1.22,0.74,0.49,0.33,0.28,0.27,0.27,0.27],
    "tensorcore_mma": [0.88,0.44,0.24,0.15,0.11,0.10,0.10,0.10]
  },
  "tflops": {
    "fp16_fma": [8.2,13.6,20.1,28.5,33.2,34.0,34.1,34.0],
    "tensorcore_mma": [15.1,30.2,55.8,84.1,109.5,118.8,119.4,119.2]
  },
  "metrics": {
    "tensor_pipe_util": [],
    "issue_active": []
  }
}
10. Derived Property Output

analysis 결과

{
  "device": "sm86",
  "properties": {
    "effective_fp16_peak_tflops": 34.1,
    "effective_tensorcore_peak_tflops": 119.4,
    "tensorcore_gain_over_fp16": 3.50,
    "tensorcore_saturation_repeat": 32
  },
  "confidence": {
    "effective_tensorcore_peak_tflops": 0.81
  }
}
11. Notes

주의 사항

실제 Tensor Core instruction이 생성되었는지 반드시 확인해야 한다.

WMMA API를 사용해도 shape/layout이 맞지 않으면 기대만큼 성능이 나오지 않을 수 있다.

fragment load/store 비용이 커지면 Tensor Core pure compute ceiling과 섞일 수 있다.

register pressure와 shared memory usage가 Tensor Core throughput을 제한할 수 있다.

architecture별 지원 MMA shape가 다를 수 있다.

추가 검증

cuobjdump / disassembly 확인
→ mma.sync 또는 관련 tensor instruction 존재 확인
12. Next Experiments

다음 실험

P10_register_granularity_probe

또는

P10_latency_hiding_mix

중 하나로 진행 가능하다.

P9_fp16_tensorcore_throughput
        │
        ▼
mixed precision compute model