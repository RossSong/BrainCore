// Copyright © 2016 Venture Media Labs. All rights reserved.
//
// This file is part of BrainCore. The full BrainCore copyright notice,
// including terms governing use, modification, and redistribution, is
// contained in the file LICENSE at the root of the source code distribution
// tree.

#include <metal_stdlib>

using namespace metal;

struct InnerProductDimensions {
    ushort batch_size;
    ushort input_size;
    ushort output_size;
};

kernel void inner_product_forward(const device float* input [[ buffer(0) ]],
                                  device float* output [[ buffer(1) ]],
                                  const device float* weights [[ buffer(2) ]],
                                  const device float* biases [[ buffer(3) ]],
                                  constant InnerProductDimensions& dims [[ buffer(4) ]],
                                  uint2 id [[ thread_position_in_grid ]])
{
    const auto outputElement = id.x;
    const auto batchElement = id.y;

    if (outputElement >= dims.output_size || batchElement >= dims.batch_size)
        return;
    
    output[batchElement + outputElement * dims.batch_size] = biases[outputElement];
    for (uint i = 0; i < dims.input_size; i += 1) {
        output[batchElement + outputElement * dims.batch_size] += weights[outputElement + i * dims.output_size] * input[batchElement + i * dims.batch_size];
    }
}

kernel void inner_product_backward_params(const device float* output_deltas [[ buffer(0) ]],
                                          const device float* input [[ buffer(1) ]],
                                          device float* weight_deltas [[ buffer(2) ]],
                                          device float* bias_deltas [[ buffer(3) ]],
                                          constant InnerProductDimensions& dims [[ buffer(4) ]],
                                          uint outputElement [[ thread_position_in_grid ]])
{
    if (outputElement >= dims.output_size)
        return;

    for (uint i = 0; i < dims.input_size; i += 1) {
        weight_deltas[outputElement +  i * dims.output_size] = 0.0;
    }
    bias_deltas[outputElement] = 0.0;
    for (uint i = 0; i < dims.batch_size; i += 1) {
        for (uint j = 0; j < dims.input_size; j += 1) {
            weight_deltas[outputElement +  j * dims.output_size] += output_deltas[i + outputElement * dims.batch_size] * input[i + j * dims.batch_size];
        }
        bias_deltas[outputElement] += output_deltas[i + outputElement * dims.batch_size];
    }
}

kernel void inner_product_backward_input(const device float* output_deltas [[ buffer(0) ]],
                                         device float* input_deltas [[ buffer(1) ]],
                                         const device float* weights [[ buffer(2) ]],
                                         constant InnerProductDimensions& dims [[ buffer(3) ]],
                                         uint2 id [[ thread_position_in_grid ]])
{
    const auto inputElement = id.x;
    const auto batchElement = id.y;
    
    if (inputElement >= dims.input_size || batchElement >= dims.batch_size)
        return;

    input_deltas[batchElement + inputElement * dims.batch_size] = 0.0;
    for (uint i = 0; i < dims.output_size; i += 1) {
        input_deltas[batchElement + inputElement * dims.batch_size] += weights[i + inputElement * dims.output_size] * output_deltas[batchElement + i * dims.batch_size];
    }
}
