# GPU Property Inference Rules

GPU Probing Lab은 probing kernel 실험 결과를 통해 GPU의 하드웨어 속성을 추정합니다.

이 문서는 **실험 데이터 → hardware property**로 변환하는 규칙을 정의합니다.

---

# 1. Inference Pipeline

GPU probing 분석 과정은 다음 단계로 구성됩니다.


raw measurements
↓
feature extraction
↓
pattern detection
↓
property estimation
↓
hardware profile


각 단계는 GPU 실행 패턴에서 의미 있는 신호를 추출합니다.

---

# 2. Raw Measurement Format

각 실험은 parameter sweep 형태로 실행됩니다.

예


stride = 1,2,4,8,16,32,64,128


각 parameter에 대해 다음 값을 기록합니다.

| Field | Description |
|---|---|
parameter | sweep parameter |
runtime | kernel execution time |
metrics | profiling metrics |
derived | computed throughput / latency |

예 JSON 결과

```json
{
  "probe": "global_stride_sweep",
  "stride_values": [1,2,4,8,16,32,64,128],
  "runtime_ns": [100,100,100,105,110,210,215,220]
}
3. Feature Extraction

raw measurement에서 다음 feature를 추출합니다.

Feature	Description
latency jump	sudden increase in latency
throughput plateau	throughput saturation
capacity cliff	performance drop due to capacity
conflict spike	shared memory conflict pattern

feature extraction은 실험 종류에 따라 달라집니다.

4. Pattern Detection

feature를 기반으로 패턴을 탐지합니다.

4.1 Latency Jump Detection

메모리 실험에서 cache boundary를 탐지합니다.

latency_ratio =
latency[i+1] / latency[i]

조건

latency_ratio > threshold

이면 cache line boundary 가능성이 있습니다.

4.2 Plateau Detection

compute throughput 실험에서 peak throughput을 찾습니다.

delta =
abs(value[i+1] - value[i])

plateau 조건

delta < epsilon

이 구간을 compute ceiling으로 판단합니다.

4.3 Capacity Cliff Detection

working set sweep에서 cache capacity를 추정합니다.

패턴

throughput
│
│───────
│       \
│        \____

cliff point를 cache capacity로 추정합니다.

5. Property Estimation Rules

각 probing 실험은 특정 property를 추정합니다.

P1 — Cache Line Size

입력

stride sweep latency

규칙

first latency spike
→ cache line boundary

property

cache_line_bytes ≈ stride_at_spike × element_size
P2 — Shared Memory Bank Count

입력

shared stride sweep latency

규칙

periodic conflict pattern

property

bank_count = stride_period
P3 — Register Pressure Cliff

입력

register count vs runtime

패턴

runtime spike

property

register_pressure_cliff =
register_count_at_spike
P4 — Branch Divergence Penalty

입력

divergence ratio vs runtime

property

divergence_penalty =
runtime_divergent / runtime_uniform
P5 — Memory Latency Hierarchy

입력

pointer chasing latency

패턴

L1 plateau
L2 plateau
DRAM plateau

property

l1_latency_cycles
l2_latency_cycles
dram_latency_cycles
P6 — Memory Transaction Size

입력

vector load throughput

패턴

throughput step

property

transaction_bytes
P7 — L2 Effective Capacity

입력

working set vs throughput

패턴

capacity cliff

property

l2_effective_capacity
P8 — FP32 Compute Peak

입력

FMA throughput vs unroll

패턴

throughput plateau

property

fp32_peak_gflops
P9 — Tensor Core Throughput

입력

mma throughput

패턴

plateau region

property

tensorcore_peak_tflops
6. Confidence Scoring

각 property는 confidence score를 가집니다.

confidence =
pattern_strength × signal_quality

예

Factor	Description
pattern_strength	spike / plateau clarity
signal_noise	runtime variance
metric_correlation	profiler metric match
7. Hardware Profile Assembly

모든 property는 하나의 GPU profile로 결합됩니다.

GPUProfile
├── memory
├── shared_memory
├── compute
└── execution

예

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
8. Limitations

GPU probing inference에는 다음 한계가 있습니다.

runtime noise

compiler optimization effects

architecture-specific behavior

undocumented hardware changes

따라서 inference 결과는 approximate hardware model로 해석해야 합니다.

9. Future Work

GPU probing inference engine은 다음 방향으로 확장될 수 있습니다.

Future Capability	Description
automatic probe generation	probe kernel 자동 생성
ML-based inference	ML 기반 property estimation
cross-GPU comparison	GPU architecture 비교
compiler integration	compiler optimization hint

---

# 지금 이 프로젝트 구조에서 중요한 점

지금까지 만든 문서들이 **GPU Probing Lab의 핵심 4개 축**입니다.


README.md
↓
experiments/
↓
hardware_model/
↓
inference/


즉


experiment
↓
observation
↓
property
↓
model


이라는 구조가 완성됩니다.
