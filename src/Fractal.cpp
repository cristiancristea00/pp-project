#include <HelperOpenGL.hpp>

#include <FractalGenerator.cuh>

#include <CosineGenerator.cuh>
#include <JuliaGenerator.cuh>
#include <MandelbrotGenerator.cuh>
#include <TricornGenerator.cuh>

#include <print>


static void ErrorCallback(int error, const char * description);

static void KeyCallback(GLFWwindow * window, int key, int scancode, int action, int mods);


static auto currentFractalType = Fractal::Type::MANDELBROT;

static constexpr std::array ITERATIONS{1UZ, 2UZ, 4UZ, 8UZ, 16UZ, 32UZ, 64UZ, 128UZ, 256UZ, 512UZ, 1024UZ, 2048UZ, 4096UZ};
static auto currentIterationIndex = ITERATIONS.size() - 1UZ;


int main()
{
    glfwSetErrorCallback(ErrorCallback);

    if (!glfwInit())
    {
        throw std::runtime_error("Error: Failed to initialize GLFW");
    }

    auto const monitor = glfwGetPrimaryMonitor();
    auto const mode = glfwGetVideoMode(monitor);

    auto const width = mode->width;
    auto const height = mode->height;

    Fractal::GeneratorConstruct({static_cast<std::size_t>(width), static_cast<std::size_t>(height)});

    auto const window = HelperOpenGL::CreateFullscreenWindow(monitor, mode);
    auto const shaderProgram = HelperOpenGL::CreateShaderProgram();
    auto const texture = HelperOpenGL::CreateTexture(width, height);

    std::println("OpenGL Version: {}", reinterpret_cast<char const *>(glGetString(GL_VERSION)));
    std::println("GLFW Version: {}", glfwGetVersionString());
    std::println("GLSL Version: {}", reinterpret_cast<char const *>(glGetString(GL_SHADING_LANGUAGE_VERSION)));
    std::println("Renderer (GPU): {}", reinterpret_cast<char const *>(glGetString(GL_RENDERER)));
    std::println("Vendor: {}", reinterpret_cast<char const *>(glGetString(GL_VENDOR)));
    std::println("Resolution: {}x{}", width, height);

    glfwSetKeyCallback(window, KeyCallback);

    while (!glfwWindowShouldClose(window))
    {
        switch (currentFractalType)
        {
            case Fractal::Type::MANDELBROT :
                Mandelbrot::Render(ITERATIONS[currentIterationIndex]);
                break;
            case Fractal::Type::JULIA :
                Julia::Render(ITERATIONS[currentIterationIndex]);
                break;
            case Fractal::Type::TRICORN :
                Tricorn::Render(ITERATIONS[currentIterationIndex]);
                break;
            case Fractal::Type::COSINE :
                Cosine::Render(ITERATIONS[currentIterationIndex]);
                break;
            default :
                break;
        }

        Fractal::Retrieve();

        HelperOpenGL::UpdateTexture(texture, Fractal::GetImage(), width, height);

        HelperOpenGL::RenderQuad(shaderProgram, texture);
        glfwSwapBuffers(window);
        glfwWaitEvents();
    }

    Fractal::GeneratorDestruct();

    HelperOpenGL::CleanUp(window, shaderProgram, texture);

    return EXIT_SUCCESS;
}

static void ErrorCallback(int error, const char * description)
{
    std::println(stderr, "Error: {}\n{}", error, description);
}

static void KeyCallback(GLFWwindow * const window, int const key, [[maybe_unused]] int const scancode, int const action, [[maybe_unused]] int const mods)
{
    if (action != GLFW_PRESS)
    {
        return;
    }

    switch (key)
    {
        case GLFW_KEY_ESCAPE :
            glfwSetWindowShouldClose(window, GLFW_TRUE);
            break;
        case GLFW_KEY_RIGHT :
            currentFractalType = static_cast<Fractal::Type>((currentFractalType + 1) % Fractal::Type::SIZE);
            break;
        case GLFW_KEY_LEFT :
            currentFractalType = static_cast<Fractal::Type>((currentFractalType + Fractal::Type::SIZE - 1) % Fractal::Type::SIZE);
            break;
        case GLFW_KEY_UP :
            currentIterationIndex = std::min(currentIterationIndex + 1, ITERATIONS.size() - 1);
            break;
        case GLFW_KEY_DOWN :
            currentIterationIndex = std::max(currentIterationIndex - 1, 0UZ);
            break;
        default :
            break;
    }
}
