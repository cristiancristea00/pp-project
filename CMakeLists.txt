cmake_minimum_required(VERSION 3.19)
project("Fractal Generator" LANGUAGES CUDA)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CUDA_STANDARD 20)

set(CMAKE_COLOR_DIAGNOSTICS ON)

if(MSCV_IDE OR MSVC)
    set(DEBUG_FLAGS "/Od /arch:AVX2 /fp:fast /EHsc /Zi")
    set(RELEASE_FLAGS "/Ot /arch:AVX2 /fp:fast /EHsc /Zi")

    set(CMAKE_CXX_FLAGS_RELEASE ${RELEASE_FLAGS})
    set(CMAKE_CXX_FLAGS_DEBUG ${DEBUG_FLAGS})
else()
    set(DEBUG_FLAGS "-O0 -march=native -mtune=native -pipe -fno-builtin -g")
    set(RELEASE_FLAGS "-O3 -march=native -mtune=native -pipe -fno-builtin -g")

    set(CMAKE_CUDA_FLAGS_RELEASE ${RELEASE_FLAGS})
    set(CMAKE_CUDA_FLAGS_DEBUG ${DEBUG_FLAGS})
endif()

include_directories(${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})

find_package(OpenCV REQUIRED)
include_directories(${OpenCV_INCLUDE_DIRS})
link_libraries(${OpenCV_LIBS})

add_library(Utils STATIC Utils.cu)
add_library(FractalGenerator STATIC FractalGenerator.cu)
link_libraries(Utils FractalGenerator)

add_executable(Mandelbrot Mandelbrot.cu MandelbrotGenerator.cu)
add_executable(Julia Julia.cu JuliaGenerator.cu)
add_executable(Cosine Cosine.cu CosineGenerator.cu)
add_executable(Tricorn Tricorn.cu TricornGenerator.cu)
