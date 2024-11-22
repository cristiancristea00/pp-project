#include <iostream>
#include <string>

#include "MandelbrotGenerator.cuh"
#include "Utils.cuh"


auto main(int const argc, char * argv[]) -> int
{
    CheckParameters(argc, argv);

    std::size_t const imageWidth{std::stoul(argv[PARAM_WIDTH])};
    std::size_t const imageHeight{std::stoul(argv[PARAM_HEIGHT])};
    Size const imageSize{imageWidth, imageHeight};

    std::size_t const maxIterations{std::stoul(argv[PARAM_MAX_ITERATIONS])};

    Mandelbrot::GeneratorConstruct(imageSize, maxIterations);
    Mandelbrot::Render();
    Mandelbrot::Retrieve();
    Mandelbrot::Save();
    Mandelbrot::GeneratorDestruct();

    return EXIT_SUCCESS;
}
