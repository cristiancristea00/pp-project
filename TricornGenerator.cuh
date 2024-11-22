#pragma once

#include "Utils.cuh"


namespace Tricorn
{
    __host__ auto GeneratorConstruct(Size const & size, std::size_t iterations) -> void;

    __host__ auto GeneratorDestruct() -> void;

    __host__ auto Render() -> void;

    __host__ auto Retrieve() -> void;

    __host__ auto Save() -> void;
} // namespace Tricorn
