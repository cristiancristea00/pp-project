#include <string>

#include "JuliaGenerator.cuh"


auto main(int const argc, char const * const argv[]) -> int
{
    CheckParameters(argc, argv);

    std::size_t const imageWidth{std::stoul(argv[PARAM_WIDTH])};
    std::size_t const imageHeight{std::stoul(argv[PARAM_HEIGHT])};
    Size const imageSize{imageWidth, imageHeight};

    std::size_t const maxIterations{std::stoul(argv[PARAM_MAX_ITERATIONS])};

    Julia::GeneratorConstruct(imageSize);
    Julia::Render(maxIterations);
    Julia::Retrieve();
    Julia::Save();
    Julia::GeneratorDestruct();

    return EXIT_SUCCESS;
}
