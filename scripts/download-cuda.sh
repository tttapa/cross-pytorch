#!/usr/bin/env bash
cd "$( dirname "${BASH_SOURCE[0]}" )"/..

set -ex

# Download jq if not already available
if ! hash jq; then
    mkdir -p /tmp/jq/bin
    wget https://github.com/jqlang/jq/releases/latest/download/jq-linux-amd64 -O /tmp/jq/bin/jq
    chmod +x /tmp/jq/bin/jq
    export PATH="/tmp/jq/bin:$PATH"
    hash -r
    hash jq
fi

# Select architecture
host_arch="x86_64"
arch="x86_64"
version="12.2.2"
cuda_url="https://developer.download.nvidia.com/compute/cuda/redist"
tools_dir="$PWD/toolchains"

host_packages=(cuda_nvcc)
target_packages=(cuda_cccl cuda_cudart cuda_compat cuda_cupti cuda_nvml_dev cuda_nvrtc cuda_nvtx)
target_packages+=(libcublas libcudla libcufft libcurand libcusolver libcusparse libnvjitlink)

mkdir -p "$tools_dir/cuda"
pushd "$tools_dir/cuda"

wget -N "$cuda_url/redistrib_$version.json"
redist_json="$PWD/redistrib_$version.json"

for pkg in "${host_packages[@]}"; do
    echo "$pkg"
    relpath="$(jq -r ".$pkg.\"linux-$host_arch\".relative_path" "$redist_json")"
    if [ "$relpath" != null ]; then
        wget "$cuda_url/$relpath" -O- | tar xJ --strip-components 1
    fi
done

# Mimic pre-built package so the makefiles and CMake find modules find CUDA
mkdir -p targets/$host_arch-linux
mv include targets/$host_arch-linux
ln -sf targets/$host_arch-linux/lib lib64
ln -sf targets/$host_arch-linux/include include

mkdir -p targets/$arch-linux
pushd targets/$arch-linux

for pkg in "${target_packages[@]}"; do
    echo "$pkg"
    relpath="$(jq -r ".$pkg.\"linux-$arch\".relative_path" "$redist_json")"
    if [ "$relpath" != null ]; then
        wget "$cuda_url/$relpath" -O- | tar xJ --strip-components 1
    fi
done

popd
popd
