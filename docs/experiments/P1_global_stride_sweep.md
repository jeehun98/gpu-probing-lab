# P1 — Global Memory Stride Sweep
*GPU Probing Lab Experiment*

---

# 1. Goal

Global memory 접근 패턴을 변화시키면서 실행 시간을 측정하여 다음 하드웨어 특성을 추정한다.

- L1/L2 cache line size
- global memory transaction boundary
- memory coalescing behavior

이 실험은 GPU memory hierarchy 분석의 **기초 실험**이며 이후 memory probing 실험의 기준점이 된다.

---

# 2. Hypothesis

Global memory 접근에서 stride가 cache line 또는 memory transaction boundary를 넘으면 다음 현상이 나타난다.

1. memory access latency 증가  
2. DRAM transaction 수 증가  
3. throughput 감소  

특히 특정 stride에서 **latency spike** 또는 **throughput step 변화**가 나타난다.

---

# 3. Controlled Variable

이 실험에서 변화시키는 변수는 다음 하나이다.

stride


stride는 다음 값들을 sweep한다.


1
2
4
8
16
32
64
128
256
512


stride는 element 단위 기준이다.

예:


thread i → A[i * stride]


---

# 4. Fixed Conditions

실험에서 다음 조건은 고정한다.

| Parameter | Value |
|---|---|
Block Size | 256 |
Grid Size | 256 |
Memory Size | ≥ 64MB |
Repeat Count | 50 |
Warmup Runs | 10 |

추가 조건

- GPU clock 변동 최소화
- 동일 stream 사용
- kernel launch overhead 제외

---

# 5. Kernel Pattern

각 thread는 stride 간격으로 global memory를 접근한다.


index = thread_id * stride
value = data[index]


CUDA pseudo kernel

```cpp
__global__ void stride_test(float* data, int stride, int N)
{
    int idx = threadIdx.x + blockIdx.x * blockDim.x;

    if (idx < N)
    {
        float v = data[idx * stride];
        data[idx] = v + 1.0f;
    }
}
6. Measurement

각 stride에 대해 다음 값을 측정한다.

Runtime Metrics

kernel execution time

latency per access

Hardware Metrics (optional)

Profiling tool:

NVIDIA Nsight Compute

수집 metric 예

dram__throughput
l2_tex__hit_rate
sm__throughput
Derived Metrics
latency_per_access
memory_bandwidth
7. Expected Pattern

stride sweep 결과는 다음과 같은 형태의 그래프를 보일 것으로 예상된다.

latency
│
│        ┌──────────
│        │
│        │
│   ─────┘
│
└────────────────────────
        stride

특징

small stride → latency 안정

특정 stride → latency jump

이후 plateau

이 jump 지점이 cache line 또는 memory transaction boundary를 나타낸다.

8. Inference Rule

실험 결과에서 다음 규칙으로 hardware property를 추정한다.

Rule 1 — Cache Line Size
latency spike stride × element_size ≈ cache line size

예

stride = 32
element = float (4B)

→ cache line ≈ 128B
Rule 2 — Memory Transaction Boundary

coalescing 효율이 급격히 감소하는 stride 위치

transaction_size ≈ stride_boundary × element_size
Rule 3 — Coalescing Behavior

throughput 변화로 판단

high throughput → good coalescing
low throughput → fragmented transactions
9. Output Format

실험 결과는 다음 JSON 형태로 저장한다.

{
  "probe": "global_stride_sweep",
  "device": "sm86",
  "stride_values": [1,2,4,8,16,32,64,128],
  "runtime_ms": [0.12,0.12,0.13,0.15,0.18,0.38,0.41,0.42],
  "metrics": {
    "dram_throughput": [],
    "l2_hit_rate": []
  }
}
10. Derived Property Output

analysis 단계에서 다음 property 후보를 생성한다.

{
  "device": "sm86",
  "properties": {
    "cache_line_size_bytes": 128,
    "memory_transaction_bytes": 32
  },
  "confidence": {
    "cache_line_size_bytes": 0.72,
    "memory_transaction_bytes": 0.55
  }
}
11. Notes

주의 사항

memory allocation은 cache warm-up 영향을 줄이기 위해 충분히 크게 설정

stride가 너무 커지면 memory locality가 완전히 사라질 수 있음

GPU clock scaling이 결과에 영향을 줄 수 있음

12. Next Experiments

이 실험 결과는 다음 실험의 기반이 된다.

M2 Memory Transaction Size

L2 Working Set Sweep

Pointer Chasing Latency

P1_global_stride_sweep
      │
      ▼
memory hierarchy model