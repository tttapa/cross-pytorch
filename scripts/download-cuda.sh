#!/usr/bin/env bash
cd "$( dirname "${BASH_SOURCE[0]}" )"/..

tools_dir="$PWD/toolchains"
export PATH="$tools_dir/bin:$PATH"

set -ex

# Download jq if not already available
if ! hash jq; then
    mkdir -p "$tools_dir/bin"
    wget https://github.com/jqlang/jq/releases/latest/download/jq-linux-amd64 -O "$tools_dir/bin/jq"
    chmod +x "$tools_dir/bin/jq"
fi

# Select architecture
triple="x86_64-bionic-linux-gnu"
arch="${triple%%-*}"
host_arch="x86_64"
cuda_version="12.2.2"
cuda_url="https://developer.download.nvidia.com/compute/cuda/redist"
cudnn_version="9.1.1"
cudnn_url="https://developer.download.nvidia.com/compute/cudnn/redist"

# List of packages we need
host_packages=(cuda_nvcc)
target_packages=(cuda_cccl cuda_cudart cuda_compat cuda_cupti cuda_nvml_dev cuda_nvrtc cuda_nvtx)
target_packages+=(libcublas libcudla libcufft libcurand libcusolver libcusparse libnvjitlink)

mkdir -p "$tools_dir/$triple/cuda"
pushd "$tools_dir/$triple/cuda"

cuda_redist_json="$PWD/cuda_redistrib_$cuda_version.json"
wget "$cuda_url/redistrib_$cuda_version.json" -O "$cuda_redist_json"
cudnn_redist_json="$PWD/cudnn_redistrib_$cudnn_version.json"
wget "$cudnn_url/redistrib_$cudnn_version.json" -O "$cudnn_redist_json"

for pkg in "${host_packages[@]}"; do
    echo "$pkg"
    relpath="$(jq -r ".$pkg.\"linux-$host_arch\".relative_path" "$cuda_redist_json")"
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
    relpath="$(jq -r ".$pkg.\"linux-$arch\".relative_path" "$cuda_redist_json")"
    if [ "$relpath" != null ]; then
        wget "$cuda_url/$relpath" -O- | tar xJ --strip-components 1
    fi
done

relpath="$(jq -r ".cudnn.\"linux-$arch\".cuda${cuda_version%%.*}.relative_path" "$cudnn_redist_json")"
wget "$cudnn_url/$relpath" -O- | tar xJ --strip-components 1

popd
popd
