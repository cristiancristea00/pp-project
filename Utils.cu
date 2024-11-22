#include "Utils.cuh"

#include <iostream>


__host__ auto CheckParameters(int const argc, char * argv[]) -> void
{
    if (argc != ARGS_COUNT)
    {
        std::cerr << "Usage: " << argv[PARAM_NAME] << " <width> <height> <max_iterations>\n";

        std::exit(EXIT_FAILURE);
    }
}
