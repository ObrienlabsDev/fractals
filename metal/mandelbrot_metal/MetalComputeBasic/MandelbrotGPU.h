//
//  mandelbrotGPU.h
//  MetalComputeBasic
//
//  Created by Michael O'Brien on 2025/2/23.
// Assistance of ChatGPT o1 pro "deep research"
//

#import <Metal/Metal.h>
#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

/// Parameters for generating the Mandelbrot set image
typedef struct {
    uint32_t width;        // Image width in pixels
    uint32_t height;       // Image height in pixels
    uint32_t maxIterations;// Maximum iterations for divergence check
    float    x0;           // Minimum real coordinate (left boundary)
    float    y0;           // Minimum imaginary coordinate (bottom boundary)
    float    x1;           // Maximum real coordinate (right boundary)
    float    y1;           // Maximum imaginary coordinate (top boundary)
} MandelbrotParams;

/**
 * Computes a Mandelbrot fractal image using Metal GPU parallelism.
 *
 * This function dispatches a Metal compute shader (`mandelbrot.metal`) to calculate
 * the Mandelbrot set for the given parameters. The resulting image pixels (RGBA8)
 * are written into the provided output buffer.
 *
 * @param device      The MTLDevice (GPU) to use for computation.
 * @param params      Mandelbrot parameters (resolution, iteration count, coordinate bounds).
 * @param outputImage Pointer to a pre-allocated buffer (size = width * height * 4 bytes)
 *                    where the resulting image (RGBA pixels) will be stored.
 * @return            YES if the computation succeeded, NO if an error occurred.
 */
BOOL computeMandelbrotImage(id<MTLDevice> device, MandelbrotParams params, uint8_t *outputImage, int runs);

#ifdef __cplusplus
}
#endif
