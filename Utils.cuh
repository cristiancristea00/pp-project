#pragma once

#include <cuda_runtime_api.h>

#include <cstdint>
#include <functional>

#include "Complex.cuh"


#define ARGS_COUNT    ( 4U )


enum Arguments : std::uint8_t
{
    PARAM_NAME           = 0x00,
    PARAM_WIDTH          = 0x01,
    PARAM_HEIGHT         = 0x02,
    PARAM_MAX_ITERATIONS = 0x03,
};

using Point = Complex<float>;

struct Pixel
{
    std::size_t x;
    std::size_t y;
};

struct Size
{
    std::size_t width;
    std::size_t height;
};

__host__ auto CheckParameters(int argc, char * argv[]) -> void;
