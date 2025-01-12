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

    __device__ __forceinline__ static auto Colorize(std::uint8_t * __restrict__ red, std::uint8_t * __restrict__ green, std::uint8_t * __restrict__ blue, std::uint8_t value) -> void;


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
            case MANDELBROT :
                MandelbrotKernel<<<GRID_SIZE, BLOCK_SIZE>>>(deviceImage, imageSize, iterations, logMaxIterations, topLeft, bottomRight, radiusSquared);
                break;
            case JULIA :
                JuliaKernel<<<GRID_SIZE, BLOCK_SIZE>>>(deviceImage, imageSize, iterations, logMaxIterations, topLeft, bottomRight, radiusSquared);
                break;
            case TRICORN :
                TricornKernel<<<GRID_SIZE, BLOCK_SIZE>>>(deviceImage, imageSize, iterations, logMaxIterations, topLeft, bottomRight, radiusSquared);
                break;
            case COSINE :
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

        Mat const imageRGB{static_cast<int>(imageSize.height), static_cast<int>(imageSize.width), CV_8UC3, hostImage.data()};
        Mat const imageBGR{imageRGB.size(), CV_8UC3};
        cvtColor(imageRGB, imageBGR, COLOR_RGB2BGR);
        imwrite(filename.data(), imageBGR);
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

    __device__ __forceinline__ static auto Colorize(std::uint8_t * __restrict__ const red, std::uint8_t * __restrict__ const green, std::uint8_t * __restrict__ const blue, std::uint8_t const value) -> void
    {
        __device__ __constant__ static constexpr float RED[] = {
            0.001462F, 0.002258F, 0.003279F, 0.004512F, 0.005950F, 0.007588F, 0.009426F, 0.011465F, 0.013708F, 0.016156F, 0.018815F, 0.021692F, 0.024792F, 0.028123F, 0.031696F, 0.035520F,
            0.039608F, 0.043830F, 0.048062F, 0.052320F, 0.056615F, 0.060949F, 0.065330F, 0.069764F, 0.074257F, 0.078815F, 0.083446F, 0.088155F, 0.092949F, 0.097833F, 0.102815F, 0.107899F,
            0.113094F, 0.118405F, 0.123833F, 0.129380F, 0.135053F, 0.140858F, 0.146785F, 0.152839F, 0.159018F, 0.165308F, 0.171713F, 0.178212F, 0.184801F, 0.191460F, 0.198177F, 0.204935F,
            0.211718F, 0.218512F, 0.225302F, 0.232077F, 0.238826F, 0.245543F, 0.252220F, 0.258857F, 0.265447F, 0.271994F, 0.278493F, 0.284951F, 0.291366F, 0.297740F, 0.304081F, 0.310382F,
            0.316654F, 0.322899F, 0.329114F, 0.335308F, 0.341482F, 0.347636F, 0.353773F, 0.359898F, 0.366012F, 0.372116F, 0.378211F, 0.384299F, 0.390384F, 0.396467F, 0.402548F, 0.408629F,
            0.414709F, 0.420791F, 0.426877F, 0.432967F, 0.439062F, 0.445163F, 0.451271F, 0.457386F, 0.463508F, 0.469640F, 0.475780F, 0.481929F, 0.488088F, 0.494258F, 0.500438F, 0.506629F,
            0.512831F, 0.519045F, 0.525270F, 0.531507F, 0.537755F, 0.544015F, 0.550287F, 0.556571F, 0.562866F, 0.569172F, 0.575490F, 0.581819F, 0.588158F, 0.594508F, 0.600868F, 0.607238F,
            0.613617F, 0.620005F, 0.626401F, 0.632805F, 0.639216F, 0.645633F, 0.652056F, 0.658483F, 0.664915F, 0.671349F, 0.677786F, 0.684224F, 0.690661F, 0.697098F, 0.703532F, 0.709962F,
            0.716387F, 0.722805F, 0.729216F, 0.735616F, 0.742004F, 0.748378F, 0.754737F, 0.761077F, 0.767398F, 0.773695F, 0.779968F, 0.786212F, 0.792427F, 0.798608F, 0.804752F, 0.810855F,
            0.816914F, 0.822926F, 0.828886F, 0.834791F, 0.840636F, 0.846416F, 0.852126F, 0.857763F, 0.863320F, 0.868793F, 0.874176F, 0.879464F, 0.884651F, 0.889731F, 0.894700F, 0.899552F,
            0.904281F, 0.908884F, 0.913354F, 0.917689F, 0.921884F, 0.925937F, 0.929845F, 0.933606F, 0.937221F, 0.940687F, 0.944006F, 0.947180F, 0.950210F, 0.953099F, 0.955849F, 0.958464F,
            0.960949F, 0.963310F, 0.965549F, 0.967671F, 0.969680F, 0.971582F, 0.973381F, 0.975082F, 0.976690F, 0.978210F, 0.979645F, 0.981000F, 0.982279F, 0.983485F, 0.984622F, 0.985693F,
            0.986700F, 0.987646F, 0.988533F, 0.989363F, 0.990138F, 0.990871F, 0.991558F, 0.992196F, 0.992785F, 0.993326F, 0.993834F, 0.994309F, 0.994738F, 0.995122F, 0.995480F, 0.995810F,
            0.996096F, 0.996341F, 0.996580F, 0.996775F, 0.996925F, 0.997077F, 0.997186F, 0.997254F, 0.997325F, 0.997351F, 0.997351F, 0.997341F, 0.997285F, 0.997228F, 0.997138F, 0.997019F,
            0.996898F, 0.996727F, 0.996571F, 0.996369F, 0.996162F, 0.995932F, 0.995680F, 0.995424F, 0.995131F, 0.994851F, 0.994524F, 0.994222F, 0.993866F, 0.993545F, 0.993170F, 0.992831F,
            0.992440F, 0.992089F, 0.991688F, 0.991332F, 0.990930F, 0.990570F, 0.990175F, 0.989815F, 0.989434F, 0.989077F, 0.988717F, 0.988367F, 0.988033F, 0.987691F, 0.987387F, 0.987053F,
        };

        __device__ __constant__ static constexpr float GREEN[] = {
            0.000466F, 0.001295F, 0.002305F, 0.003490F, 0.004843F, 0.006356F, 0.008022F, 0.009828F, 0.011771F, 0.013840F, 0.016026F, 0.018320F, 0.020715F, 0.023201F, 0.025765F, 0.028397F,
            0.031090F, 0.033830F, 0.036607F, 0.039407F, 0.042160F, 0.044794F, 0.047318F, 0.049726F, 0.052017F, 0.054184F, 0.056225F, 0.058133F, 0.059904F, 0.061531F, 0.063010F, 0.064335F,
            0.065492F, 0.066479F, 0.067295F, 0.067935F, 0.068391F, 0.068654F, 0.068738F, 0.068637F, 0.068354F, 0.067911F, 0.067305F, 0.066576F, 0.065732F, 0.064818F, 0.063862F, 0.062907F,
            0.061992F, 0.061158F, 0.060445F, 0.059889F, 0.059517F, 0.059352F, 0.059415F, 0.059706F, 0.060237F, 0.060994F, 0.061978F, 0.063168F, 0.064553F, 0.066117F, 0.067835F, 0.069702F,
            0.071690F, 0.073782F, 0.075972F, 0.078236F, 0.080564F, 0.082946F, 0.085373F, 0.087831F, 0.090314F, 0.092816F, 0.095332F, 0.097855F, 0.100379F, 0.102902F, 0.105420F, 0.107930F,
            0.110431F, 0.112920F, 0.115395F, 0.117855F, 0.120298F, 0.122724F, 0.125132F, 0.127522F, 0.129893F, 0.132245F, 0.134577F, 0.136891F, 0.139186F, 0.141462F, 0.143719F, 0.145958F,
            0.148179F, 0.150383F, 0.152569F, 0.154739F, 0.156894F, 0.159033F, 0.161158F, 0.163269F, 0.165368F, 0.167454F, 0.169530F, 0.171596F, 0.173652F, 0.175701F, 0.177743F, 0.179779F,
            0.181811F, 0.183840F, 0.185867F, 0.187893F, 0.189921F, 0.191952F, 0.193986F, 0.196027F, 0.198075F, 0.200133F, 0.202203F, 0.204286F, 0.206384F, 0.208501F, 0.210638F, 0.212797F,
            0.214982F, 0.217194F, 0.219437F, 0.221713F, 0.224025F, 0.226377F, 0.228772F, 0.231214F, 0.233705F, 0.236249F, 0.238851F, 0.241514F, 0.244242F, 0.247040F, 0.249911F, 0.252861F,
            0.255895F, 0.259016F, 0.262229F, 0.265540F, 0.268953F, 0.272473F, 0.276106F, 0.279857F, 0.283729F, 0.287728F, 0.291859F, 0.296125F, 0.300530F, 0.305079F, 0.309773F, 0.314616F,
            0.319610F, 0.324755F, 0.330052F, 0.335500F, 0.341098F, 0.346844F, 0.352734F, 0.358764F, 0.364929F, 0.371224F, 0.377643F, 0.384178F, 0.390820F, 0.397563F, 0.404400F, 0.411324F,
            0.418323F, 0.425390F, 0.432519F, 0.439703F, 0.446936F, 0.454210F, 0.461520F, 0.468861F, 0.476226F, 0.483612F, 0.491014F, 0.498428F, 0.505851F, 0.513280F, 0.520713F, 0.528148F,
            0.535582F, 0.543015F, 0.550446F, 0.557873F, 0.565296F, 0.572706F, 0.580107F, 0.587502F, 0.594891F, 0.602275F, 0.609644F, 0.616999F, 0.624350F, 0.631696F, 0.639027F, 0.646344F,
            0.653659F, 0.660969F, 0.668256F, 0.675541F, 0.682828F, 0.690088F, 0.697349F, 0.704611F, 0.711848F, 0.719089F, 0.726324F, 0.733545F, 0.740772F, 0.747981F, 0.755190F, 0.762398F,
            0.769591F, 0.776795F, 0.783977F, 0.791167F, 0.798348F, 0.805527F, 0.812706F, 0.819875F, 0.827052F, 0.834213F, 0.841387F, 0.848540F, 0.855711F, 0.862859F, 0.870024F, 0.877168F,
            0.884330F, 0.891470F, 0.898627F, 0.905763F, 0.912915F, 0.920049F, 0.927196F, 0.934329F, 0.941470F, 0.948604F, 0.955742F, 0.962878F, 0.970012F, 0.977154F, 0.984288F, 0.991438F,
        };

        __device__ __constant__ static constexpr float BLUE[] = {
            0.013866F, 0.018331F, 0.023708F, 0.029965F, 0.037130F, 0.044973F, 0.052844F, 0.060750F, 0.068667F, 0.076603F, 0.084584F, 0.092610F, 0.100676F, 0.108787F, 0.116965F, 0.125209F,
            0.133515F, 0.141886F, 0.150327F, 0.158841F, 0.167446F, 0.176129F, 0.184892F, 0.193735F, 0.202660F, 0.211667F, 0.220755F, 0.229922F, 0.239164F, 0.248477F, 0.257854F, 0.267289F,
            0.276784F, 0.286321F, 0.295879F, 0.305443F, 0.315000F, 0.324538F, 0.334011F, 0.343404F, 0.352688F, 0.361816F, 0.370771F, 0.379497F, 0.387973F, 0.396152F, 0.404009F, 0.411514F,
            0.418647F, 0.425392F, 0.431742F, 0.437695F, 0.443256F, 0.448436F, 0.453248F, 0.457710F, 0.461840F, 0.465660F, 0.469190F, 0.472451F, 0.475462F, 0.478243F, 0.480812F, 0.483186F,
            0.485380F, 0.487408F, 0.489287F, 0.491024F, 0.492631F, 0.494121F, 0.495501F, 0.496778F, 0.497960F, 0.499053F, 0.500067F, 0.501002F, 0.501864F, 0.502658F, 0.503386F, 0.504052F,
            0.504662F, 0.505215F, 0.505714F, 0.506160F, 0.506555F, 0.506901F, 0.507198F, 0.507448F, 0.507652F, 0.507809F, 0.507921F, 0.507989F, 0.508011F, 0.507988F, 0.507920F, 0.507806F,
            0.507648F, 0.507443F, 0.507192F, 0.506895F, 0.506551F, 0.506159F, 0.505719F, 0.505230F, 0.504692F, 0.504105F, 0.503466F, 0.502777F, 0.502035F, 0.501241F, 0.500394F, 0.499492F,
            0.498536F, 0.497524F, 0.496456F, 0.495332F, 0.494150F, 0.492910F, 0.491611F, 0.490253F, 0.488836F, 0.487358F, 0.485819F, 0.484219F, 0.482558F, 0.480835F, 0.479049F, 0.477201F,
            0.475290F, 0.473316F, 0.471279F, 0.469180F, 0.467018F, 0.464794F, 0.462509F, 0.460162F, 0.457755F, 0.455289F, 0.452765F, 0.450184F, 0.447543F, 0.444848F, 0.442102F, 0.439305F,
            0.436461F, 0.433573F, 0.430644F, 0.427671F, 0.424666F, 0.421631F, 0.418573F, 0.415496F, 0.412403F, 0.409303F, 0.406205F, 0.403118F, 0.400047F, 0.397002F, 0.393995F, 0.391037F,
            0.388137F, 0.385308F, 0.382563F, 0.379915F, 0.377376F, 0.374959F, 0.372677F, 0.370541F, 0.368567F, 0.366762F, 0.365136F, 0.363701F, 0.362468F, 0.361438F, 0.360619F, 0.360014F,
            0.359630F, 0.359469F, 0.359529F, 0.359810F, 0.360311F, 0.361030F, 0.361965F, 0.363111F, 0.364466F, 0.366025F, 0.367783F, 0.369734F, 0.371874F, 0.374198F, 0.376698F, 0.379371F,
            0.382210F, 0.385210F, 0.388365F, 0.391671F, 0.395122F, 0.398714F, 0.402441F, 0.406299F, 0.410283F, 0.414390F, 0.418613F, 0.422950F, 0.427397F, 0.431951F, 0.436607F, 0.441361F,
            0.446213F, 0.451160F, 0.456192F, 0.461314F, 0.466526F, 0.471811F, 0.477182F, 0.482635F, 0.488154F, 0.493755F, 0.499428F, 0.505167F, 0.510983F, 0.516859F, 0.522806F, 0.528821F,
            0.534892F, 0.541039F, 0.547233F, 0.553499F, 0.559820F, 0.566202F, 0.572645F, 0.579140F, 0.585701F, 0.592307F, 0.598983F, 0.605696F, 0.612482F, 0.619299F, 0.626189F, 0.633109F,
            0.640099F, 0.647116F, 0.654202F, 0.661309F, 0.668481F, 0.675675F, 0.682926F, 0.690198F, 0.697519F, 0.704863F, 0.712242F, 0.719649F, 0.727077F, 0.734536F, 0.742002F, 0.749504F,
        };

        *red = static_cast<std::uint8_t>(MAX_COLOR * RED[value]);
        *green = static_cast<std::uint8_t>(MAX_COLOR * GREEN[value]);
        *blue = static_cast<std::uint8_t>(MAX_COLOR * BLUE[value]);
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
            Colorize(&image[(row * size.width + col) * CHANNELS + 0], &image[(row * size.width + col) * CHANNELS + 1], &image[(row * size.width + col) * CHANNELS + 2], value);
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
            Colorize(&image[(row * size.width + col) * CHANNELS + 0], &image[(row * size.width + col) * CHANNELS + 1], &image[(row * size.width + col) * CHANNELS + 2], value);
        }
    }

    __device__ auto GenerateJuliaPixel(Point const startPoint, std::size_t const iterations, float const logIterations, float const radiusSquared) -> std::uint8_t
    {
        __device__ __constant__ static constexpr Point C_POINT{-0.7, 0.27015};

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
            Colorize(&image[(row * size.width + col) * CHANNELS + 0], &image[(row * size.width + col) * CHANNELS + 1], &image[(row * size.width + col) * CHANNELS + 2], value);
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
            Colorize(&image[(row * size.width + col) * CHANNELS + 0], &image[(row * size.width + col) * CHANNELS + 1], &image[(row * size.width + col) * CHANNELS + 2], value);
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
