#include "Utils.hpp"

#include <chrono>
#include <print>


auto CheckParameters(int const argc, char const * const argv[]) -> void
{
    if (argc != ARGS_COUNT)
    {
        std::println(stderr, "Usage: {} <width> <height> <max_iterations>", argv[PARAM_NAME]);

        std::exit(EXIT_FAILURE);
    }
}

auto TestSpeed(std::function<void()> const & function, std::string_view const message) -> void
{
    using namespace std::chrono;

    auto const start = high_resolution_clock::now();
    function();
    auto const stop = high_resolution_clock::now();

    auto const differenceMs = duration_cast<milliseconds>(stop - start);
    auto const timeMs = differenceMs.count();

    std::println("Time taken for {} : {} ms", message, timeMs);
}
