# GPU Observation Theory
Toward Experimental Understanding of GPU Hardware Behavior

---

# 1. Introduction

현대 GPU는 매우 복잡한 계산 장치이며 많은 내부 동작이 완전히 공개되어 있지 않습니다.

예를 들어 다음과 같은 질문은 공식 문서에서 정확히 설명되지 않습니다.

- 실제 cache line size는 무엇인가?
- memory transaction은 어떻게 발생하는가?
- shared memory bank는 어떤 규칙으로 매핑되는가?
- warp scheduler는 어떤 정책으로 동작하는가?

이러한 정보는 성능 최적화에 매우 중요하지만 GPU는 내부 구조를 완전히 공개하지 않습니다.

GPU Probing Lab은 다음 질문에서 출발합니다.

> **GPU 내부 동작을 실험적으로 관측할 수 있을까?**

---

# 2. GPU as a Black Box System

GPU Probing Lab은 GPU를 다음과 같이 바라봅니다.


GPU = complex hardware system


하지만 개발자는 내부 구현을 직접 볼 수 없습니다.

따라서 GPU는 다음과 같은 **black box system**으로 모델링됩니다.


input
(kernel execution)
↓
GPU hardware
↓
observable signals
(runtime / metrics)


즉 우리는 내부 구조를 직접 보지 않고  
**입력과 출력 사이의 관계를 통해 내부 특성을 추정합니다.**

---

# 3. Observability in Hardware Systems

이 접근은 물리학 및 시스템 연구에서 자주 사용되는 방법입니다.

예

- particle physics
- network tomography
- performance modeling

이 분야에서는 다음 접근을 사용합니다.


controlled experiment
↓
measure observable signals
↓
infer hidden structure


GPU probing도 동일한 철학을 따릅니다.

---

# 4. Probing Methodology

GPU probing은 다음 구조로 진행됩니다.


probe kernel
↓
controlled execution
↓
observable runtime behavior
↓
pattern detection
↓
hardware property inference


이 접근의 핵심은 **probe kernel 설계**입니다.

probe kernel은 특정 하드웨어 행동을 자극하도록 설계됩니다.

예

| Probe Type | Observed Behavior |
|---|---|
stride sweep | cache line / coalescing |
pointer chasing | memory latency |
register pressure | occupancy behavior |
branch divergence | SIMT execution |

---

# 5. GPU Execution as Observable Phenomenon

GPU execution은 단순한 프로그램 실행이 아니라  
다양한 하드웨어 메커니즘의 결과입니다.

예


memory access
↓
cache hierarchy
↓
memory transaction
↓
latency


또는


register allocation
↓
occupancy change
↓
runtime variation


이러한 실행 결과는 **observable phenomena**로 나타납니다.

GPU probing은 이러한 현상을 관측합니다.

---

# 6. Hardware Property Inference

GPU probing의 목표는 단순한 benchmark가 아닙니다.

목표는 다음입니다.


execution observation
↓
behavior pattern
↓
hardware property


예


latency spike → cache line size
throughput plateau → compute peak
capacity cliff → cache capacity


이러한 규칙을 통해 GPU hardware property model을 구성합니다.

---

# 7. GPU Hardware Knowledge

GPU probing을 통해 얻을 수 있는 knowledge는 다음과 같습니다.

| Property | Description |
|---|---|
cache line size | memory access granularity |
transaction size | memory transaction unit |
latency hierarchy | L1/L2/DRAM latency |
bank mapping | shared memory bank structure |
register pressure | register allocation behavior |
compute peak | arithmetic throughput |

이 정보는 GPU kernel optimization에 직접 활용됩니다.

---

# 8. Relation to Performance Modeling

GPU probing 결과는 performance modeling의 기초가 됩니다.

GPU kernel 실행 시간은 다음으로 표현할 수 있습니다.


kernel_time =
max(
memory_time,
compute_time,
execution_overhead
)


각 항목은 probing 실험으로 추정됩니다.

---

# 9. Why This Matters

GPU probing은 다음 이유로 중요합니다.

### Performance Optimization

GPU kernel optimization은 하드웨어 특성을 이해해야 합니다.

### Compiler Design

컴파일러는 hardware-aware optimization을 수행해야 합니다.

### Architecture Comparison

GPU architecture 간 차이를 분석할 수 있습니다.

### Research

GPU hardware behavior를 체계적으로 연구할 수 있습니다.

---

# 10. Experimental Hardware Understanding

GPU Probing Lab의 핵심 철학은 다음 문장으로 요약됩니다.

> **GPU hardware behavior can be understood through controlled computational experiments.**

즉


GPU execution
↓
observable behavior
↓
hardware understanding


이라는 접근입니다.

---

# 11. Future Directions

GPU probing 연구는 다음 방향으로 확장될 수 있습니다.

- warp scheduler inference
- latency hiding analysis
- memory arbitration study
- cross-architecture comparison
- automatic probe generation

이 연구는 GPU hardware behavior를 더 깊이 이해하는 데 기여할 수 있습니다.

---

# 12. Summary

GPU Probing Lab은 GPU를 다음과 같이 바라봅니다.


GPU = observable computational system


따라서


carefully designed probe kernels
↓
controlled execution
↓
behavior observation
↓
hardware property inference


이라는 실험적 접근을 통해 GPU 내부 동작을 이해할 수 있습니다.