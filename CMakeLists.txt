cmake_minimum_required(VERSION 3.20)
project(pytorch-test)

find_package(Torch REQUIRED)

add_executable(example-torch "example-torch.cpp")
target_link_libraries(example-torch PRIVATE "${TORCH_LIBRARIES}")
target_compile_options(example-torch PRIVATE "${TORCH_CXX_FLAGS}")
target_precompile_headers(example-torch PRIVATE <torch/torch.h>)
