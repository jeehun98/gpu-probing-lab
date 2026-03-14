# GPU Probing Lab

**GPU Probing Lab**은 GPU를 단순한 계산 장치가 아니라  
**관측 가능한 계산 시스템(observable computational system)**으로 다루는 실험 프로젝트입니다.

이 프로젝트는 carefully designed probing kernels를 통해 GPU의 숨겨진 하드웨어 속성과 동적 실행 행동을 실험적으로 드러내는 것을 목표로 합니다.

---

# Motivation

현대 GPU는 결정론적 시스템이지만 실제 실행 과정은 완전히 관측 가능하지 않습니다.

Profiling 도구는 다음과 같은 aggregate metric만 제공합니다.

SM utilization  
DRAM throughput  
warp stall reason  
L2 hit rate  

그러나 실제 성능을 결정하는 것은 다음과 같은 내부 특성입니다.

- cache line size
- memory transaction size
- shared memory bank mapping
- register allocation policy
- warp scheduling heuristics

이러한 특성은 문서화되지 않거나 부분적으로만 공개되어 있습니다.

GPU Probing Lab은 **실험적 probing kernel 집합을 통해 이러한 속성을 추정(infer)**합니다.

---

# Core Idea

특정 실행 패턴을 가진 커널을 설계하면 GPU 내부 행동을 유도할 수 있습니다.


probing kernel
│
▼
GPU execution
│
▼
observable metrics
│
▼
hardware behavior inference

Stride memory test


thread i -> A[i]
thread i -> A[i2]
thread i -> A[i4]
thread i -> A[i*8]

stride 변화에 따른 latency spike를 통해 cache line size를 추정할 수 있습니다.

---

# Property Catalog

GPU Probing Lab은 다음 세 가지 범주의 하드웨어 속성을 관측합니다.

## Memory Hierarchy

| ID | Property |
|----|--------|
| M1 | Cache Line Size |
| M2 | Memory Transaction Size |
| M3 | Shared Memory Bank Mapping |
| M4 | L2 Cache Associativity |

## Compute Resources

| ID | Property |
|----|--------|
| C1 | Register File Size per SM |
| C2 | Register Allocation Granularity |
| C3 | Instruction Throughput |
| C4 | Shared Memory Capacity |

## Execution Policy

| ID | Property |
|----|--------|
| S1 | Warp Scheduling Heuristics |
| S2 | Branch Divergence Penalty |

---

# Project Structure


gpu-probing-lab/
│
├─ docs/
│ experiment design and inference documentation
│
├─ probes/
│ CUDA probing kernels
│
├─ harness/
│ experiment runner and profiling automation
│
├─ analysis/
│ inference logic and visualization
│
├─ results/
│ raw and processed measurement results
│
└─ configs/
device specific experiment configurations


---

# Example Workflow

1. run probing kernel


python harness/run_probe.py probes/memory/cache_line_size.cu


2. collect metrics


python harness/collect_ncu.py


3. analyze results


python analysis/infer/cache_line.py


4. update property catalog


docs/experiments/M1_cache_line_size.md


---

# Relationship with AICF

GPU Probing Lab은 컴파일러 프로젝트와 직접 결합되지는 않지만 다음과 같이 활용될 수 있습니다.


hardware property
│
▼
kernel design heuristics
│
▼
compiler optimization decisions


즉 **hardware characterization layer** 역할을 수행합니다.

---

# Future Work

- automatic probing kernel generation
- GPU architecture comparison
- execution behavior modeling
- optimization hint generation for compilers

---
