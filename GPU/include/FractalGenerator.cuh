#pragma once

#include "Utils.hpp"

#include <string_view>


namespace Fractal
{
    enum Type : std::uint8_t
    {
        MANDELBROT = 0x00,
        JULIA      = 0x01,
        TRICORN    = 0x02,
        COSINE     = 0x03,
        SIZE       = 0x04,
    };

    __host__ auto TypeToString(Type type) -> std::string_view;

    __host__ auto GeneratorConstruct(Size const & size) -> void;

    __host__ auto GeneratorDestruct() -> void;

    __host__ auto Render(Type type, Point topLeft, Point bottomRight, float radiusSquared, std::size_t iterations) -> void;

    __host__ auto Retrieve() -> void;

    __host__ auto GetImage() -> std::uint8_t const *;

    __host__ auto Save(std::string_view const & filename) -> void;
} // namespace Fractal
