#include <print>

#include "CosineGenerator.cuh"


auto main(int const argc, char const * const argv[]) -> int
{
    CheckParameters(argc, argv);

    std::size_t const imageWidth{std::stoul(argv[PARAM_WIDTH])};
    std::size_t const imageHeight{std::stoul(argv[PARAM_HEIGHT])};
    Size const imageSize{imageWidth, imageHeight};

    std::size_t const maxIterations{std::stoul(argv[PARAM_MAX_ITERATIONS])};

    std::println("Generating Cosine fractal image with size {}×{} using {} iterations", imageWidth, imageHeight, maxIterations);

    Cosine::GeneratorConstruct(imageSize);
    TestSpeed(
        [&maxIterations]() -> void
        {
            Cosine::Render(maxIterations);
        }, "Cosine fractal generation"
    );
    TestSpeed(
        []() -> void
        {
            Cosine::Retrieve();
        }, "Cosine fractal retrieval"
    );
    Cosine::Save();
    Cosine::GeneratorDestruct();

    return EXIT_SUCCESS;
}
