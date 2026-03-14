# GPU Probing Experiments

이 디렉토리는 GPU Probing Lab의 실험 문서를 포함합니다.

각 실험은 GPU의 특정 하드웨어 속성을 관측하기 위한 **probing kernel**을 기반으로 설계되었습니다.

GPU Probing Lab의 실험 철학은 다음과 같습니다.

> Carefully designed kernels can expose hidden hardware behavior.

즉 GPU를 black box 시스템으로 보고  
실험을 통해 내부 구조를 추정합니다.

---

# Experiment Methodology

GPU probing 실험은 다음 구조를 따릅니다.


controlled kernel pattern
↓
GPU execution
↓
observable runtime metrics
↓
pattern detection
↓
hardware property inference


각 실험은 특정 하드웨어 속성 하나를 관측하도록 설계됩니다.

---

# Experiment Design Principles

GPU probing 실험은 다음 원칙을 따릅니다.

### 1. Single Behavior Isolation

각 실험은 가능한 한 **하나의 하드웨어 특성만 자극**하도록 설계합니다.

예


memory access pattern
register pressure
branch divergence


---

### 2. Parameter Sweep

실험은 항상 **parameter sweep 형태**로 수행됩니다.

예


stride = 1,2,4,8,16...
working_set = 1KB → 64MB
unroll_factor = 1 → 64


이렇게 하면 그래프에서 패턴이 드러납니다.

---

### 3. Noise Reduction

GPU 실행 결과는 노이즈가 많기 때문에 다음 절차를 사용합니다.


warmup runs
multiple repetitions
median result


---

### 4. Hardware Metric Correlation

가능한 경우 profiling metrics를 함께 수집합니다.

예


dram throughput
l2 hit rate
warp execution efficiency


이를 통해 runtime 패턴을 해석합니다.

---

# Experiment Categories

GPU probing 실험은 다음 네 가지 영역으로 나뉩니다.

| Category | Description |
|---|---|
Memory | global memory / cache behavior |
Shared Memory | bank mapping and conflicts |
Compute | arithmetic throughput |
Execution | SIMT execution behavior |

---

# Implemented Experiments

## Memory Probes

| ID | Experiment | Observed Property |
|---|---|---|
P1 | Global Stride Sweep | cache line size / coalescing |
P5 | Pointer Chasing Latency | cache latency hierarchy |
P6 | Vector Load Compare | memory transaction size |
P7 | L2 Working Set Sweep | effective L2 capacity |

---

## Shared Memory Probes

| ID | Experiment | Observed Property |
|---|---|---|
P2 | Shared Bank Stride Sweep | shared memory bank mapping |

---

## Compute Probes

| ID | Experiment | Observed Property |
|---|---|---|
P3 | Register Pressure Sweep | register pressure cliff |
P8 | FP32 FMA Throughput | FP32 compute ceiling |
P9 | FP16 TensorCore Throughput | Tensor Core throughput |

---

## Execution Probes

| ID | Experiment | Observed Property |
|---|---|---|
P4 | Branch Divergence Sweep | SIMT divergence penalty |

---

# Experiment Dependency Graph

일부 실험은 다른 실험 결과를 기반으로 해석됩니다.


P1_global_stride_sweep
│
▼
memory coalescing model

P5_pointer_chasing_latency
│
▼
memory latency hierarchy

P7_l2_working_set_sweep
│
▼
cache capacity model


compute 실험


P3_register_pressure_sweep
│
▼
occupancy model

P8_fp32_fma_throughput
│
▼
compute ceiling

P9_tensorcore_throughput
│
▼
mixed precision compute model


---

# Running Experiments

각 실험은 다음 방식으로 실행됩니다.


probe kernel
→ parameter sweep
→ runtime measurement
→ metric collection
→ result storage


예


python harness/run_probe.py probes/memory/global_stride_sweep.cu


결과는 다음 위치에 저장됩니다.


results/raw


---

# Result Interpretation

analysis 단계에서 다음 과정을 수행합니다.


raw measurement
↓
feature extraction
↓
pattern detection
↓
property estimation


예


latency spike → cache line size
throughput plateau → compute peak


---

# Output: Hardware Property Model

모든 실험 결과는 GPU hardware profile로 통합됩니다.

예

```yaml
device: RTX3080_SM86

memory:
  cache_line_bytes: 128
  transaction_bytes: 32
  l1_latency_cycles: 32
  l2_latency_cycles: 95

shared_memory:
  bank_count: 32

compute:
  fp32_peak_gflops: 22880
  tensorcore_peak_tflops: 119

execution:
  warp_size: 32
  divergence_penalty: 1.9
Future Experiments

GPU Probing Lab은 다음 추가 실험을 계획하고 있습니다.

ID	Experiment
P10	Register Allocation Granularity
P11	Warp Scheduler Behavior
P12	Latency Hiding Efficiency
P13	Memory Arbitration Behavior
P14	Warp Issue Pattern

이 실험들은 GPU execution policy를 더 깊이 분석합니다.

Summary

GPU Probing Lab experiments aim to transform runtime observations into hardware knowledge.

probing kernel
        ↓
execution observation
        ↓
behavior inference
        ↓
hardware property model

이 접근을 통해 GPU 내부 구조를 실험적으로 분석할 수 있습니다.