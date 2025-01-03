#include <cmath>
#include <iostream>
#include <vector>
#include <nlohmann/json.hpp>
#include <fstream>
#include <cuda_runtime.h>

typedef struct option {
    float stock_p;
    float strike_p;
    float exp_time;
    float rf_rate;
    float vol;
} opt;

__device__ float cnd(float d) {
    const float A1 = 0.31938153;
    const float A2 = -0.356563782;
    const float A3 = 1.781477937;
    const float A4 = -1.821255978;
    const float A5 = 1.330274429;
    const float RSQRT2PI = 0.39894228040143267793994605993438;

    float K = 1.0 / (1.0 + 0.2316419 * fabs(d));
    float cnd = RSQRT2PI * exp(-0.5 * d * d) *
                (K * (A1 + K * (A2 + K * (A3 + K * (A4 + K * A5)))));

    if (d > 0)
        cnd = 1.0 - cnd;

    return cnd;
}

__global__ void calc(opt* options, float* price) {
    int idx = threadIdx.x + blockIdx.x * blockDim.x;
    if (idx < 10) {
        float S = options[idx].stock_p;
        float X = options[idx].strike_p;
        float T = options[idx].exp_time;
        float R = options[idx].rf_rate;
        float V = options[idx].vol;

        float d1 = (log(S / X) + (R + 0.5 * V * V) * T) / (V * sqrt(T));
        float d2 = d1 - V * sqrt(T);

        float cnd_d1 = cnd(d1);
        float cnd_d2 = cnd(d2);

        price[idx] = S * cnd_d1 - X * exp(-R * T) * cnd_d2;
    }
}

int main() {
    std::ifstream infile("out.json");
    if (!infile.is_open()) {
        std::cerr << "Error opening file" << std::endl;
        return 1;
    }

    std::vector<nlohmann::json> data(10);
    try {
        nlohmann::json jsonData;
        infile >> jsonData;

        if (!jsonData.is_array() || jsonData.size() != 10) {
            std::cerr << "Invalid JSON format or size" << std::endl;
            return 1;
        }

        for (int i = 0; i < 10; i++) {
            data[i] = jsonData[i];
            std::cout << "Read option " << i << ": " << data[i] << std::endl;
        }
    } catch (const nlohmann::json::parse_error& e) {
        std::cerr << "Parse error: " << e.what() << std::endl;
        return 1;
    }

    std::vector<float> h_price(10);
    float* d_price;
    std::vector<opt> options(10);
    for (int i = 0; i < 10; i++) {
        options[i] = {data[i]["stock_p"], data[i]["strike_p"], data[i]["exp_time"], data[i]["rf_rate"], data[i]["vol"]};
    }

    opt* d_options;

    cudaMalloc((void**)&d_price, 10 * sizeof(float));
    cudaMalloc((void**)&d_options, 10 * sizeof(opt));

    cudaMemcpy(d_price, h_price.data(), 10 * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(d_options, options.data(), 10 * sizeof(opt), cudaMemcpyHostToDevice);

    int blocksize = 1;
    int gridsize = (10 + blocksize - 1) / blocksize;

    calc<<<gridsize, blocksize>>>(d_options, d_price);

    cudaMemcpy(h_price.data(), d_price, 10 * sizeof(float), cudaMemcpyDeviceToHost);

    std::cout << "Result vector (price): ";
    for (int i = 0; i < 10; i++) {
        std::cout << h_price[i] << " ";
    }

    cudaFree(d_price);
    cudaFree(d_options);

    return 0;
}