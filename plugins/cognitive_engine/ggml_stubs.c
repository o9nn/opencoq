/*************************************************************************
 *  v      *   The Coq Proof Assistant  /  The Coq Development Team      *
 * <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016      *
 *   \VV/  ***************************************************************
 *    //   *      This file is distributed under the terms of the        *
 *         *       GNU Lesser General Public License Version 2.1         *
 *************************************************************************/

/**
 * GGML OCaml FFI Stubs Implementation
 * 
 * This file provides the C implementation of GGML bindings for OCaml.
 * When compiled with HAVE_GGML defined, it links against the actual
 * GGML library. Otherwise, it provides stub implementations that
 * raise OCaml exceptions.
 */

#include "ggml_stubs.h"
#include <string.h>
#include <math.h>

/* Custom block operations for GGML context */
static struct custom_operations ggml_ctx_ops = {
    "org.opencoq.ggml_ctx",
    custom_finalize_default,
    custom_compare_default,
    custom_hash_default,
    custom_serialize_default,
    custom_deserialize_default,
    custom_compare_ext_default,
    custom_fixed_length_default
};

/* Custom block operations for GGML tensor */
static struct custom_operations ggml_tensor_ops = {
    "org.opencoq.ggml_tensor",
    custom_finalize_default,
    custom_compare_default,
    custom_hash_default,
    custom_serialize_default,
    custom_deserialize_default,
    custom_compare_ext_default,
    custom_fixed_length_default
};

/* Custom block operations for GGML compute graph */
static struct custom_operations ggml_graph_ops = {
    "org.opencoq.ggml_graph",
    custom_finalize_default,
    custom_compare_default,
    custom_hash_default,
    custom_serialize_default,
    custom_deserialize_default,
    custom_compare_ext_default,
    custom_fixed_length_default
};

#ifdef HAVE_GGML

/*
 * Real GGML implementation
 * These functions call the actual GGML library
 */

#define Ggml_ctx_val(v) (*((struct ggml_context **) Data_custom_val(v)))
#define Ggml_tensor_val(v) (*((struct ggml_tensor **) Data_custom_val(v)))
#define Ggml_graph_val(v) (*((struct ggml_cgraph **) Data_custom_val(v)))

CAMLprim value caml_ggml_init(value mem_size) {
    CAMLparam1(mem_size);
    CAMLlocal1(result);
    
    struct ggml_init_params params = {
        .mem_size   = Long_val(mem_size),
        .mem_buffer = NULL,
        .no_alloc   = false,
    };
    
    struct ggml_context *ctx = ggml_init(params);
    if (ctx == NULL) {
        caml_failwith("ggml_init failed");
    }
    
    result = caml_alloc_custom(&ggml_ctx_ops, sizeof(struct ggml_context *), 0, 1);
    Ggml_ctx_val(result) = ctx;
    
    CAMLreturn(result);
}

CAMLprim value caml_ggml_free(value ctx) {
    CAMLparam1(ctx);
    ggml_free(Ggml_ctx_val(ctx));
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_backend_type(value unit) {
    CAMLparam1(unit);
    CAMLreturn(Val_int(1)); /* 1 = GGML backend */
}

CAMLprim value caml_ggml_new_tensor_1d(value ctx, value type, value ne0) {
    CAMLparam3(ctx, type, ne0);
    CAMLlocal1(result);
    
    struct ggml_tensor *tensor = ggml_new_tensor_1d(
        Ggml_ctx_val(ctx),
        Int_val(type),
        Long_val(ne0)
    );
    
    if (tensor == NULL) {
        caml_failwith("ggml_new_tensor_1d failed");
    }
    
    result = caml_alloc_custom(&ggml_tensor_ops, sizeof(struct ggml_tensor *), 0, 1);
    Ggml_tensor_val(result) = tensor;
    
    CAMLreturn(result);
}

CAMLprim value caml_ggml_new_tensor_2d(value ctx, value type, value ne0, value ne1) {
    CAMLparam4(ctx, type, ne0, ne1);
    CAMLlocal1(result);
    
    struct ggml_tensor *tensor = ggml_new_tensor_2d(
        Ggml_ctx_val(ctx),
        Int_val(type),
        Long_val(ne0),
        Long_val(ne1)
    );
    
    if (tensor == NULL) {
        caml_failwith("ggml_new_tensor_2d failed");
    }
    
    result = caml_alloc_custom(&ggml_tensor_ops, sizeof(struct ggml_tensor *), 0, 1);
    Ggml_tensor_val(result) = tensor;
    
    CAMLreturn(result);
}

CAMLprim value caml_ggml_new_tensor_3d(value ctx, value type, value ne0, value ne1, value ne2) {
    CAMLparam5(ctx, type, ne0, ne1, ne2);
    CAMLlocal1(result);
    
    struct ggml_tensor *tensor = ggml_new_tensor_3d(
        Ggml_ctx_val(ctx),
        Int_val(type),
        Long_val(ne0),
        Long_val(ne1),
        Long_val(ne2)
    );
    
    if (tensor == NULL) {
        caml_failwith("ggml_new_tensor_3d failed");
    }
    
    result = caml_alloc_custom(&ggml_tensor_ops, sizeof(struct ggml_tensor *), 0, 1);
    Ggml_tensor_val(result) = tensor;
    
    CAMLreturn(result);
}

CAMLprim value caml_ggml_new_tensor_4d_native(value ctx, value type, value ne0, value ne1, value ne2, value ne3) {
    CAMLparam5(ctx, type, ne0, ne1, ne2);
    CAMLxparam1(ne3);
    CAMLlocal1(result);
    
    struct ggml_tensor *tensor = ggml_new_tensor_4d(
        Ggml_ctx_val(ctx),
        Int_val(type),
        Long_val(ne0),
        Long_val(ne1),
        Long_val(ne2),
        Long_val(ne3)
    );
    
    if (tensor == NULL) {
        caml_failwith("ggml_new_tensor_4d failed");
    }
    
    result = caml_alloc_custom(&ggml_tensor_ops, sizeof(struct ggml_tensor *), 0, 1);
    Ggml_tensor_val(result) = tensor;
    
    CAMLreturn(result);
}

CAMLprim value caml_ggml_new_tensor_4d(value *argv, int argn) {
    return caml_ggml_new_tensor_4d_native(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
}

CAMLprim value caml_ggml_set_data(value tensor, value data) {
    CAMLparam2(tensor, data);
    
    struct ggml_tensor *t = Ggml_tensor_val(tensor);
    float *src = (float *)Caml_ba_data_val(data);
    size_t size = ggml_nbytes(t);
    
    memcpy(t->data, src, size);
    
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_get_data(value tensor) {
    CAMLparam1(tensor);
    CAMLlocal1(result);
    
    struct ggml_tensor *t = Ggml_tensor_val(tensor);
    int64_t nelements = ggml_nelements(t);
    
    result = caml_ba_alloc_dims(CAML_BA_FLOAT32 | CAML_BA_C_LAYOUT, 1, NULL, nelements);
    memcpy(Caml_ba_data_val(result), t->data, ggml_nbytes(t));
    
    CAMLreturn(result);
}

CAMLprim value caml_ggml_nelements(value tensor) {
    CAMLparam1(tensor);
    CAMLreturn(Val_long(ggml_nelements(Ggml_tensor_val(tensor))));
}

CAMLprim value caml_ggml_nbytes(value tensor) {
    CAMLparam1(tensor);
    CAMLreturn(Val_long(ggml_nbytes(Ggml_tensor_val(tensor))));
}

/* Basic operations */
CAMLprim value caml_ggml_add(value ctx, value a, value b) {
    CAMLparam3(ctx, a, b);
    CAMLlocal1(result);
    
    struct ggml_tensor *tensor = ggml_add(
        Ggml_ctx_val(ctx),
        Ggml_tensor_val(a),
        Ggml_tensor_val(b)
    );
    
    result = caml_alloc_custom(&ggml_tensor_ops, sizeof(struct ggml_tensor *), 0, 1);
    Ggml_tensor_val(result) = tensor;
    
    CAMLreturn(result);
}

CAMLprim value caml_ggml_sub(value ctx, value a, value b) {
    CAMLparam3(ctx, a, b);
    CAMLlocal1(result);
    
    struct ggml_tensor *tensor = ggml_sub(
        Ggml_ctx_val(ctx),
        Ggml_tensor_val(a),
        Ggml_tensor_val(b)
    );
    
    result = caml_alloc_custom(&ggml_tensor_ops, sizeof(struct ggml_tensor *), 0, 1);
    Ggml_tensor_val(result) = tensor;
    
    CAMLreturn(result);
}

CAMLprim value caml_ggml_mul(value ctx, value a, value b) {
    CAMLparam3(ctx, a, b);
    CAMLlocal1(result);
    
    struct ggml_tensor *tensor = ggml_mul(
        Ggml_ctx_val(ctx),
        Ggml_tensor_val(a),
        Ggml_tensor_val(b)
    );
    
    result = caml_alloc_custom(&ggml_tensor_ops, sizeof(struct ggml_tensor *), 0, 1);
    Ggml_tensor_val(result) = tensor;
    
    CAMLreturn(result);
}

CAMLprim value caml_ggml_div(value ctx, value a, value b) {
    CAMLparam3(ctx, a, b);
    CAMLlocal1(result);
    
    struct ggml_tensor *tensor = ggml_div(
        Ggml_ctx_val(ctx),
        Ggml_tensor_val(a),
        Ggml_tensor_val(b)
    );
    
    result = caml_alloc_custom(&ggml_tensor_ops, sizeof(struct ggml_tensor *), 0, 1);
    Ggml_tensor_val(result) = tensor;
    
    CAMLreturn(result);
}

CAMLprim value caml_ggml_scale(value ctx, value a, value s) {
    CAMLparam3(ctx, a, s);
    CAMLlocal1(result);
    
    struct ggml_tensor *tensor = ggml_scale(
        Ggml_ctx_val(ctx),
        Ggml_tensor_val(a),
        Double_val(s)
    );
    
    result = caml_alloc_custom(&ggml_tensor_ops, sizeof(struct ggml_tensor *), 0, 1);
    Ggml_tensor_val(result) = tensor;
    
    CAMLreturn(result);
}

CAMLprim value caml_ggml_neg(value ctx, value a) {
    CAMLparam2(ctx, a);
    CAMLlocal1(result);
    
    struct ggml_tensor *tensor = ggml_neg(
        Ggml_ctx_val(ctx),
        Ggml_tensor_val(a)
    );
    
    result = caml_alloc_custom(&ggml_tensor_ops, sizeof(struct ggml_tensor *), 0, 1);
    Ggml_tensor_val(result) = tensor;
    
    CAMLreturn(result);
}

/* Matrix operations */
CAMLprim value caml_ggml_mul_mat(value ctx, value a, value b) {
    CAMLparam3(ctx, a, b);
    CAMLlocal1(result);
    
    struct ggml_tensor *tensor = ggml_mul_mat(
        Ggml_ctx_val(ctx),
        Ggml_tensor_val(a),
        Ggml_tensor_val(b)
    );
    
    result = caml_alloc_custom(&ggml_tensor_ops, sizeof(struct ggml_tensor *), 0, 1);
    Ggml_tensor_val(result) = tensor;
    
    CAMLreturn(result);
}

CAMLprim value caml_ggml_transpose(value ctx, value a) {
    CAMLparam2(ctx, a);
    CAMLlocal1(result);
    
    struct ggml_tensor *tensor = ggml_transpose(
        Ggml_ctx_val(ctx),
        Ggml_tensor_val(a)
    );
    
    result = caml_alloc_custom(&ggml_tensor_ops, sizeof(struct ggml_tensor *), 0, 1);
    Ggml_tensor_val(result) = tensor;
    
    CAMLreturn(result);
}

/* Activation functions */
CAMLprim value caml_ggml_relu(value ctx, value a) {
    CAMLparam2(ctx, a);
    CAMLlocal1(result);
    
    struct ggml_tensor *tensor = ggml_relu(
        Ggml_ctx_val(ctx),
        Ggml_tensor_val(a)
    );
    
    result = caml_alloc_custom(&ggml_tensor_ops, sizeof(struct ggml_tensor *), 0, 1);
    Ggml_tensor_val(result) = tensor;
    
    CAMLreturn(result);
}

CAMLprim value caml_ggml_gelu(value ctx, value a) {
    CAMLparam2(ctx, a);
    CAMLlocal1(result);
    
    struct ggml_tensor *tensor = ggml_gelu(
        Ggml_ctx_val(ctx),
        Ggml_tensor_val(a)
    );
    
    result = caml_alloc_custom(&ggml_tensor_ops, sizeof(struct ggml_tensor *), 0, 1);
    Ggml_tensor_val(result) = tensor;
    
    CAMLreturn(result);
}

CAMLprim value caml_ggml_silu(value ctx, value a) {
    CAMLparam2(ctx, a);
    CAMLlocal1(result);
    
    struct ggml_tensor *tensor = ggml_silu(
        Ggml_ctx_val(ctx),
        Ggml_tensor_val(a)
    );
    
    result = caml_alloc_custom(&ggml_tensor_ops, sizeof(struct ggml_tensor *), 0, 1);
    Ggml_tensor_val(result) = tensor;
    
    CAMLreturn(result);
}

CAMLprim value caml_ggml_soft_max(value ctx, value a) {
    CAMLparam2(ctx, a);
    CAMLlocal1(result);
    
    struct ggml_tensor *tensor = ggml_soft_max(
        Ggml_ctx_val(ctx),
        Ggml_tensor_val(a)
    );
    
    result = caml_alloc_custom(&ggml_tensor_ops, sizeof(struct ggml_tensor *), 0, 1);
    Ggml_tensor_val(result) = tensor;
    
    CAMLreturn(result);
}

/* Compute graph */
CAMLprim value caml_ggml_build_forward(value ctx, value tensor) {
    CAMLparam2(ctx, tensor);
    CAMLlocal1(result);
    
    struct ggml_cgraph *graph = ggml_new_graph(Ggml_ctx_val(ctx));
    ggml_build_forward_expand(graph, Ggml_tensor_val(tensor));
    
    result = caml_alloc_custom(&ggml_graph_ops, sizeof(struct ggml_cgraph *), 0, 1);
    Ggml_graph_val(result) = graph;
    
    CAMLreturn(result);
}

CAMLprim value caml_ggml_graph_compute(value ctx, value graph) {
    CAMLparam2(ctx, graph);
    
    ggml_graph_compute_with_ctx(Ggml_ctx_val(ctx), Ggml_graph_val(graph), 1);
    
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_used_mem(value ctx) {
    CAMLparam1(ctx);
    CAMLreturn(Val_long(ggml_used_mem(Ggml_ctx_val(ctx))));
}

/* CPU feature detection */
CAMLprim value caml_ggml_cpu_has_avx(value unit) {
    CAMLparam1(unit);
    CAMLreturn(Val_bool(ggml_cpu_has_avx()));
}

CAMLprim value caml_ggml_cpu_has_avx2(value unit) {
    CAMLparam1(unit);
    CAMLreturn(Val_bool(ggml_cpu_has_avx2()));
}

CAMLprim value caml_ggml_cpu_has_fma(value unit) {
    CAMLparam1(unit);
    CAMLreturn(Val_bool(ggml_cpu_has_fma()));
}

CAMLprim value caml_ggml_cpu_has_neon(value unit) {
    CAMLparam1(unit);
    CAMLreturn(Val_bool(ggml_cpu_has_neon()));
}

#else /* !HAVE_GGML */

/*
 * Stub implementation when GGML is not available
 * These functions raise OCaml exceptions
 */

static void ggml_not_available(void) {
    caml_failwith("GGML backend not available. Compile with -DHAVE_GGML and link against libggml.");
}

CAMLprim value caml_ggml_init(value mem_size) {
    CAMLparam1(mem_size);
    ggml_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_free(value ctx) {
    CAMLparam1(ctx);
    ggml_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_backend_type(value unit) {
    CAMLparam1(unit);
    CAMLreturn(Val_int(0)); /* 0 = OCaml backend (GGML not available) */
}

CAMLprim value caml_ggml_new_tensor_1d(value ctx, value type, value ne0) {
    CAMLparam3(ctx, type, ne0);
    ggml_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_new_tensor_2d(value ctx, value type, value ne0, value ne1) {
    CAMLparam4(ctx, type, ne0, ne1);
    ggml_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_new_tensor_3d(value ctx, value type, value ne0, value ne1, value ne2) {
    CAMLparam5(ctx, type, ne0, ne1, ne2);
    ggml_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_new_tensor_4d(value *argv, int argn) {
    ggml_not_available();
    return Val_unit;
}

CAMLprim value caml_ggml_set_data(value tensor, value data) {
    CAMLparam2(tensor, data);
    ggml_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_get_data(value tensor) {
    CAMLparam1(tensor);
    ggml_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_nelements(value tensor) {
    CAMLparam1(tensor);
    ggml_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_nbytes(value tensor) {
    CAMLparam1(tensor);
    ggml_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_add(value ctx, value a, value b) {
    CAMLparam3(ctx, a, b);
    ggml_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_sub(value ctx, value a, value b) {
    CAMLparam3(ctx, a, b);
    ggml_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_mul(value ctx, value a, value b) {
    CAMLparam3(ctx, a, b);
    ggml_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_div(value ctx, value a, value b) {
    CAMLparam3(ctx, a, b);
    ggml_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_scale(value ctx, value a, value s) {
    CAMLparam3(ctx, a, s);
    ggml_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_neg(value ctx, value a) {
    CAMLparam2(ctx, a);
    ggml_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_mul_mat(value ctx, value a, value b) {
    CAMLparam3(ctx, a, b);
    ggml_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_transpose(value ctx, value a) {
    CAMLparam2(ctx, a);
    ggml_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_relu(value ctx, value a) {
    CAMLparam2(ctx, a);
    ggml_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_gelu(value ctx, value a) {
    CAMLparam2(ctx, a);
    ggml_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_silu(value ctx, value a) {
    CAMLparam2(ctx, a);
    ggml_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_soft_max(value ctx, value a) {
    CAMLparam2(ctx, a);
    ggml_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_build_forward(value ctx, value tensor) {
    CAMLparam2(ctx, tensor);
    ggml_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_graph_compute(value ctx, value graph) {
    CAMLparam2(ctx, graph);
    ggml_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_used_mem(value ctx) {
    CAMLparam1(ctx);
    ggml_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_cpu_has_avx(value unit) {
    CAMLparam1(unit);
    CAMLreturn(Val_bool(0));
}

CAMLprim value caml_ggml_cpu_has_avx2(value unit) {
    CAMLparam1(unit);
    CAMLreturn(Val_bool(0));
}

CAMLprim value caml_ggml_cpu_has_fma(value unit) {
    CAMLparam1(unit);
    CAMLreturn(Val_bool(0));
}

CAMLprim value caml_ggml_cpu_has_neon(value unit) {
    CAMLparam1(unit);
    CAMLreturn(Val_bool(0));
}

#endif /* HAVE_GGML */
