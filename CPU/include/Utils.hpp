#pragma once

#include <complex>
#include <cstdint>
#include <functional>


#define ARGS_COUNT    ( 4U )


enum Arguments : std::uint8_t
{
    PARAM_NAME           = 0x00,
    PARAM_WIDTH          = 0x01,
    PARAM_HEIGHT         = 0x02,
    PARAM_MAX_ITERATIONS = 0x03,
};

using Point = std::complex<float>;

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


auto CheckParameters(int argc, char const * const argv[]) -> void;

auto GetGrainSize(Size const & imageSize, int numberOfThreads) -> Size;

auto TestSpeed(std::function<void()> const & function, std::string_view message) -> void;
