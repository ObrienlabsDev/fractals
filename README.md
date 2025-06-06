# fractals
Mandelbrot set - via GPU
Warning: Your GPU will run at 100% at up to 90% TDP.  You will need at least a 1600 Watt PSU and 2 separate 15A/1800W breakers on 2 lines.

## Performance

- block size 16 x 16, 5000 iterations of 4096x4096 images with max mandelbrot iteration of 8192

perf | sec | /run | # GPUs | % GPU | Watts | TDP | Chip | Cores | GPU spec
--- | --- | --- | --- | --- | --- | --- | --- | --- | --
11.7 | 23 | .0092 | 2 | 99 | 904 | 94 | AD-102 | 32768 | dual RTX-4090 Ada (no NVLink (not used 48G))
5.85 | 46 | .0092 | 1 | 99 | 452 | 94 | AD-102 | 16384 | RTX-4090 Ada 24G
3.44 | 78 | .0312 | 2 | 99 | 388 | 97 | GA-102 | 14336| dual [RTX-A4500](https://www.nvidia.com/content/dam/en-zz/Solutions/design-visualization/rtx/nvidia-rtx-a4500-datasheet.pdf) with NVLink (not used) 40G
2.66 | 100 | .02 | 1 | 99 | 304 | 102 | GA-102 | 10752 | [RTX-A6000](https://www.nvidia.com/content/dam/en-zz/Solutions/design-visualization/quadro-product-literature/proviz-print-nvidia-rtx-a6000-datasheet-us-nvidia-1454980-r9-web%20(1).pdf) 48G
0 | 180 |  | 2 | 92 |  | ? | M3 Ultra 60 | 7680 | Mac Studio 3 M3Ultra 96G
2.56 | 191 | .0382 | 1 | 99 | 102 | ? | AD-104 | 5120 | RTX-3500 Ada 12G Thermal Throttling
1.72 | 156 | .0312 | 1 | 99 | 194 | 97 | GA-102 | 7168 | RTX-A4500 20G old
1.29 | 208 | .0416 | 1 | 99 | 143 | 102 | GA-104 | 6144 | RTX-A4000 16G old
1.16 | 231 | .0462 | 1 | 98 | 120 | ? | M4 Max 40 | 5120 | Macbook Pro 16 M4Max 48G
1 | 269 | .0538 | 1 | 99 | 105 | ? | TU-104 | 3072 | RTX-5000 16G
0.78 | 344 | .0688 | 2 | 96 | 120 | ? | M2 Ultra 60 | 7680 | Mac Studio 2 M2Ultra 64G
0.47 | 571 | .1142 | 1 | 79-98 |  | ? | M4 Pro 16 | 2048 | Mac Mini M4 Pro 24G
0.39 | 693 | .1386 | 1 | 95 |  | ? | M1 Max 32 | 4096 | Macbook Pro 16 M1Max 32G



### Power Options

9 A - two RTX-A4500 GPUs
![image](https://github.com/user-attachments/assets/e8843564-c8c1-4768-903d-6341b369e835)

![image](https://github.com/user-attachments/assets/7de6901a-a024-4d8f-b623-f8c10393bad4)

10.5 A - two RTX-4090 GPUs generating Mandelbrot set images

<img width="777" alt="Screenshot 2025-01-22 at 14 34 12" src="https://github.com/user-attachments/assets/7d98ebbf-1694-4c4e-8eb8-81a682cd473f" />
