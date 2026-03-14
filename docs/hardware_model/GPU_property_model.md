# GPU Hardware Property Model

GPU Probing Lab은 GPU를 단순한 계산 장치가 아니라  
**관측 가능한 하드웨어 시스템 (observable hardware system)**으로 모델링합니다.

이 문서는 GPU Probing Lab에서 사용하는 **GPU hardware property model**을 정의합니다.

---

# 1. Overview

GPU는 매우 복잡한 마이크로아키텍처를 가지지만  
성능 관점에서 보면 다음 네 가지 subsystem으로 분해할 수 있습니다.


GPU
│
├─ Memory Subsystem
├─ Shared Memory Subsystem
├─ Compute Subsystem
└─ Execution Subsystem


각 subsystem은 probing 실험을 통해 관측 가능한 **hardware properties**로 표현됩니다.

---

# 2. Memory Subsystem

Memory subsystem은 global memory access behavior를 정의합니다.

이 subsystem은 다음 속성으로 모델링됩니다.

| Property | Description |
|---|---|
cache_line_bytes | cache line 크기 |
transaction_bytes | memory transaction 단위 |
l1_latency_cycles | L1 cache latency |
l2_latency_cycles | L2 cache latency |
dram_latency_cycles | global memory latency |
l2_effective_capacity | effective L2 cache size |

---

## Memory Access Model

global memory access는 다음 모델로 표현됩니다.


memory access cost =
latency

transaction_cost

coalescing_penalty


각 항목은 probing 실험으로 추정됩니다.

---

## Observed By

| Experiment | Observed Property |
|---|---|
P1_global_stride_sweep | cache line / coalescing |
P5_pointer_chasing_latency | latency hierarchy |
P6_global_vector_load_compare | transaction size |
P7_l2_working_set_sweep | L2 effective capacity |

---

# 3. Shared Memory Subsystem

shared memory는 GPU의 on-chip memory이며 bank 구조를 가집니다.

shared memory subsystem은 다음 속성으로 모델링됩니다.

| Property | Description |
|---|---|
bank_count | shared memory bank 개수 |
bank_width_bytes | bank addressing width |
bank_conflict_penalty | bank conflict cost |

---

## Bank Mapping Model

shared memory address는 다음 방식으로 bank에 매핑됩니다.


bank_id =
(address / bank_width) % bank_count


동일 bank에 접근하면 conflict가 발생합니다.

---

## Observed By

| Experiment | Observed Property |
|---|---|
P2_shared_bank_stride_sweep | bank mapping / conflict penalty |

---

# 4. Compute Subsystem

Compute subsystem은 arithmetic pipeline의 처리량을 정의합니다.

| Property | Description |
|---|---|
fp32_peak_gflops | FP32 compute throughput |
fp16_peak_tflops | FP16 arithmetic throughput |
tensorcore_peak_tflops | Tensor Core throughput |
register_file_size | register file capacity |
register_allocation_granularity | register allocation unit |
register_pressure_cliff | occupancy collapse point |

---

## Compute Performance Model

compute bound kernel의 성능은 다음으로 표현됩니다.


compute_time =
operation_count / effective_compute_throughput


effective throughput은 pipeline utilization에 따라 달라집니다.

---

## Observed By

| Experiment | Observed Property |
|---|---|
P3_register_pressure_sweep | register pressure |
P8_fp32_fma_throughput | FP32 compute ceiling |
P9_fp16_tensorcore_throughput | Tensor Core peak |

---

# 5. Execution Subsystem

Execution subsystem은 GPU의 SIMT execution model을 정의합니다.

| Property | Description |
|---|---|
warp_size | warp thread count |
divergence_penalty | branch divergence cost |
warp_execution_efficiency | warp execution utilization |

---

## SIMT Execution Model

warp는 다음 방식으로 실행됩니다.


warp_execution_time =
active_threads

divergence_penalty

instruction_latency


branch divergence가 발생하면 warp는 serialized execution을 수행합니다.

---

## Observed By

| Experiment | Observed Property |
|---|---|
P4_branch_divergence_sweep | divergence penalty |

---

# 6. Unified GPU Property Model

위 네 subsystem을 결합하면 GPU 성능 모델은 다음과 같이 표현됩니다.


kernel_time =
max(
memory_time,
compute_time,
execution_overhead
)


여기서


memory_time =
data_movement / memory_bandwidth

compute_time =
operations / compute_throughput

execution_overhead =
divergence + scheduling


이 모델은 GPU kernel 성능 분석의 기본 구조가 됩니다.

---

# 7. Hardware Property Profile

GPU probing 실험 결과는 다음과 같은 hardware profile로 표현됩니다.

```yaml
device: RTX3080_SM86

memory:
  cache_line_bytes: 128
  transaction_bytes: 32
  l1_latency_cycles: 32
  l2_latency_cycles: 95
  dram_latency_cycles: 230
  l2_effective_capacity: 3MB

shared_memory:
  bank_count: 32
  bank_conflict_penalty: 2.7

compute:
  fp32_peak_gflops: 22880
  tensorcore_peak_tflops: 119
  register_file_size: 65536

execution:
  warp_size: 32
  divergence_penalty: 1.9
8. Why This Model Matters

GPU hardware property model은 다음 용도로 사용될 수 있습니다.

GPU kernel optimization

compiler backend tuning

performance modeling

architecture comparison

auto-tuning systems

즉 GPU probing은 단순 benchmark가 아니라

hardware behavior → property model → optimization insight

로 이어지는 연구 접근입니다.

9. Future Extensions

GPU probing model은 다음 방향으로 확장될 수 있습니다.

Future Property	Description
warp_scheduler_policy	warp scheduling heuristic
latency_hiding_efficiency	latency hiding ability
memory_arbitration	memory request arbitration
warp_issue_pattern	instruction issue behavior

이 속성들은 더 복잡한 probing 실험을 통해 추정할 수 있습니다.


---

# 이 문서가 중요한 이유

이 문서는 프로젝트에서 **가장 중요한 문서 중 하나**입니다.

왜냐하면 이 문서가


experiments
↓
hardware property
↓
performance model


을 연결해 줍니다.

즉 이 프로젝트는


microbenchmark collection


이 아니라


GPU hardware property inference framework


로 보이게 됩니다.

---

# 다음 단계로 추천

지금 구조에서 다음 문서가 있으면 **프로젝트 완성도가 크게 올라갑니다.**


docs/inference/inference_rules.md


이 문서는 다음을 설명합니다.


experiment result
↓
feature extraction
↓
pattern detection
↓
hardware property estimation


즉 **실험 데이터를 어떻게 해석하는지**를 정의합니다.

---