#pragma once

#include "Utils.hpp"

#include <cuda_runtime_api.h>


namespace Mandelbrot
{
    __host__ auto GeneratorConstruct(Size const & size) -> void;

    __host__ auto GeneratorDestruct() -> void;

    __host__ auto Render(std::size_t iterations) -> void;

    __host__ auto Retrieve() -> void;

    __host__ auto GetImage() -> std::uint8_t const *;

    __host__ auto Save() -> void;
} // namespace Mandelbrot
