cmake_minimum_required(VERSION 3.10)
project(kalan_gemma)

# Note: llama.cpp source code must be present in this directory
# For production, we would use a prebuilt library or a git submodule
add_subdirectory(llama.cpp)

add_library(gemma_jni SHARED gemma_jni.cpp)

target_link_libraries(gemma_jni llama)
