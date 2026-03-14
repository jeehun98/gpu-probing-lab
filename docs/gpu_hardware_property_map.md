GPU Hardware Property Map

GPU Probing Lab – Conceptual Map

                         GPU HARDWARE
                              │
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
  MEMORY SUBSYSTEM     COMPUTE SUBSYSTEM     EXECUTION MODEL
1. Memory Subsystem

GPU 성능에서 가장 큰 영향을 주는 영역입니다.

MEMORY SUBSYSTEM
│
├── Global Memory Behavior
│   │
│   ├─ Cache Line Size
│   │      ↑
│   │   P1_global_stride_sweep
│   │
│   ├─ Memory Transaction Size
│   │      ↑
│   │   P6_global_vector_load_compare
│   │
│   └─ Coalescing Efficiency
│          ↑
│       P1_global_stride_sweep
│
├── Cache Hierarchy
│   │
│   ├─ L1 Latency
│   │
│   ├─ L2 Latency
│   │
│   ├─ DRAM Latency
│   │      ↑
│   │   P5_pointer_chasing_latency
│   │
│   └─ Effective L2 Capacity
│          ↑
│       P7_l2_working_set_sweep
│
└── Shared Memory
    │
    ├─ Bank Count
    │
    ├─ Bank Mapping Rule
    │
    └─ Conflict Penalty
           ↑
        P2_shared_bank_stride_sweep
2. Compute Subsystem

GPU의 연산 유닛 처리량과 관련된 속성입니다.

COMPUTE SUBSYSTEM
│
├── FP32 Pipeline
│   │
│   ├─ Peak FP32 Throughput
│   │
│   ├─ Pipeline Saturation Point
│   │
│   └─ Instruction Issue Efficiency
│        ↑
│     P8_fp32_fma_throughput
│
├── Tensor Core / FP16
│   │
│   ├─ Tensor Core Throughput
│   │
│   └─ Mixed Precision Efficiency
│        ↑
│     P9_fp16_tensorcore_throughput
│
└── Register System
    │
    ├─ Register File Size
    │
    ├─ Allocation Granularity
    │
    └─ Register Pressure Cliff
           ↑
        P3_register_pressure_sweep
3. Execution Model

GPU의 SIMT execution behavior를 관측합니다.

EXECUTION MODEL
│
├── Warp Structure
│   │
│   └─ Warp Size
│
├── Branch Execution
│   │
│   ├─ Divergence Penalty
│   │
│   └─ Warp Execution Efficiency
│        ↑
│     P4_branch_divergence_sweep
│
└── Scheduler Behavior
    │
    ├─ Latency Hiding
    │
    ├─ Warp Interleaving
    │
    └─ Execution Overlap
         ↑
      (future probe)
전체 구조 (요약)

GPU probing 프로젝트는 결국 이 구조를 복원하는 작업입니다.

GPU
│
├── Memory
│   ├── Transaction
│   ├── Cache
│   ├── Latency
│   └── Shared Memory
│
├── Compute
│   ├── FP32
│   ├── Tensor Core
│   └── Registers
│
└── Execution
    ├── Warp
    ├── Divergence
    └── Scheduler

각 probing kernel은 이 지도에서 하나의 속성을 드러내는 센서 역할을 합니다.

실험 → 속성 맵
Probe	관측 속성
P1_global_stride_sweep	cache line / coalescing
P2_shared_bank_stride_sweep	shared memory bank structure
P3_register_pressure_sweep	register pressure / occupancy
P4_branch_divergence_sweep	SIMT divergence
P5_pointer_chasing_latency	cache latency hierarchy
P6_global_vector_load_compare	memory transaction size
P7_l2_working_set_sweep	cache capacity
P8_fp32_fma_throughput	FP32 compute ceiling
P9_tensorcore_throughput	tensor core peak
최종 산출물 (프로젝트 목표)

이 실험들을 실행하면 결국 GPU hardware profile이 생성됩니다.

예시:

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
  tensorcore_peak_tflops: 120
  register_file_per_sm: 65536

execution:
  warp_size: 32
  divergence_penalty: 1.9

이게 바로 GPU Hardware Property Map의 실제 데이터 버전입니다.

이 프로젝트가 흥미로운 이유

이 접근은 GPU를 다음처럼 바라봅니다.

GPU = black box hardware
        +
carefully designed probe kernels
        ↓
observable execution behavior
        ↓
hardware property inference

즉 GPU를 실험적으로 해부하는 프로젝트입니다.