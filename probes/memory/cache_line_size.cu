#include <cuda_runtime.h>
#include <stdio.h>

__global__ void stride_test(float* data, int stride, int N)
{
    int idx = threadIdx.x + blockIdx.x * blockDim.x;

    if(idx < N)
    {
        float x = data[idx * stride];
        data[idx] = x + 1.0f;
    }
}

int main()
{
    int N = 1<<20;

    float* d;
    cudaMalloc(&d, N * sizeof(float) * 256);

    for(int stride=1; stride<=256; stride*=2)
    {
        stride_test<<<256,256>>>(d, stride, N);
        cudaDeviceSynchronize();
    }

    cudaFree(d);
}