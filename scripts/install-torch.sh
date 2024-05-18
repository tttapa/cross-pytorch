#!/usr/bin/env bash
cd "$( dirname "${BASH_SOURCE[0]}" )"/..

set -ex

# Select architecture
triple="x86_64-bionic-linux-gnu"
arch="${triple%%-*}"

tools_dir="$PWD/toolchains"
pfx="$tools_dir/$triple"
cuda="$pfx/cuda"
src="$pfx/src"
patch_dir="$PWD/scripts/patches"
toolchain="$PWD/scripts/toolchains/$triple.cmake"
mkdir -p "$pfx"

export CMAKE_C_COMPILER_LAUNCHER=ccache
export CMAKE_CXX_COMPILER_LAUNCHER=ccache
export CMAKE_CUDA_COMPILER_LAUNCHER=ccache

# Install Python dependencies
[ -d .venv ] || python3 -m venv .venv
. .venv/bin/activate
pip install -U typing-extensions pyyaml cmake ninja

# Download and build Sleef
[ -d "$src/sleef" ] || {
    git clone https://github.com/shibatch/sleef "$src/sleef" --depth=1 --single-branch --branch=3.6;
}
pushd "$src/sleef"

rm -f build-native/CMakeCache.txt
cmake -B build-native -S . -G "Ninja Multi-Config" \
    -D BUILD_SHARED_LIBS=Off -D SLEEF_BUILD_DFT=Off \
    -D SLEEF_BUILD_GNUABI_LIBS=Off -D SLEEF_BUILD_TESTS=Off \
    -D SLEEF_BUILD_SCALAR_LIB=Off
cmake --build build-native -j

rm -f build/CMakeCache.txt
cmake -B build -S . -G "Ninja Multi-Config" \
    --toolchain "$toolchain" \
    -D BUILD_SHARED_LIBS=Off -D SLEEF_BUILD_DFT=Off \
    -D SLEEF_BUILD_GNUABI_LIBS=Off -D SLEEF_BUILD_TESTS=Off \
    -D SLEEF_BUILD_SCALAR_LIB=Off \
    -D CMAKE_POSITION_INDEPENDENT_CODE=On \
    -D NATIVE_BUILD_DIR="$PWD/build-native"
cmake --build build -j
cmake --install build --prefix "$pfx/sleef"

popd

# Download and build pytorch
[ -d "$src/pytorch" ] || {
    git clone https://github.com/pytorch/pytorch "$src/pytorch" --depth=1 --single-branch --branch=main --recursive;
}
# Apply patches
pushd "$src/pytorch"
for patch in "$patch_dir/pytorch/"*.patch; do
    git apply "$patch" || git apply --reverse --check "$patch"
done
rm -f build/CMakeCache.txt

# We need a native protoc compiler first
cmake -B build_host_protoc_build -S third_party/protobuf/cmake -G "Ninja Multi-Config" \
    -D protobuf_BUILD_TESTS=Off
cmake --build build_host_protoc_build -j --config Release
cmake --install build_host_protoc_build --config Release --prefix="$PWD/build_host_protoc"

# Build pytorch
cmake -B build -S . -G "Ninja Multi-Config" \
    -D BUILD_TESTING=Off -D CMAKE_INSTALL_PREFIX="$pfx/pytorch" \
    --toolchain "$toolchain" \
    -D GLIBCXX_USE_CXX11_ABI=1 \
    -D PYTHON_EXECUTABLE="$(which python3)" \
    -D USE_SYSTEM_SLEEF=On \
    -D CMAKE_FIND_ROOT_PATH="$pfx/sleef;$PWD/third_party" \
    -D PROTOBUF_PROTOC_EXECUTABLE="$PWD/build_host_protoc/bin/protoc" \
    -D CAFFE2_CUSTOM_PROTOC_EXECUTABLE="$PWD/build_host_protoc/bin/protoc" \
    -D protobuf_BUILD_PROTOC_BINARIES=Off \
    -D CMAKE_CUDA_ARCHITECTURES="86" -D TORCH_CUDA_ARCH_LIST="8.6" \
    -D USE_CUDA=On -D USE_CUDNN=On -D USE_XPU=On \
    -D USE_MAGMA=Off -D USE_NUMPY=Off -D USE_NUMA=Off -D USE_ITT=Off \
    -D BUILD_PYTHON=Off -D USE_MPI=Off
cmake --build build --config Release -j
cmake --install build --config Release

popd
