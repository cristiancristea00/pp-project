#include "FractalGenerator.cuh"

#include <iostream>

#include <opencv2/opencv.hpp>


namespace Tricorn
{
    static constexpr float RADIUS_SQUARED{4.0F};

    static constexpr Point TOP_LEFT{-2.0, 1.6};
    static constexpr Point BOTTOM_RIGHT{2.0, -1.6};


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
        Fractal::Render(Fractal::Type::TRICORN, TOP_LEFT, BOTTOM_RIGHT, RADIUS_SQUARED, iterations);
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
        Fractal::Save("Tricorn.png");
    }
} // namespace Tricorn
