/*************************************************************************
 *  v      *   The Coq Proof Assistant  /  The Coq Development Team      *
 * <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016      *
 *   \VV/  ***************************************************************
 *    //   *      This file is distributed under the terms of the        *
 *         *       GNU Lesser General Public License Version 2.1         *
 *************************************************************************/

/**
 * GGML OCaml FFI Stubs Header
 * 
 * This header defines the C interface for GGML operations that can be
 * called from OCaml via the foreign function interface.
 * 
 * When GGML is available, these functions dispatch to the actual GGML
 * implementation. Otherwise, they provide fallback implementations.
 */

#ifndef GGML_STUBS_H
#define GGML_STUBS_H

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/bigarray.h>

#ifdef HAVE_GGML
#include <ggml.h>
#endif

/* Context management */
CAMLprim value caml_ggml_init(value mem_size);
CAMLprim value caml_ggml_free(value ctx);
CAMLprim value caml_ggml_backend_type(value unit);

/* Tensor creation */
CAMLprim value caml_ggml_new_tensor_1d(value ctx, value type, value ne0);
CAMLprim value caml_ggml_new_tensor_2d(value ctx, value type, value ne0, value ne1);
CAMLprim value caml_ggml_new_tensor_3d(value ctx, value type, value ne0, value ne1, value ne2);
CAMLprim value caml_ggml_new_tensor_4d(value ctx, value type, value ne0, value ne1, value ne2, value ne3);

/* Tensor data access */
CAMLprim value caml_ggml_set_data(value tensor, value data);
CAMLprim value caml_ggml_get_data(value tensor);
CAMLprim value caml_ggml_nelements(value tensor);
CAMLprim value caml_ggml_nbytes(value tensor);

/* Basic operations */
CAMLprim value caml_ggml_add(value ctx, value a, value b);
CAMLprim value caml_ggml_sub(value ctx, value a, value b);
CAMLprim value caml_ggml_mul(value ctx, value a, value b);
CAMLprim value caml_ggml_div(value ctx, value a, value b);
CAMLprim value caml_ggml_scale(value ctx, value a, value s);
CAMLprim value caml_ggml_neg(value ctx, value a);

/* Matrix operations */
CAMLprim value caml_ggml_mul_mat(value ctx, value a, value b);
CAMLprim value caml_ggml_transpose(value ctx, value a);
CAMLprim value caml_ggml_permute(value ctx, value a, value axis0, value axis1, value axis2, value axis3);
CAMLprim value caml_ggml_reshape(value ctx, value a, value shape);

/* Activation functions */
CAMLprim value caml_ggml_relu(value ctx, value a);
CAMLprim value caml_ggml_gelu(value ctx, value a);
CAMLprim value caml_ggml_silu(value ctx, value a);
CAMLprim value caml_ggml_sigmoid(value ctx, value a);
CAMLprim value caml_ggml_tanh(value ctx, value a);

/* Normalization */
CAMLprim value caml_ggml_norm(value ctx, value a, value eps);
CAMLprim value caml_ggml_rms_norm(value ctx, value a, value eps);
CAMLprim value caml_ggml_soft_max(value ctx, value a);

/* Reduction operations */
CAMLprim value caml_ggml_sum(value ctx, value a);
CAMLprim value caml_ggml_mean(value ctx, value a);
CAMLprim value caml_ggml_argmax(value ctx, value a);

/* Attention operations */
CAMLprim value caml_ggml_flash_attn(value ctx, value q, value k, value v, value masked);
CAMLprim value caml_ggml_flash_attn_back(value ctx, value q, value k, value v, value d, value masked);

/* Compute graph */
CAMLprim value caml_ggml_build_forward(value ctx, value tensor);
CAMLprim value caml_ggml_graph_compute(value ctx, value graph);
CAMLprim value caml_ggml_graph_reset(value graph);

/* Memory management */
CAMLprim value caml_ggml_used_mem(value ctx);
CAMLprim value caml_ggml_set_scratch(value ctx, value scratch);

/* Backend selection */
CAMLprim value caml_ggml_cpu_has_avx(value unit);
CAMLprim value caml_ggml_cpu_has_avx2(value unit);
CAMLprim value caml_ggml_cpu_has_fma(value unit);
CAMLprim value caml_ggml_cpu_has_neon(value unit);

#endif /* GGML_STUBS_H */
