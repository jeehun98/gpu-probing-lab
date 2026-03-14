# Experiment M1: Cache Line Size

## Goal

GPU L1/L2 cache line size 추정

## Hypothesis

stride memory access 패턴에서 cache line boundary에서 latency spike 발생

## Kernel Pattern

thread i -> A[i * stride]

stride sweep

1  
2  
4  
8  
16  
32  
64  
128  

## Measurement

average latency per access

## Expected Result

latency step 증가

## Inference Rule

latency spike가 발생하는 stride ≈ cache line size