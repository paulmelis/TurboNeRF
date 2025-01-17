#pragma once

#include <optional>
#include <vector>

#include "../math/transform4f.cuh"
#include "../common.h"
#include "dataset.h"
#include "nerf.cuh"

TURBO_NAMESPACE_BEGIN

/**
 * A NeRFProxy is a reference to one or more NeRF objects.
 * The NeRFs should all share copies of the same data,
 * but they may be distributed across multiple GPUs.
 */

struct NeRFProxy {
    std::vector<NeRF> nerfs;
    std::optional<Dataset> dataset;
    
    // nerf props
    BoundingBox bounding_box = BoundingBox();
    Transform4f transform = Transform4f::Identity();

    bool is_valid = false;
    bool is_visible = true;
    bool is_dataset_dirty = true;

	uint32_t training_step = 0;

    NeRFProxy() = default;
    
    // TODO:
    // bounding box (training, rendering)
    // masks
    // distortions

    std::vector<NeRF*> get_nerf_ptrs() {
        std::vector<NeRF*> ptrs;
        ptrs.reserve(nerfs.size());
        for (auto& nerf : nerfs) {
            ptrs.emplace_back(&nerf);
        }
        return ptrs;
    }

    void update_dataset_if_necessary(const cudaStream_t& stream) {
        if (!dataset.has_value()) {
            return;
        }

        // supported changes: Everything about Cameras, except how many there are.
        // aka the number of cameras must remain the same as when the nerf_proxy was constructed.
        if (!is_dataset_dirty) {
            return;
        }

        // TODO: do for all NeRFs
        auto& nerf = nerfs[0];
        
        CUDA_CHECK_THROW(
            cudaMemcpyAsync(
                nerf.dataset_ws.cameras,
                dataset->cameras.data(),
                dataset->cameras.size() * sizeof(Camera),
                cudaMemcpyHostToDevice,
                stream
            )
        );

        is_dataset_dirty = false;
    }
};

TURBO_NAMESPACE_END
