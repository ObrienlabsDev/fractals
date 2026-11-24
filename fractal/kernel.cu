#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <iostream>
#include <time.h>

/**
* Michael O'Brien 20250121
* michael at obrienlabs.dev
* 128 bit version
* Mandelbrot set on NVidia GPUs like the RTX-3500 ada,RTX-A4000,RTX-A4500,RTX-4090 ada and RTX-A6000
* https://github.com/ObrienlabsDev/performance
* https://github.com/ObrienlabsDev/fractals
*
* https://docs.nvidia.com/cuda/floating-point/index.html 
*/
/*cudaError_t cudaFacade(double *c, double *a, double *b, unsigned int size);


__device__ uint32_t mandel_double(double cr, double ci, int max_iter) {
    double zr = 0;
    double zi = 0;
    double zrsqr = 0;
    double zisqr = 0;

    uint32_t i;

    for (i = 0; i < max_iter; i++) {
        zi = zr * zi;
        zi += zi;
        zi += ci;
        zr = zrsqr - zisqr + cr;
        zrsqr = zr * zr;
        zisqr = zi * zi;

        //the fewer iterations it takes to diverge, the farther from the set
        if (zrsqr + zisqr > 4.0) break;
    }

    return i;
}

__global__ void mandel_kernel(uint32_t* counts, double xmin, double ymin,
    double step, int max_iter, int dim, uint32_t* colors) {
    int pix_per_thread = dim * dim / (gridDim.x * blockDim.x);
    int tId = blockDim.x * blockIdx.x + threadIdx.x;
    int offset = pix_per_thread * tId;
    for (int i = offset; i < offset + pix_per_thread; i++) {
        int x = i % dim;
        int y = i / dim;
        double cr = xmin + x * step;
        double ci = ymin + y * step;
        counts[y * dim + x] = colors[mandel_double(cr, ci, max_iter)];
    }
    if (gridDim.x * blockDim.x * pix_per_thread < dim * dim
        && tId < (dim * dim) - (blockDim.x * gridDim.x)) {
        int i = blockDim.x * gridDim.x * pix_per_thread + tId;
        int x = i % dim;
        int y = i / dim;
        double cr = xmin + x * step;
        double ci = ymin + y * step;
        counts[y * dim + x] = colors[mandel_double(cr, ci, max_iter)];
    }
}

__global__ void addKernel(double *c, double *a, double *b)
{
    int x = threadIdx.x;

    double zr = 0;
    double zi = 0;
    double zrsqr = 0;
    double zisqr = 0;
    int max_iter = 2000;
    double ci = -0.59990625;// 0;
    double cr = 0.4290703125; //0;

    uint32_t i;

    for (i = 0; i < max_iter; i++) {
        zi = zr * zi;
        zi += zi;
        zi += ci;
        zr = zrsqr - zisqr + cr;
        zrsqr = zr * zr;
        zisqr = zi * zi;

        if (zrsqr + zisqr > 4.0) break;
    }
    c[x] = i;// zrsqr + zisqr;
}

void singleGPUMandelbrot() {
    int deviceCount = 0;
    int dualDevice = 0;
    cudaGetDeviceCount(&deviceCount);
    printf("%d CUDA devices found - reallocating\n", deviceCount);
    if (deviceCount > 1) {
        dualDevice = 1;
    }

    const int arraySize = 5;
    double a[arraySize] = { 1.0, 2.0, 3.0, 4.0, 5.0 };
    double b[arraySize] = { 10.0, 20.0, 30.0, 40.0, 50.0 };
    double c[arraySize] = { 0.0 };

    // Add vectors in parallel.
    cudaError_t cudaStatus = cudaFacade(c, a, b, arraySize);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addWithCuda failed!");
        return;
    }

    printf("{1,2,3,4,5} + {10,20,30,40,50} = {%lf,%lf,%lf,%lf,%lf}\n",
        c[0], c[1], c[2], c[3], c[4]);

    // cudaDeviceReset must be called before exiting in order for profiling and
    // tracing tools such as Nsight and Visual Profiler to show complete traces.
    cudaStatus = cudaDeviceReset();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceReset failed!");
        return;
    }
}


cudaError_t cudaFacade(double* c, double* a, double* b, unsigned int size)
{
    double* dev_a = 0;
    double* dev_b = 0;
    double* dev_c = 0;
    cudaError_t cudaStatus;
    // Choose which GPU to run on, change this on a multi-GPU system.
    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
        goto Error;
    }

    // Allocate GPU buffers for three vectors (two input, one output)    .
    cudaStatus = cudaMalloc((void**)&dev_c, size * sizeof(double));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_a, size * sizeof(double));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_b, size * sizeof(double));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    // Copy input vectors from host memory to GPU buffers.
    cudaStatus = cudaMemcpy(dev_a, a, size * sizeof(double), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    cudaStatus = cudaMemcpy(dev_b, b, size * sizeof(double), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    // Launch a kernel on the GPU with one thread for each element.
    addKernel << <1, size >> > (dev_c, dev_a, dev_b);

    // Check for any errors launching the kernel
    cudaStatus = cudaGetLastError();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
        goto Error;
    }

    // cudaDeviceSynchronize waits for the kernel to finish, and returns
    // any errors encountered during the launch.
    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
        goto Error;
    }

    // Copy output vector from GPU buffer to host memory.
    cudaStatus = cudaMemcpy(c, dev_c, size * sizeof(double), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

Error:
    cudaFree(dev_c);
    cudaFree(dev_a);
    cudaFree(dev_b);
    
    return cudaStatus;
}
*/
#define WIDTH  4096//1920
#define HEIGHT 4096//1080

#define MAX_ITER 8192

#define X_MIN -2.0f
#define X_MAX  1.0f
#define Y_MIN -1.2f
#define Y_MAX  1.2f

__global__ void mandelbrotKernel(unsigned char* output, int width, int height,
    float xMin, float xMax, float yMin, float yMax, int maxIter)
{
    int px = blockIdx.x * blockDim.x + threadIdx.x;
    int py = blockIdx.y * blockDim.y + threadIdx.y;
    if (px >= width || py >= height) return;

    float dx = (xMax - xMin) / (float)width;
    float dy = (yMax - yMin) / (float)height;
    float x0 = xMin + px * dx;
    float y0 = yMin + py * dy;

    float x = 0.0f, y = 0.0f;
    int iter = 0;
    while ((x * x + y * y <= 4.0f) && (iter < maxIter)) {
        float xTemp = x * x - y * y + x0;
        y = 2.0f * x * y + y0;
        x = xTemp;
        iter++;
    }

    unsigned char color = (unsigned char)(255.0f * (float)iter / (float)maxIter);
    int index = py * width + px;
    output[index] = color;
}

int main(int argc, char* argv[])
{
    int gpu = (argc > 1) ? atoi(argv[1]) : 0; // get command
    int iterations = (argc > 1) ? atoi(argv[2]) : 5000;
    printf("Using GPU #: %d for iterations: %d\n", gpu, iterations);
    cudaSetDevice(gpu);
    //singleGPUMandelbrot();

    time_t timeStart, timeEnd;
    double timeElapsed;
    time(&timeStart);

    size_t imageSize = WIDTH * HEIGHT * sizeof(unsigned char);
    unsigned char* h_image = (unsigned char*)malloc(imageSize);
    unsigned char* d_image;
    cudaMalloc((void**)&d_image, imageSize);

    dim3 blockSize(16, 16);
    dim3 gridSize((WIDTH + blockSize.x - 1) / blockSize.x,(HEIGHT + blockSize.y - 1) / blockSize.y);

    for (int run = 0; run < iterations; run++) {
        mandelbrotKernel << <gridSize, blockSize >> > (d_image, WIDTH, HEIGHT, X_MIN, X_MAX, Y_MIN, Y_MAX, MAX_ITER);
        cudaDeviceSynchronize();
        //printf("Completed %d\n", run);
        cudaMemcpy(h_image, d_image, imageSize, cudaMemcpyDeviceToHost);
    }
    cudaFree(d_image);
    free(h_image);
    
    time(&timeEnd);
    timeElapsed = difftime(timeEnd, timeStart);

    printf("duration: %.f\n", timeElapsed);
    printf("time / run : %f\n", timeElapsed / iterations);
    
    return 0;
}
