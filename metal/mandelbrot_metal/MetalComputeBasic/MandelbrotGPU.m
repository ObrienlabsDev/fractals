//
//  mandelbrotHost.m
//  MetalComputeBasic
//
//  Created by Michael O'Brien on 2025/2/23.
// Assistance of ChatGPT o1 pro "deep research"
//

#import "MandelbrotGPU.h"
#import <Metal/Metal.h>
#import <Foundation/Foundation.h>

BOOL computeMandelbrotImage(id<MTLDevice> device, MandelbrotParams params, uint8_t *outputImage) {
    // Ensure a valid Metal device is available
    if (device == nil) {
        NSLog(@"[MandelbrotGPU] Error: No Metal GPU device available.");
        return NO;
    }

    // Create a command queue to schedule GPU work
    id<MTLCommandQueue> commandQueue = [device newCommandQueue];
    if (commandQueue == nil) {
        NSLog(@"[MandelbrotGPU] Error: Failed to create Metal command queue.");
        return NO;
    }

    // Load the compute function from the default Metal library (compiled from mandelbrot.metal)
    id<MTLLibrary> library = [device newDefaultLibrary];
    if (library == nil) {
        NSLog(@"[MandelbrotGPU] Error: Failed to load Metal library.");
        return NO;
    }
    id<MTLFunction> mandelbrotFunction = [library newFunctionWithName:@"mandelbrotKernel"];
    if (mandelbrotFunction == nil) {
        NSLog(@"[MandelbrotGPU] Error: Compute shader function 'mandelbrotKernel' not found.");
        return NO;
    }

    // Create a compute pipeline state object for the Mandelbrot shader
    NSError *error = nil;
    id<MTLComputePipelineState> pipelineState = [device newComputePipelineStateWithFunction:mandelbrotFunction error:&error];
    if (pipelineState == nil) {
        NSLog(@"[MandelbrotGPU] Error: Failed to create compute pipeline state: %@", error);
        return NO;
    }

    // Calculate the size of the output image in bytes (RGBA8 format = 4 bytes per pixel)
    size_t imageBytes = (size_t)params.width * params.height * 4;
    // Allocate a Metal buffer for the output image data
    id<MTLBuffer> outputBuffer = [device newBufferWithLength:imageBytes options:MTLResourceStorageModeShared];
    if (outputBuffer == nil) {
        NSLog(@"[MandelbrotGPU] Error: Failed to allocate output buffer of size %zu bytes.", imageBytes);
        return NO;
    }

    // Create a command buffer and a compute command encoder
    int iterations = 2000;
    for (int run = 0; run < iterations - 1; run++) {
        
        id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
        id<MTLComputeCommandEncoder> encoder = [commandBuffer computeCommandEncoder];
        if (encoder == nil) {
            NSLog(@"[MandelbrotGPU] Error: Failed to create compute command encoder.");
            return NO;
        }
        
        // Set the compute pipeline state (our Mandelbrot kernel) and resources
        [encoder setComputePipelineState:pipelineState];
        // Bind the output buffer to the shader (argument index 0 corresponds to device uchar4* outPixels)
        [encoder setBuffer:outputBuffer offset:0 atIndex:0];
        // Pass Mandelbrot parameters to the shader as a constant buffer (argument index 1)
        [encoder setBytes:&params length:sizeof(MandelbrotParams) atIndex:1];
        
        // Configure threadgroup size for full GPU utilization (16x16 threads per group)&#8203;:contentReference[oaicite:1]{index=1}
        MTLSize threadsPerGroup = MTLSizeMake(16, 16, 1);
        // Define the total number of threads equal to the image size (width x height)
        MTLSize threadsPerGrid = MTLSizeMake(params.width, params.height, 1);
        // Dispatch the compute kernel with an arbitrarily sized thread grid covering the whole image
        [encoder dispatchThreads:threadsPerGrid threadsPerThreadgroup:threadsPerGroup];
        
        [encoder endEncoding];
        
        // Commit the command buffer to enqueue the GPU work, then wait for completion
        [commandBuffer commit];
        [commandBuffer waitUntilCompleted];
        // Check for any errors during GPU execution
        if (commandBuffer.error != nil) {
            NSLog(@"[MandelbrotGPU] Error: GPU execution failed: %@", commandBuffer.error);
            return NO;
        }
    }
    // Copy the result from the GPU buffer into the outputImage array
    void *gpuDataPtr = [outputBuffer contents];
    if (gpuDataPtr == NULL) {
        NSLog(@"[MandelbrotGPU] Error: Could not access output buffer contents.");
        return NO;
    }
    memcpy(outputImage, gpuDataPtr, imageBytes);

    return YES;  // Computation successful
}
