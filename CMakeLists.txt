cmake_minimum_required(VERSION 3.19)
project("Fractal Generator" LANGUAGES CUDA CXX C VERSION 1.0.0)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CUDA_STANDARD 20)

set(CMAKE_COLOR_DIAGNOSTICS ON)

if(MSCV_IDE OR MSVC)
    set(DEBUG_FLAGS "/Od /arch:AVX2 /fp:fast /EHsc /Zi")
    set(RELEASE_FLAGS "/Ot /arch:AVX2 /fp:fast /EHsc /Zi")
else()
    set(DEBUG_FLAGS "-O0 -march=native -mtune=native -pipe -fno-builtin -g  -Wall -Wextra -fsanitize=undefined,leak")
    set(RELEASE_FLAGS "-O3 -march=native -mtune=native -pipe -fno-builtin -g")
endif()

set(CMAKE_CUDA_FLAGS_RELEASE ${RELEASE_FLAGS})
set(CMAKE_CUDA_FLAGS_DEBUG ${DEBUG_FLAGS})
set(CMAKE_CXX_FLAGS_RELEASE ${RELEASE_FLAGS})
set(CMAKE_CXX_FLAGS_DEBUG ${DEBUG_FLAGS})
set(CMAKE_C_FLAGS_RELEASE ${RELEASE_FLAGS})
set(CMAKE_C_FLAGS_DEBUG ${DEBUG_FLAGS})

include_directories(include)
include_directories(${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})

find_package(OpenCV REQUIRED)
include_directories(${OpenCV_INCLUDE_DIRS})
link_libraries(${OpenCV_LIBS})

set(SRC src)
set(LIB ${SRC}/libs)

add_library(Utils STATIC ${LIB}/Utils.cpp)
add_library(FractalGenerator STATIC ${LIB}/FractalGenerator.cu)
link_libraries(Utils FractalGenerator)

add_executable(Mandelbrot ${SRC}/Mandelbrot.cpp ${SRC}/MandelbrotGenerator.cu)
add_executable(Julia ${SRC}/Julia.cpp ${SRC}/JuliaGenerator.cu)
add_executable(Cosine ${SRC}/Cosine.cpp ${SRC}/CosineGenerator.cu)
add_executable(Tricorn ${SRC}/Tricorn.cpp ${SRC}/TricornGenerator.cu)

find_package(glfw3 REQUIRED)
link_libraries(glfw)

file(GLOB_RECURSE SRC_FILES ${SRC}/*Generator.cu ${SRC}/*.c)
add_executable(Fractal ${SRC_FILES} ${SRC}/HelperOpenGL.cpp ${SRC}/Fractal.cpp)