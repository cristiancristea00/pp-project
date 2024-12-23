#include "HelperOpenGL.hpp"

#include <array>
#include <format>


namespace HelperOpenGL
{
    static constexpr std::string_view VERTEX_SHADER_SOURCE = R"(
        #version 460 core

        // Input vertex attributes
        layout (location = 0) in vec2 aPos;       // Vertex position
        layout (location = 1) in vec2 aTexCoord;  // Texture coordinates

        // Output to the fragment shader
        out vec2 TexCoord;

        void main()
        {
            // Set the position of the vertex
            gl_Position = vec4(aPos, 0.0, 1.0);

            // Pass the texture coordinates to the fragment shader
            TexCoord = aTexCoord;
        }
    )";


    static constexpr std::string_view FRAGMENT_SHADER_SOURCE = R"(
        #version 460 core

        // Output color
        out vec4 FragColor;

        // Input texture coordinates from vertex shader
        in vec2 TexCoord;

        // Texture sampler
        uniform sampler2D texture1;

        void main()
        {
            // Sample the texture at the given coordinates and set the fragment color
            FragColor = texture(texture1, TexCoord);
        }
    )";

    auto CreateShader(GLenum const type, char const * const source) -> GLuint
    {
        static constexpr auto BUFFER_SIZE = 2048;

        // Create shader object
        auto const shader = glCreateShader(type);
        glShaderSource(shader, 1, &source, nullptr);
        glCompileShader(shader);

        // Check for shader compilation errors
        GLint success;
        glGetShaderiv(shader, GL_COMPILE_STATUS, &success);

        if (!success)
        {
            // Get the error message
            std::array<char, BUFFER_SIZE> infoLog{};
            glGetShaderInfoLog(shader, BUFFER_SIZE, nullptr, infoLog.data());
            throw std::runtime_error(std::format("Error: Shader compilation failed\n{}\n", infoLog.data()));
        }

        return shader;
    }

    auto CreateShaderProgram() -> GLuint
    {
        static constexpr auto BUFFER_SIZE = 2048;

        // Create and compile vertex and fragment shaders
        auto const vertexShader = CreateShader(GL_VERTEX_SHADER, VERTEX_SHADER_SOURCE.data());
        auto const fragmentShader = CreateShader(GL_FRAGMENT_SHADER, FRAGMENT_SHADER_SOURCE.data());

        // Create shader program and attach shaders
        auto const shaderProgram = glCreateProgram();
        glAttachShader(shaderProgram, vertexShader);
        glAttachShader(shaderProgram, fragmentShader);
        glLinkProgram(shaderProgram);

        // Check for shader linking errors
        GLint success;
        glGetProgramiv(shaderProgram, GL_LINK_STATUS, &success);

        if (!success)
        {
            // Get the error message
            std::array<char, BUFFER_SIZE> infoLog{};
            glGetProgramInfoLog(shaderProgram, BUFFER_SIZE, nullptr, infoLog.data());
            throw std::runtime_error(std::format("Error: Shader linking failed\n{}\n", infoLog.data()));
        }

        // Delete the shaders as they're linked into our program now and no longer necessary
        glDeleteShader(vertexShader);
        glDeleteShader(fragmentShader);

        return shaderProgram;
    }

    auto CreateTexture(int const width, int const height) -> GLuint
    {
        GLuint texture;
        glGenTextures(1, &texture);
        glBindTexture(GL_TEXTURE_2D, texture);

        // Specify the texture image
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, nullptr);

        // Set texture parameters
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

        // Check for errors
        if (glGetError() != GL_NO_ERROR)
        {
            throw std::runtime_error("Error: Failed to create texture");
        }

        return texture;
    }

    auto UpdateTexture(GLuint const texture, std::uint8_t const * const image, int const width, int const height) -> void
    {
        // Bind the texture
        glBindTexture(GL_TEXTURE_2D, texture);

        // Update the texture image
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width, height, GL_RGB, GL_UNSIGNED_BYTE, image);

        // Check for errors
        if (glGetError() != GL_NO_ERROR)
        {
            throw std::runtime_error("Error: Failed to update texture");
        }
    }

    auto RenderQuad(GLuint const shaderProgram, GLuint const texture) -> void
    {
        static constexpr std::array VERTICES = {
            -1.0f, -1.0f, 0.0f, 0.0f,
            1.0f, -1.0f, 1.0f, 0.0f,
            1.0f, 1.0f, 1.0f, 1.0f,
            -1.0f, 1.0f, 0.0f, 1.0f
        };

        static constexpr std::array INDICES = {
            0, 1, 2,
            2, 3, 0
        };

        GLuint VBO, VAO, EBO;

        // Clear the screen
        glClear(GL_COLOR_BUFFER_BIT);

        // Generate and bind the VAO, VBO, and EBO
        glGenVertexArrays(1, &VAO);
        glGenBuffers(1, &VBO);
        glGenBuffers(1, &EBO);

        glBindVertexArray(VAO);

        glBindBuffer(GL_ARRAY_BUFFER, VBO);
        glBufferData(GL_ARRAY_BUFFER, sizeof(VERTICES), VERTICES.data(), GL_STATIC_DRAW);

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(INDICES), INDICES.data(), GL_STATIC_DRAW);

        // Configure vertex attributes
        glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), nullptr);
        glEnableVertexAttribArray(0);
        glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), reinterpret_cast<void *>(2 * sizeof(float)));
        glEnableVertexAttribArray(1);

        // Use the shader program and bind the texture
        glUseProgram(shaderProgram);
        glBindTexture(GL_TEXTURE_2D, texture);

        // Draw the quad
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, nullptr);

        // Unbind the VAO
        glBindVertexArray(0);

        // Delete the buffers
        glDeleteVertexArrays(1, &VAO);
        glDeleteBuffers(1, &VBO);
        glDeleteBuffers(1, &EBO);
    }

    auto CreateFullscreenWindow(GLFWmonitor * const monitor, GLFWvidmode const * const mode) -> GLFWwindow *
    {
        // Set window hints for OpenGL context version and profile
        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
        glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

        // Create fullscreen window
        auto const window = glfwCreateWindow(mode->width, mode->height, "Fractal", monitor, nullptr);

        // Check if window creation was successful
        if (!window)
        {
            glfwTerminate();
            throw std::runtime_error("Error: Failed to create GLFW window");
        }

        // Make the OpenGL context current
        glfwMakeContextCurrent(window);

        // Load OpenGL function pointers using GLAD
        if (!gladLoadGL(glfwGetProcAddress))
        {
            glfwTerminate();
            throw std::runtime_error("Error: Failed to initialize GLAD");
        }

        // Enable V-Sync
        glfwSwapInterval(1);

        return window;
    }

    auto CleanUp(GLFWwindow * const window, GLuint const shaderProgram, GLuint const texture) -> void
    {
        // Delete the texture if it is valid
        if (texture != 0)
        {
            glDeleteTextures(1, &texture);
        }

        // Delete the shader program if it is valid
        if (shaderProgram != 0)
        {
            glDeleteProgram(shaderProgram);
        }

        // Destroy the GLFW window if it is valid
        if (window != nullptr)
        {
            glfwDestroyWindow(window);
        }

        // Terminate GLFW
        glfwTerminate();
    }
} // namespace HelperOpenGL
