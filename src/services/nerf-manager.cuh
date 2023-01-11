#pragma once

#include <memory>
#include <stdint.h>
#include <vector>

#include "../common.h"
#include "../models/cascaded-occupancy-grid.cuh"
#include "../models/dataset.h"
#include "../models/nerf-network.h"
#include "../models/nerf.cuh"

NRC_NAMESPACE_BEGIN

struct NeRFManager {
private:
	std::vector<NeRF> nerfs;
public:
	// TODO: protect nerfs with const getter?
	// There are downstream effects which make this impossible for now
	// like the fact that NeRFNetwork inference has self-mutating side effects
	// also, pointer/reference sharing between trainer and renderer
	std::vector<NeRF*> get_nerfs() {
		std::vector<NeRF*> nerf_ptrs;
		nerf_ptrs.reserve(nerfs.size());
		for (auto& nerf : nerfs) {
			nerf_ptrs.emplace_back(&nerf);
		}
		return nerf_ptrs;
	}

	// create a new nerf
	NeRF* create_trainable_nerf(const cudaStream_t& stream, const BoundingBox& bbox) {
		nerfs.emplace_back(
			NerfNetwork(bbox.size_x),
			CascadedOccupancyGrid(5),
			bbox
		);

		NeRF& nerf = nerfs.back();
		
		// for now we will initialize the occupancy grid here, but it should probably done somewhere else
		nerf.occupancy_grid.initialize_bitfield(stream);
		nerf.occupancy_grid.initialize_values(stream);
		
		// Initialize occupancy grid bitfield (all bits set to 1)
		CUDA_CHECK_THROW(
			cudaMemsetAsync(
				nerf.occupancy_grid.get_bitfield(),
				(uint8_t)0b11111111, // set all bits to 1
				nerf.occupancy_grid.get_n_bitfield_elements(),
				stream
			)
		);

		return &nerf;
	}

	// manage nerfs

	// destroy nerfs	
};

NRC_NAMESPACE_END