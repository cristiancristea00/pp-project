#include <print>

#include <oneapi/tbb.h>

#include "TricornGenerator.hpp"
#include "Utils.hpp"


auto main(int const argc, char const * const argv[]) -> int
{
    CheckParameters(argc, argv);

    std::size_t const imageWidth{std::stoul(argv[WIDTH])};
    std::size_t const imageHeight{std::stoul(argv[HEIGHT])};
    Size const imageSize{imageWidth, imageHeight};

    std::size_t const maxIterations{std::stoul(argv[MAX_ITERATIONS])};

    auto const numThreads{oneapi::tbb::info::default_concurrency()};

    auto const grainSize{GetGrainSize(imageSize, numThreads)};

    std::println(
        "Generating Tricorn fractal image with size {}×{} using {} iterations and grainsize {}×{} on {} threads", imageWidth, imageHeight, maxIterations, grainSize.width, grainSize.height, numThreads
    );

    TricornGenerator tricornGenerator{imageSize, grainSize, maxIterations};
    TestSpeed(
        [&tricornGenerator]() -> void
        {
            tricornGenerator.Render();
        }, "Tricorn fractal generation"
    );
    tricornGenerator.Save("Tricorn.png");

    return EXIT_SUCCESS;
}
