#include "CosineGenerator.hpp"


CosineGenerator::CosineGenerator(Size const & imageSize, Size const & grainSize, std::size_t const maxIterations) : FractalGenerator{imageSize, grainSize, TOP_LEFT, BOTTOM_RIGHT, maxIterations} { }

auto CosineGenerator::Generate(Point const & startPoint) const -> std::uint8_t
{
    Point point{0.0, 0.0};

    for (std::size_t iteration = 0; iteration < maxIterations; ++iteration)
    {
        if (std::abs(point) > RADIUS)
        {
            return static_cast<std::uint8_t>(MAX_COLOR * std::log(iteration + 1) / logMaxIterations);
        }

        point = cosine(point) + startPoint;
    }

    return 0;
}

template <std::floating_point T>
constexpr auto CosineGenerator::cosine(std::complex<T> const & value) -> std::complex<T>
{
    return {std::cos(value.real()) * std::cosh(value.imag()), -std::sin(value.real()) * std::sinh(value.imag())};
}
