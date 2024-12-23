#include "JuliaGenerator.hpp"


JuliaGenerator::JuliaGenerator(Size const & imageSize, Size const & grainSize, std::size_t const maxIterations) : FractalGenerator{imageSize, grainSize, TOP_LEFT, BOTTOM_RIGHT, maxIterations} { }

auto JuliaGenerator::Generate(Point const & startPoint) const -> std::uint8_t
{
    auto point{startPoint};

    for (std::size_t iteration = 0; iteration < maxIterations; ++iteration)
    {
        if (std::abs(point) > RADIUS)
        {
            return static_cast<std::uint8_t>(MAX_COLOR * std::log(iteration + 1) / logMaxIterations);
        }

        point = point * point + C_POINT;
    }

    return 0;
}
