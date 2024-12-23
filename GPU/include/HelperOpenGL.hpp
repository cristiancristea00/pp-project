#pragma once

#define GLFW_INCLUDE_NONE
#include <GLFW/glfw3.h>
#include "glad/gl.h"

#include <cstdint>


namespace HelperOpenGL
{
    auto CreateShader(GLenum type, char const * source) -> GLuint;

    auto CreateShaderProgram() -> GLuint;

    auto CreateTexture(int width, int height) -> GLuint;

    auto UpdateTexture(GLuint texture, std::uint8_t const * image, int width, int height) -> void;

    auto RenderQuad(GLuint shaderProgram, GLuint texture) -> void;

    auto CreateFullscreenWindow(GLFWmonitor * monitor, GLFWvidmode const * mode) -> GLFWwindow *;

    auto CleanUp(GLFWwindow * window, GLuint shaderProgram, GLuint texture) -> void;
} // namespace HelperOpenGL
