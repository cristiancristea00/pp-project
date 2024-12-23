#include "FractalGenerator.cuh"

#include <iostream>
#include <numbers>

#include <opencv2/opencv.hpp>


namespace Cosine
{
    static constexpr float RADIUS_SQUARED{(10.0 * std::numbers::pi) * (10.0 * std::numbers::pi)};

    static constexpr Point TOP_LEFT{-2.0, 2.0};
    static constexpr Point BOTTOM_RIGHT{5.0, -2.0};


    __host__ auto GeneratorConstruct(Size const & size) -> void
    {
        Fractal::GeneratorConstruct(size);
    }

    __host__ auto GeneratorDestruct() -> void
    {
        Fractal::GeneratorDestruct();
    }

    __host__ auto Render(std::size_t const iterations) -> void
    {
        Fractal::Render(Fractal::Type::COSINE, TOP_LEFT, BOTTOM_RIGHT, RADIUS_SQUARED, iterations);
    }

    __host__ auto Retrieve() -> void
    {
        Fractal::Retrieve();
    }

    __host__ auto GetImage() -> std::uint8_t const *
    {
        return Fractal::GetImage();
    }

    __host__ auto Save() -> void
    {
        Fractal::Save("Cosine.png");
    }
} // namespace Cosine
