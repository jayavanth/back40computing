/******************************************************************************
 * Copyright (c) 2010-2011, Duane Merrill.  All rights reserved.
 * Copyright (c) 2011-2013, NVIDIA CORPORATION.  All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 ******************************************************************************/

/******************************************************************************
 * Consecutive reduction spine scan kernel
 ******************************************************************************/

#pragma once

#include <b40c/util/cta_work_distribution.cuh>

#include <b40c/consecutive_reduction/spine/cta.cuh>

namespace b40c {
namespace consecutive_reduction {
namespace spine {


/**
 * Consecutive reduction spine scan pass
 */
template <typename KernelPolicy>
__device__ __forceinline__ void SpinePass(
	typename KernelPolicy::ValueType 		*d_in_partials,
	typename KernelPolicy::ValueType 		*d_out_partials,
	typename KernelPolicy::SizeT			*d_in_flags,
	typename KernelPolicy::SizeT			*d_out_flags,
	typename KernelPolicy::SpineSizeT 		spine_elements,
	typename KernelPolicy::ReductionOp 		reduction_op,
	typename KernelPolicy::SmemStorage		&smem_storage)
{
	typedef Cta<KernelPolicy> Cta;
	typedef typename KernelPolicy::SpineSizeT 			SpineSizeT;
	typedef typename KernelPolicy::RakingSoaDetails 		RakingSoaDetails;
	typedef typename KernelPolicy::SoaScanOperator		SoaScanOperator;

	// Exit if we're not the first CTA
	if (blockIdx.x > 0) return;

	// CTA processing abstraction
	Cta cta(
		smem_storage,
		d_in_partials,
		d_out_partials,
		d_in_flags,
		d_out_flags,
		SoaScanOperator(reduction_op));

	// Number of elements in (the last) partially-full tile (requires guarded loads)
	SpineSizeT guarded_elements = spine_elements & (KernelPolicy::TILE_ELEMENTS - 1);

	// Offset of final, partially-full tile (requires guarded loads)
	SpineSizeT guarded_offset = spine_elements - guarded_elements;

	util::CtaWorkLimits<SpineSizeT> work_limits(
		0,					// Offset at which this CTA begins processing
		spine_elements,		// Total number of elements for this CTA to process
		guarded_offset, 	// Offset of final, partially-full tile (requires guarded loads)
		guarded_elements,	// Number of elements in partially-full tile
		spine_elements,		// Offset at which this CTA is out-of-bounds
		true);				// If this block is the last block in the grid with any work

	cta.ProcessWorkRange(work_limits);
}


/**
 * Consecutive reduction spine scan kernel entry point
 */
template <typename KernelPolicy>
__launch_bounds__ (KernelPolicy::THREADS, KernelPolicy::MIN_CTA_OCCUPANCY)
__global__ 
void Kernel(
	typename KernelPolicy::ValueType 			*d_in_partials,
	typename KernelPolicy::ValueType 			*d_out_partials,
	typename KernelPolicy::SizeT				*d_in_flags,
	typename KernelPolicy::SizeT				*d_out_flags,
	typename KernelPolicy::SpineSizeT 			spine_elements,
	typename KernelPolicy::ReductionOp 			reduction_op)
{
	// Shared storage for the kernel
	__shared__ typename KernelPolicy::SmemStorage smem_storage;

	SpinePass<KernelPolicy>(
		d_in_partials,
		d_out_partials,
		d_in_flags,
		d_out_flags,
		spine_elements,
		reduction_op,
		smem_storage);
}


} // namespace spine
} // namespace consecutive_reduction
} // namespace b40c

