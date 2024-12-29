#include <print>

#include "TricornGenerator.cuh"


auto main(int const argc, char const * const argv[]) -> int
{
    CheckParameters(argc, argv);

    std::size_t const imageWidth{std::stoul(argv[PARAM_WIDTH])};
    std::size_t const imageHeight{std::stoul(argv[PARAM_HEIGHT])};
    Size const imageSize{imageWidth, imageHeight};

    std::size_t const maxIterations{std::stoul(argv[PARAM_MAX_ITERATIONS])};

    std::println("Generating Tricorn fractal image with size {}×{} using {} iterations", imageWidth, imageHeight, maxIterations);

    Tricorn::GeneratorConstruct(imageSize);
    TestSpeed(
        [&maxIterations]() -> void
        {
            Tricorn::Render(maxIterations);
        }, "Tricorn fractal generation"
    );
    TestSpeed(
        []() -> void
        {
            Tricorn::Retrieve();
        }, "Tricorn fractal retrieval"
    );
    Tricorn::Save();
    Tricorn::GeneratorDestruct();

    return EXIT_SUCCESS;
}
