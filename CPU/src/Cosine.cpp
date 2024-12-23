#include <print>

#include <oneapi/tbb.h>

#include "CosineGenerator.hpp"
#include "Utils.hpp"


auto main(int const argc, char const * const argv[]) -> int
{
    CheckParameters(argc, argv);

    std::size_t const imageWidth{std::stoul(argv[PARAM_WIDTH])};
    std::size_t const imageHeight{std::stoul(argv[PARAM_HEIGHT])};
    Size const imageSize{imageWidth, imageHeight};

    std::size_t const maxIterations{std::stoul(argv[PARAM_MAX_ITERATIONS])};

    auto const numThreads{oneapi::tbb::info::default_concurrency()};

    auto const grainSize{GetGrainSize(imageSize, numThreads)};

    std::println(
        "Generating Cosine fractal image with size {}×{} using {} iterations and grainsize {}×{} on {} threads", imageWidth, imageHeight, maxIterations, grainSize.width, grainSize.height, numThreads
    );

    CosineGenerator cosineGenerator{imageSize, grainSize, maxIterations};
    TestSpeed(
        [&cosineGenerator]() -> void
        {
            cosineGenerator.Render();
        }, "Cosine fractal generation"
    );
    cosineGenerator.Save("Cosine.png");

    return EXIT_SUCCESS;
}
