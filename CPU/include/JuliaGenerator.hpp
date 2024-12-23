#pragma once

#include "FractalGenerator.hpp"


class JuliaGenerator final : public FractalGenerator
{
public:
    JuliaGenerator(Size const & imageSize, Size const & grainSize, std::size_t maxIterations);

private:
    [[nodiscard]] auto Generate(Point const & startPoint) const -> std::uint8_t override;

    static constexpr Point TOP_LEFT{-1.6, 1.2};
    static constexpr Point BOTTOM_RIGHT{1.6, -1.2};

    static constexpr Point C_POINT{-0.7, 0.27015};

    static constexpr float RADIUS{2.0};
};
