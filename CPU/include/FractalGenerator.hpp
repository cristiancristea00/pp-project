#pragma once

#include <cstdint>
#include <string_view>
#include <vector>

#include <oneapi/tbb.h>

#include "Utils.hpp"


class FractalGenerator
{
public:
    FractalGenerator(Size const & imageSize, Size const & grainSize, Point const & topLeft, Point const & bottomRight, std::size_t maxIterations);

    virtual ~FractalGenerator() = default;

    auto Render() -> void;

    auto Save(std::string_view const & filename) -> void;

protected:
    virtual auto Generate(Point const & startPoint) const -> std::uint8_t = 0;

    [[gnu::always_inline]] inline auto PixelToPoint(Pixel const & pixel) const -> Point;

    [[gnu::always_inline]] inline static auto Colorize(std::uint8_t & red, std::uint8_t & green, std::uint8_t & blue, std::size_t value) -> void;

    bool isRendered{false};

    Size const imageSize;
    Size const grainSize;

    Point const topLeft;
    Point const bottomRight;

    std::size_t const maxIterations;
    float const logMaxIterations;

    std::vector<std::uint8_t, oneapi::tbb::cache_aligned_allocator<std::uint8_t>> image;

    static constexpr std::size_t CHANNELS{3};
    static constexpr std::size_t MAX_COLOR{255};
};
