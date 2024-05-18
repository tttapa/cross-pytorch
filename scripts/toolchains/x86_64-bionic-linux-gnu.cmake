if (NOT DEFINED CROSS_GNU_TRIPLE)
    set(CROSS_GNU_TRIPLE "x86_64-bionic-linux-gnu")
endif()
set(ALPAQA4S_TOOLCHAIN_DIR "${CMAKE_CURRENT_LIST_DIR}/../../toolchains")
include("${ALPAQA4S_TOOLCHAIN_DIR}/x-tools/${CROSS_GNU_TRIPLE}.toolchain.cmake")
unset(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE)

# CUDA
set(CUDA_TOOLKIT_ROOT_DIR "${ALPAQA4S_TOOLCHAIN_DIR}/${CROSS_GNU_TRIPLE}/cuda")
cmake_path(NORMAL_PATH CUDA_TOOLKIT_ROOT_DIR) # Needs to be normalized for CMAKE_FIND_ROOT_PATH
set(CUDA_TOOLKIT_ROOT_DIR "${CUDA_TOOLKIT_ROOT_DIR}" CACHE PATH "" FORCE)
set(ENV{CUDA_TOOLKIT_ROOT} "${CUDA_TOOLKIT_ROOT_DIR}")
set(CMAKE_CUDA_COMPILER "${CUDA_TOOLKIT_ROOT_DIR}/bin/nvcc" CACHE PATH "" FORCE)
set(CMAKE_CUDA_HOST_COMPILER "${CMAKE_CXX_COMPILER}" CACHE FILEPATH "" FORCE)
set(CUDA_TOOLKIT_TARGET_DIR "${CUDA_TOOLKIT_ROOT_DIR}/targets/x86_64-linux")
list(APPEND CMAKE_FIND_ROOT_PATH "${CUDA_TOOLKIT_ROOT_DIR}")
add_link_options("-Wl,-rpath-link,${CUDA_TOOLKIT_ROOT_DIR}/targets/x86_64-linux/lib")

# Not-so-portable CUDA variables
set(CUDA_TOOLKIT_TARGET_DIR "${CUDA_TOOLKIT_TARGET_DIR}" CACHE PATH "" FORCE) # FindCUDA.cmake unsets the cache entry for this variable
set(CUDA_TOOLKIT_TARGET_NAME "x86_64-linux" CACHE STRING "Undocumented hint for CMake's FindCUDA.cmake, necessary when cross-compiling" FORCE)
set(CUDA_TOOLKIT_TARGET_NAMES "x86_64-linux" CACHE STRING "Undocumented hint for pytorch's FindCUDA.cmake, necessary when cross-compiling" FORCE)
