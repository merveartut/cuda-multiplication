
#include "cuda_runtime.h"
#include "device_launch_parameters.h"



#include <iostream>




__global__ void matrixMul(const int* a, const int* b, int* c, int size) {
    // Thread'lerin satır ve sütun indexlerini hesapla
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int c_sum = 0;
    // multiplication islemini yap
    c[row * size + col] = 0;
    for (int k = 0; k <size; k++) {
       
       c_sum += a[row * size + k] * b[k * size + col];
    }
    c[row * size + col] = c_sum;   // sonucu c dizisine ata

}

void cpuMul(int* a, int* b, int* c, int N) {
   
    for (int i = 0; i < N; i++) {
        
        for (int j = 0; j < N; j++) {
                                                //her satır ve her sutun icin carpim hesaplama
            int tmp = 0;
            for (int k = 0; k < N; k++) {
               
                tmp += a[i * N + k] * b[k * N + j];
            }

            c[i * N + j] = tmp;
        }
    }
}
int main() {
    
    int n = 1 << 10;

    

    int* h_a;
    int* h_b;
    int* h_c;
    int* h_cc;

    int* d_a;
    int* d_b;
    int* d_c;
    int* d_cc;

    size_t bytes = n * n * sizeof(int);

    h_a = (int*)malloc(bytes);
    h_b = (int*)malloc(bytes);
    h_c = (int*)malloc(bytes);
    h_cc = (int*)malloc(bytes);

    for (int i = 0; i < n;i++) {           //matrisleri random olustur
        for (int j = 0;j < n;j++) {
            h_a[i * n + j] = rand() % 1024;
            h_b[i * n + j] = rand() % 1024;
        }
    }

    cudaMalloc(&d_a, bytes);
    cudaMalloc(&d_b, bytes);
    cudaMalloc(&d_c, bytes);
    cudaMalloc(&d_cc, bytes);

    cudaMemcpy(d_a, h_a, bytes, cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, h_b, bytes, cudaMemcpyHostToDevice);

    int threads_per_block = 16;
    dim3 blocks(threads_per_block, threads_per_block);
    dim3 grid(n / blocks.x, n / blocks.y);

    matrixMul<<<grid,blocks>>> (d_a, d_b, d_c, n);   //kernel cagrisi gonder

    cudaMemcpy(h_c, d_c, bytes, cudaMemcpyDeviceToHost);

    cpuMul(h_a, h_b, h_cc, n); //cpu hesaplamasi 

    int ok = 1;
    for (int i = 0; i < n; ++i)        //cpu ve gpu sonuclarini karsilastir
    {
        for (int j = 0; j < n; ++j)
        {
            
            if (h_cc[i * n + j] != h_c[i * n + j])
            {
                ok = 0;
            }
        }
    
    }


    if (ok)
    {
        printf("tum sonuclar dogru!");
    }
    else
    {
        printf("sonuclar yanlis! ");
    }


    cudaFree(d_a);
    cudaFree(d_b);
    cudaFree(d_c);

 
    return 0;
}