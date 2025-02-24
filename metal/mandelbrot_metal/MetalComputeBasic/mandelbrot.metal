//
//  mandelbrot.metal
//  MetalComputeBasic
//
//  Created by Michael O'Brien on 2025/2/23.
// Assistance of ChatGPT o1 pro "deep research"
//

#include <metal_stdlib>
using namespace metal;

// Struct for Mandelbrot parameters (must match the struct in MandelbrotGPU.h)
struct MandelbrotParams {
    uint width;
    uint height;
    uint maxIterations;
    float x0;
    float y0;
    float x1;
    float y1;
};

// Mandelbrot compute kernel: calculates one pixel of the fractal.
kernel void mandelbrotKernel(device uchar4 *outPixels [[buffer(0)]],
                             constant MandelbrotParams &params [[buffer(1)]],
                             uint2 tid [[thread_position_in_grid]])
{
    uint x = tid.x;
    uint y = tid.y;
    // Discard threads outside the image bounds (if any)
    if (x >= params.width || y >= params.height) {
        return;
    }

    // Map pixel (x,y) to a point (cr + ci*i) in the complex plane within [x0,x1] x [y0,y1]
    float cr = params.x0 + ((float)x / (float)params.width)  * (params.x1 - params.x0);
    float ci = params.y0 + ((float)y / (float)params.height) * (params.y1 - params.y0);

    // Start iteration at z = 0
    float zr = 0.0f;
    float zi = 0.0f;
    uint iter = 0;
    // Iterate z = z^2 + c until |z|^2 >= 4 (divergence) or maxIterations reached
    while ((zr * zr + zi * zi) < 4.0f && iter < params.maxIterations) {
        // z^2 = (zr + zi*i)^2 = (zr^2 - zi^2) + (2*zr*zi)*i
        float zr_new = zr * zr - zi * zi + cr;
        float zi_new = 2.0f * zr * zi + ci;
        zr = zr_new;
        zi = zi_new;
        iter++;
    }

    // Determine pixel color based on iteration count
    uchar4 color;
    if (iter >= params.maxIterations) {
        // Likely inside the Mandelbrot set (did not diverge)
        color = uchar4(0, 0, 0, 255);  // black (with alpha = 255)
    } else {
        // Diverged after 'iter' iterations – map this to a grayscale value
        uint8_t intensity = uint8_t(255.0f * (float)iter / (float)params.maxIterations);
        color = uchar4(intensity, intensity, intensity, 255);
    }

    // Write the color to the output image buffer at the corresponding pixel index
    outPixels[y * params.width + x] = color;
}
