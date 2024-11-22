#include <iostream>
#include <string>

#include "CosineGenerator.cuh"
#include "Utils.cuh"


auto main(int const argc, char * argv[]) -> int
{
    CheckParameters(argc, argv);

    std::size_t const imageWidth{std::stoul(argv[PARAM_WIDTH])};
    std::size_t const imageHeight{std::stoul(argv[PARAM_HEIGHT])};
    Size const imageSize{imageWidth, imageHeight};

    std::size_t const maxIterations{std::stoul(argv[PARAM_MAX_ITERATIONS])};

    Cosine::GeneratorConstruct(imageSize, maxIterations);
    Cosine::Render();
    Cosine::Retrieve();
    Cosine::Save();
    Cosine::GeneratorDestruct();

    return EXIT_SUCCESS;
}