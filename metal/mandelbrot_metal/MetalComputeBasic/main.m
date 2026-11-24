/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An app that performs a simple calculation on a GPU.
Assistance of ChatGPT o1 pro "deep research"
*/

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "MetalAdder.h"
#import "MandelbrotGPU.h"
#import <AppKit/AppKit.h>

// This is the C version of the function that the sample
// implements in Metal Shading Language.
void add_arrays(const float* inA,
                const float* inB,
                float* result,
                int length)
{
    for (int index = 0; index < length ; index++)
    {
        result[index] = inA[index] + inB[index];
    }
}

// output in /Users/*/Library/Developer/Xcode/DerivedData/MetalComputeBasic-*/Build/Products/Debug
int main(int argc, const char * argv[]) {
    
    int gpu = (argc > 1) ? atoi(argv[1]) : 0; // get command
    int runs = (argc > 1) ? atoi(argv[2]) : 5000;
    printf("Using GPU #: %d for iterations: %d\n", gpu, runs);
    
    @autoreleasepool {
        // Initialize the default Metal GPU device
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (device == nil) {
            NSLog(@"Metal is not supported on this system.");
            return 1;
        }
        NSLog(@"Using Metal device: %@", [device name]);

        // Define Mandelbrot parameters: image size, max iterations, and complex plane bounds
        MandelbrotParams params;
        params.width  = 4096;
        params.height = 4096;
        params.maxIterations = 8192;
        // Use the standard view of the Mandelbrot set (you can adjust for zoom/position)
        params.x0 = -2.0f;  // real axis min
        params.x1 =  1.0f;  // real axis max
        params.y0 = -1.2f;  // imaginary axis min
        params.y1 =  1.2f;  // imaginary axis max

        // Allocate memory for the output image (4 bytes per pixel for RGBA)
        size_t imageBytes = (size_t)params.width * params.height * 4;
        uint8_t *imageData = (uint8_t *)malloc(imageBytes);
        if (imageData == NULL) {
            NSLog(@"Error: Failed to allocate %zu bytes for image buffer.", imageBytes);
            return 1;
        }

        // Compute the Mandelbrot image using the GPU
        NSLog(@"Computing Mandelbrot set %ux%u with max %u iterations on %u runs...", params.width, params.height, params.maxIterations, runs);
        BOOL ok;
        // check single run first
        ok = computeMandelbrotImage(device, params, imageData, runs);
        if (!ok) {
            NSLog(@"Mandelbrot GPU computation failed.");
            free(imageData);
            return 1;
        }
        
        NSLog(@"GPU computation complete.");

        // save only the last image
        // Wrap the raw pixel buffer in an NSBitmapImageRep for image saving
        // Note: We provide the buffer pointer to NSBitmapImageRep without copying
        unsigned char *planes[1] = { imageData };
        NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:planes
                                                                             pixelsWide:params.width
                                                                             pixelsHigh:params.height
                                                                          bitsPerSample:8
                                                                        samplesPerPixel:4
                                                                               hasAlpha:YES
                                                                               isPlanar:NO
                                                                         colorSpaceName:NSDeviceRGBColorSpace
                                                                            bitmapFormat:NSBitmapFormatAlphaNonpremultiplied
                                                                             bytesPerRow:params.width * 4
                                                                            bitsPerPixel:32];
        if (bitmapRep == nil) {
            NSLog(@"Error: Failed to create NSBitmapImageRep.");
            free(imageData);
            return 1;
        }

        // Convert the bitmap to PNG data
        NSData *pngData = [bitmapRep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
        if (pngData == nil) {
            NSLog(@"Error: Failed to generate PNG data.");
            free(imageData);
            return 1;
        }

        // Write the PNG data to a file (in the current directory)
        NSString *filePath = @"mandelbrot.png";
        if (![pngData writeToFile:filePath atomically:YES]) {
            NSLog(@"Error: Failed to write image to %@", filePath);
        } else {
            NSLog(@"Mandelbrot image saved to %@", filePath);
        }

        // Free the image buffer (since NSBitmapImageRep does not copy the planes data)
        free(imageData);
    }
    return 0;
    
/*    @autoreleasepool {
        
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();

        // Create the custom object used to encapsulate the Metal code.
        // Initializes objects to communicate with the GPU.
        MetalAdder* adder = [[MetalAdder alloc] initWithDevice:device];
        
        // Create buffers to hold data
        [adder prepareData];
        
        // Send a command to the GPU to perform the calculation.
        [adder sendComputeCommandGPU];
        //[adder sendComputeCommandCPU];
        
        NSLog(@"Execution finished");
    }
    return 0;*/
}
