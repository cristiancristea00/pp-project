#include "FractalGenerator.cuh"

#include <iostream>

#include <opencv2/opencv.hpp>


namespace Fractal
{
    static constexpr auto CHANNELS{3U};

    static constexpr dim3 BLOCK_SIZE{32U, 32U};

    static constexpr float MAX_COLOR{255.0F};

    static Size imageSize{0U, 0U};

    static bool isRendered{false};

    static std::uint8_t * deviceImage{nullptr};
    static std::vector<std::uint8_t> hostImage;


    __host__ __forceinline__ static auto CleanUp() -> void;

    __device__ __forceinline__ static auto PixelToPoint(Pixel pixel, Size size, Point topLeft, Point bottomRight) -> Point;


    __global__ static auto MandelbrotKernel(std::uint8_t * image, Size size, std::size_t iterations, float logIterations, Point topLeft, Point bottomRight, float radiusSquared) -> void;

    __device__ __forceinline__ static auto GenerateMandelbrotPixel(Point startPoint, std::size_t iterations, float logIterations, float radiusSquared) -> std::uint8_t;


    __global__ static auto JuliaKernel(std::uint8_t * image, Size size, std::size_t iterations, float logIterations, Point topLeft, Point bottomRight, float radiusSquared) -> void;

    __device__ __forceinline__ static auto GenerateJuliaPixel(Point startPoint, std::size_t iterations, float logIterations, float radiusSquared) -> std::uint8_t;


    __global__ static auto TricornKernel(std::uint8_t * image, Size size, std::size_t iterations, float logIterations, Point topLeft, Point bottomRight, float radiusSquared) -> void;

    __device__ __forceinline__ static auto GenerateTricornPixel(Point startPoint, std::size_t iterations, float logIterations, float radiusSquared) -> std::uint8_t;


    __global__ static auto CosineKernel(std::uint8_t * image, Size size, std::size_t iterations, float logIterations, Point topLeft, Point bottomRight, float radiusSquared) -> void;

    __device__ __forceinline__ static auto GenerateCosinePixel(Point startPoint, std::size_t iterations, float logIterations, float radiusSquared) -> std::uint8_t;


    __host__ auto GeneratorConstruct(Size const & size) -> void
    {
        if (auto const result{cudaMalloc(&deviceImage, size.width * size.height * CHANNELS * sizeof(std::uint8_t))}; cudaSuccess != result)
        {
            std::cerr << "Error allocating memory for Mandelbrot image: " << cudaGetErrorString(result) << '\n';
            std::exit(EXIT_FAILURE);
        }

        hostImage.resize(size.width * size.height * CHANNELS);

        imageSize = size;
    }

    __host__ auto GeneratorDestruct() -> void
    {
        cudaFree(deviceImage);
        deviceImage = nullptr;

        hostImage.clear();

        isRendered = false;

        imageSize = {0U, 0U};

        cudaDeviceReset();
    }

    __host__ auto Render(Type const type, Point const topLeft, Point const bottomRight, float const radiusSquared, std::size_t const iterations) -> void
    {
        static const dim3 GRID_SIZE{
            static_cast<uint32_t>((imageSize.width + BLOCK_SIZE.x - 1U) / BLOCK_SIZE.x),
            static_cast<uint32_t>((imageSize.height + BLOCK_SIZE.y - 1U) / BLOCK_SIZE.y)
        };

        auto const logMaxIterations{std::log(static_cast<float>(iterations))};

        switch (type)
        {
            case Type::MANDELBROT :
                MandelbrotKernel<<<GRID_SIZE, BLOCK_SIZE>>>(deviceImage, imageSize, iterations, logMaxIterations, topLeft, bottomRight, radiusSquared);
                break;
            case Type::JULIA :
                JuliaKernel<<<GRID_SIZE, BLOCK_SIZE>>>(deviceImage, imageSize, iterations, logMaxIterations, topLeft, bottomRight, radiusSquared);
                break;
            case Type::TRICORN :
                TricornKernel<<<GRID_SIZE, BLOCK_SIZE>>>(deviceImage, imageSize, iterations, logMaxIterations, topLeft, bottomRight, radiusSquared);
                break;
            case Type::COSINE :
                CosineKernel<<<GRID_SIZE, BLOCK_SIZE>>>(deviceImage, imageSize, iterations, logMaxIterations, topLeft, bottomRight, radiusSquared);
                break;
            default :
                std::cerr << "Unknown fractal type.\n";
                CleanUp();
        }

        cudaDeviceSynchronize();

        if (auto const error{cudaGetLastError()}; cudaSuccess != error)
        {
            std::cerr << "Error in the " << TypeToString(type) << " kernel: " << cudaGetErrorString(error) << '\n';
            CleanUp();
        }
    }

    __host__ auto Retrieve() -> void
    {
        cudaMemcpy(hostImage.data(), deviceImage, hostImage.size() * sizeof(std::uint8_t), cudaMemcpyDeviceToHost);

        isRendered = true;
    }

    __host__ auto GetImage() -> std::uint8_t const *
    {
        if (!isRendered)
        {
            throw std::runtime_error("The fractal has not been rendered yet.");
        }

        return hostImage.data();
    }

    __host__ auto Save(std::string_view const & filename) -> void
    {
        using namespace cv;

        if (!isRendered)
        {
            throw std::runtime_error("The fractal has not been rendered yet.");
        }

        Mat const greyImage(static_cast<int>(imageSize.height), static_cast<int>(imageSize.width), CV_8UC1, hostImage.data());
        Mat coloredImage;
        applyColorMap(greyImage, coloredImage, COLORMAP_MAGMA);
        imwrite(filename.data(), coloredImage);
    }

    __host__ __forceinline__ static auto CleanUp() -> void
    {
        GeneratorDestruct();
        std::exit(EXIT_FAILURE);
    }

    auto TypeToString(Type const type) -> std::string_view
    {
        switch (type)
        {
            case MANDELBROT :
                return "Mandelbrot";
            case JULIA :
                return "Julia";
            case TRICORN :
                return "Tricorn";
            case COSINE :
                return "Cosine";
            default :
                throw std::runtime_error("Unknown fractal type.");
        }
    }

    __device__ auto PixelToPoint(Pixel const pixel, Size const size, Point const topLeft, Point const bottomRight) -> Point
    {
        auto const domainWidth{bottomRight.real - topLeft.real};
        auto const domainHeight{topLeft.imag - bottomRight.imag};

        auto const real{topLeft.real + (static_cast<decltype(domainWidth)>(pixel.x) * domainWidth / static_cast<decltype(domainWidth)>(size.width))};
        auto const imag{topLeft.imag - (static_cast<decltype(domainHeight)>(pixel.y) * domainHeight / static_cast<decltype(domainHeight)>(size.height))};

        return {real, imag};
    }

    __global__ static auto MandelbrotKernel(std::uint8_t * const image, Size const size, std::size_t const iterations, float const logIterations, Point const topLeft,
    Point const bottomRight, float const radiusSquared) -> void
    {
        auto const row{(blockIdx.y * blockDim.y) + threadIdx.y};
        auto const col{(blockIdx.x * blockDim.x) + threadIdx.x};

        if (row < size.height && col < size.width)
        {
            auto const point = PixelToPoint({col, row}, size, topLeft, bottomRight);
            auto const value = GenerateMandelbrotPixel(point, iterations, logIterations, radiusSquared);
            image[(row * size.width + col) * CHANNELS + 0] = value;
            image[(row * size.width + col) * CHANNELS + 1] = value;
            image[(row * size.width + col) * CHANNELS + 2] = value;
        }
    }

    __device__ auto GenerateMandelbrotPixel(Point const startPoint, std::size_t const iterations, float const logIterations, float const radiusSquared) -> std::uint8_t
    {
        Point point{0.0, 0.0};

        for (std::size_t iteration = 0; iteration < iterations; ++iteration)
        {
            if (point.norm() > radiusSquared)
            {
                return static_cast<std::uint8_t>(MAX_COLOR * logf(iteration + 1) / logIterations);
            }

            point = point * point + startPoint;
        }

        return 0;
    }

    __global__ static auto JuliaKernel(std::uint8_t * const image, Size const size, std::size_t const iterations, float const logIterations, Point const topLeft,
    Point const bottomRight, float const radiusSquared) -> void
    {
        auto const row{(blockIdx.y * blockDim.y) + threadIdx.y};
        auto const col{(blockIdx.x * blockDim.x) + threadIdx.x};

        if (row < size.height && col < size.width)
        {
            auto const point = PixelToPoint({col, row}, size, topLeft, bottomRight);
            auto const value = GenerateJuliaPixel(point, iterations, logIterations, radiusSquared);
            image[(row * size.width + col) * CHANNELS + 0] = value;
            image[(row * size.width + col) * CHANNELS + 1] = value;
            image[(row * size.width + col) * CHANNELS + 2] = value;
        }
    }

    __device__ auto GenerateJuliaPixel(Point const startPoint, std::size_t const iterations, float const logIterations, float const radiusSquared) -> std::uint8_t
    {
        __device__ static constexpr Point C_POINT{-0.7, 0.27015};

        Point point{startPoint};

        for (std::size_t iteration = 0; iteration < iterations; ++iteration)
        {
            if (point.norm() > radiusSquared)
            {
                return static_cast<std::uint8_t>(MAX_COLOR * logf(iteration + 1) / logIterations);
            }

            point = point * point + C_POINT;
        }

        return 0;
    }

    __global__ static auto TricornKernel(std::uint8_t * const image, Size const size, std::size_t const iterations, float const logIterations, Point const topLeft,
    Point const bottomRight, float const radiusSquared) -> void
    {
        auto const row{(blockIdx.y * blockDim.y) + threadIdx.y};
        auto const col{(blockIdx.x * blockDim.x) + threadIdx.x};

        if (row < size.height && col < size.width)
        {
            auto const point = PixelToPoint({col, row}, size, topLeft, bottomRight);
            auto const value = GenerateTricornPixel(point, iterations, logIterations, radiusSquared);
            image[(row * size.width + col) * CHANNELS + 0] = value;
            image[(row * size.width + col) * CHANNELS + 1] = value;
            image[(row * size.width + col) * CHANNELS + 2] = value;
        }
    }

    __device__ auto GenerateTricornPixel(Point const startPoint, std::size_t const iterations, float const logIterations, float const radiusSquared) -> std::uint8_t
    {
        Point point{0.0, 0.0};

        for (std::size_t iteration = 0; iteration < iterations; ++iteration)
        {
            if (point.norm() > radiusSquared)
            {
                return static_cast<std::uint8_t>(MAX_COLOR * logf(iteration + 1) / logIterations);
            }

            auto const conjugate = point.conj();
            point = conjugate * conjugate + startPoint;
        }

        return 0;
    }

    __global__ static auto CosineKernel(std::uint8_t * const image, Size const size, std::size_t const iterations, float const logIterations, Point const topLeft,
    Point const bottomRight, float const radiusSquared) -> void
    {
        auto const row{(blockIdx.y * blockDim.y) + threadIdx.y};
        auto const col{(blockIdx.x * blockDim.x) + threadIdx.x};

        if (row < size.height && col < size.width)
        {
            auto const point = PixelToPoint({col, row}, size, topLeft, bottomRight);
            auto const value = GenerateCosinePixel(point, iterations, logIterations, radiusSquared);
            image[(row * size.width + col) * CHANNELS + 0] = value;
            image[(row * size.width + col) * CHANNELS + 1] = value;
            image[(row * size.width + col) * CHANNELS + 2] = value;
        }
    }

    __device__ auto GenerateCosinePixel(Point const startPoint, std::size_t const iterations, float const logIterations, float const radiusSquared) -> std::uint8_t
    {
        Point point{0.0, 0.0};

        for (std::size_t iteration = 0; iteration < iterations; ++iteration)
        {
            if (point.norm() > radiusSquared)
            {
                return static_cast<std::uint8_t>(MAX_COLOR * logf(iteration + 1) / logIterations);
            }

            point = point.cos() + startPoint;
        }

        return 0;
    }
} // namespace Fractal
