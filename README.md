# cross-pytorch

Scripts for cross-compiling PyTorch with CUDA support on Linux.

## Why?

Recent PyTorch binaries no longer support glibc 2.28 and earlier, and can no
longer be compiled using older compilers.

## How?

This repository has scripts that 
1. Download a suitable cross-compiler to make sure that the resulting binaries are compatible with Ubuntu 18.04 Bionic, Debian 10 Buster, Rocky 8 and later.
2. Download a suitable version of CUDA.
3. Cross-compile PyTorch and (some of) its dependencies with the rigth compiler and CUDA version.

## Instructions

- In `scripts/download-cuda.sh`, select the appropriate `cuda_version` and `cudnn_version`.
- In `scripts/install-torch.sh`, select the appropriate `CMAKE_CUDA_ARCHITECTURES` and `TORCH_CUDA_ARCH_LIST` options (see https://developer.nvidia.com/cuda-gpus).
- In `scripts/install-torch.sh`, select the version of PyTorch you need (`main` by default).
- You'll need Python 3 and some standard tools like `wget` and `git`. Ccache is recommended and enabled by default, but can be commented out in `scripts/install-torch.sh`
- Finally, run the following commands:
```sh
./install-toolchain.sh # ~120 MiB download
./download-cuda.sh # ~2 GiB download
./install-torch.sh # May take a couple of hours, dependening on your machine's performance
```
