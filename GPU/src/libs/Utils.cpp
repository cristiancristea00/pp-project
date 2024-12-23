#include "Utils.hpp"

#include <iostream>


auto CheckParameters(int const argc, char const * const argv[]) -> void
{
    if (argc != ARGS_COUNT)
    {
        std::cerr << "Usage: " << argv[PARAM_NAME] << " <width> <height> <max_iterations>\n";

        std::exit(EXIT_FAILURE);
    }
}
