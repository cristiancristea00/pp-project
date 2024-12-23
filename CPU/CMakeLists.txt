cmake_minimum_required(VERSION 3.19)
project("CPU Fractal Generator" DESCRIPTION "Fractal Generator on CPUs using TBB" LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)

set(CMAKE_COLOR_DIAGNOSTICS ON)

if(MSCV_IDE OR MSVC)
    set(RELEASE_FLAGS "/Ot /arch:AVX2 /fp:fast /EHsc /Zi")
    set(DEBUG_FLAGS "/Od /arch:AVX2 /fp:fast /EHsc /Zi")
else()
    set(RELEASE_FLAGS "-O3 -ffast-math -march=native -mtune=native -pipe -fno-builtin -g")
    set(DEBUG_FLAGS "-O0 -march=native -mtune=native -pipe -fno-builtin -g -Wall -Wextra -fno-omit-frame-pointer -fsanitize=undefined,leak")
endif()

set(CMAKE_CXX_FLAGS_RELEASE ${RELEASE_FLAGS})
set(CMAKE_CXX_FLAGS_DEBUG ${DEBUG_FLAGS})

include_directories(include)

find_package(OpenCV REQUIRED)
include_directories(${OpenCV_INCLUDE_DIRS})
link_libraries(${OpenCV_LIBS})

find_package(TBB REQUIRED)
link_libraries(TBB::tbb)

set(SRC src)
set(LIB ${SRC}/libs)

add_library(Utils STATIC ${LIB}/Utils.cpp)
add_library(FractalGenerator STATIC ${LIB}/FractalGenerator.cpp)
link_libraries(Utils FractalGenerator)

add_executable(Mandelbrot ${SRC}/Mandelbrot.cpp ${SRC}/MandelbrotGenerator.cpp)
add_executable(Julia ${SRC}/Julia.cpp ${SRC}/JuliaGenerator.cpp)
add_executable(Cosine ${SRC}/Cosine.cpp ${SRC}/CosineGenerator.cpp)
add_executable(Tricorn ${SRC}/Tricorn.cpp ${SRC}/TricornGenerator.cpp)
