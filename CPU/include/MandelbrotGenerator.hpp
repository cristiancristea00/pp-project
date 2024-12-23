#pragma once

#include "FractalGenerator.hpp"


class MandelbrotGenerator final : public FractalGenerator
{
public:
    MandelbrotGenerator(Size const & imageSize, Size const & grainSize, std::size_t maxIterations);

private:
    [[nodiscard]] auto Generate(Point const & startPoint) const -> std::uint8_t override;

    static constexpr Point TOP_LEFT{-2.0, 1.2};
    static constexpr Point BOTTOM_RIGHT{1.0, -1.2};

    static constexpr float RADIUS{2.0};
};
