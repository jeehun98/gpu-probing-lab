Architecture Overview

GPU Probing Lab은 GPU를 단순한 실행 장치가 아니라 관측 가능한 계산 시스템 (observable computational system)으로 다루는 실험 프로젝트입니다.

프로젝트의 기본 아이디어는 다음과 같습니다.

carefully designed probing kernels
        ↓
controlled GPU execution
        ↓
hardware metrics observation
        ↓
behavior pattern detection
        ↓
hardware property inference

이 과정을 통해 GPU 내부 구조를 실험적으로 드러내는 hardware profile을 생성합니다.

System Architecture

아래 다이어그램은 GPU Probing Lab의 전체 구조를 보여줍니다.

Hardware Property Categories

GPU Probing Lab은 GPU를 다음 네 가지 subsystem으로 분해하여 관측합니다.

Subsystem	Example Properties
Memory	cache line size, memory transaction size, latency hierarchy
Shared Memory	bank count, bank mapping rule, conflict penalty
Compute	FP32 peak throughput, Tensor Core throughput, register pressure
Execution	warp divergence penalty, warp execution efficiency

각 probing kernel은 이 구조에서 특정 하드웨어 속성을 드러내는 역할을 합니다.

Probe → Property Mapping
Probe	Hardware Property
P1_global_stride_sweep	cache line size, coalescing behavior
P2_shared_bank_stride_sweep	shared memory bank mapping
P3_register_pressure_sweep	register pressure cliff
P4_branch_divergence_sweep	SIMT divergence behavior
P5_pointer_chasing_latency	L1/L2/DRAM latency
P6_global_vector_load_compare	memory transaction size
P7_l2_working_set_sweep	effective L2 capacity
P8_fp32_fma_throughput	FP32 compute ceiling
P9_fp16_tensorcore_throughput	Tensor Core peak throughput
Output: GPU Hardware Profile

최종적으로 GPU Probing Lab은 다음과 같은 hardware property profile을 생성합니다.

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
  register_file_per_sm: 65536

execution:
  warp_size: 32
  divergence_penalty: 1.9

이 profile은 다음 용도로 활용될 수 있습니다.

GPU kernel optimization

compiler backend tuning

performance modeling

architecture comparison

Core Idea

GPU Probing Lab의 핵심 철학은 다음 한 문장으로 요약됩니다.

GPU hardware behavior can be inferred through carefully designed probe kernels.

즉,

GPU hardware
+
probing experiments
↓
observable behavior
↓
hardware property inference

라는 접근을 취합니다.