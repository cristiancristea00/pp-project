#include <iostream>
#include <string>

#include "TricornGenerator.cuh"
#include "Utils.cuh"


auto main(int const argc, char * argv[]) -> int
{
    CheckParameters(argc, argv);

    std::size_t const imageWidth{std::stoul(argv[PARAM_WIDTH])};
    std::size_t const imageHeight{std::stoul(argv[PARAM_HEIGHT])};
    Size const imageSize{imageWidth, imageHeight};

    std::size_t const maxIterations{std::stoul(argv[PARAM_MAX_ITERATIONS])};

    Tricorn::GeneratorConstruct(imageSize, maxIterations);
    Tricorn::Render();
    Tricorn::Retrieve();
    Tricorn::Save();
    Tricorn::GeneratorDestruct();

    return EXIT_SUCCESS;
}
