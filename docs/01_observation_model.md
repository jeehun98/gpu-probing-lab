# GPU Observation Model

GPU 실행에서 관측 가능한 정보는 다음 계층으로 나뉜다.

Level 1  
Program execution

kernel launch  
kernel duration  

Level 2  
Kernel metrics

SM utilization  
DRAM throughput  
L2 hit rate  

Level 3  
Execution flow

kernel ordering  
GPU idle region  

Level 4  
Hidden microarchitecture

warp scheduling  
cache replacement policy  
memory arbitration  

GPU probing의 목표는 Level 4 behavior를 Level 1~3 관측을 통해 추론하는 것이다.