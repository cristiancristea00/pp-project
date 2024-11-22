#pragma once


template <std::floating_point T>
struct Complex
{
    T real;
    T imag;

    __device__ auto operator+(Complex const & other) const -> Complex
    {
        return {real + other.real, imag + other.imag};
    }

    __device__ auto operator-(Complex const & other) const -> Complex
    {
        return {real - other.real, imag - other.imag};
    }

    __device__ auto operator*(Complex const & other) const -> Complex
    {
        return {real * other.real - imag * other.imag, real * other.imag + imag * other.real};
    }

    __device__ auto norm() const -> T
    {
        return real * real + imag * imag;
    }

    __device__ auto conj() const -> Complex
    {
        return {real, -imag};
    }

    __device__ auto cos() const -> Complex
    {
        return {cosf(real) * coshf(imag), -sinf(real) * sinhf(imag)};
    }
};
