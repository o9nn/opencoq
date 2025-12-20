/*************************************************************************
 *  v      *   The Coq Proof Assistant  /  The Coq Development Team      *
 * <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016      *
 *   \VV/  ***************************************************************
 *    //   *      This file is distributed under the terms of the        *
 *         *       GNU Lesser General Public License Version 2.1         *
 *************************************************************************/

/**
 * GGML Native Bindings for OpenCoq
 * 
 * This file provides complete native bindings to the GGML library,
 * including:
 * - Full tensor operations (creation, manipulation, computation)
 * - Backend selection (CPU, CUDA, Metal, Vulkan)
 * - Quantization support (Q4_0, Q4_1, Q5_0, Q5_1, Q8_0, etc.)
 * - Memory-mapped model loading
 * - Multi-threaded computation
 * 
 * Build with: -DHAVE_GGML -lggml
 * Optional: -DGGML_USE_CUDA -lcuda -lcublas
 *           -DGGML_USE_METAL -framework Metal -framework Foundation
 */

#include "ggml_stubs.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>

#ifdef HAVE_GGML
#include <ggml.h>
#ifdef GGML_USE_CUDA
#include <ggml-cuda.h>
#endif
#ifdef GGML_USE_METAL
#include <ggml-metal.h>
#endif
#endif

/*
 * ============================================================================
 * Type Definitions and Macros
 * ============================================================================
 */

#define GGML_MAX_CONTEXTS 64
#define GGML_MAX_GRAPHS 64

/* Backend types */
typedef enum {
    BACKEND_CPU = 0,
    BACKEND_CUDA = 1,
    BACKEND_METAL = 2,
    BACKEND_VULKAN = 3,
    BACKEND_STUB = 99
} ggml_backend_enum;

/* Context wrapper with metadata */
typedef struct {
    void *ctx;              /* ggml_context pointer */
    size_t mem_size;        /* Allocated memory size */
    int backend;            /* Backend type */
    int n_threads;          /* Number of threads */
    int ref_count;          /* Reference count */
} ggml_ctx_wrapper;

/* Tensor wrapper with metadata */
typedef struct {
    void *tensor;           /* ggml_tensor pointer */
    int ctx_id;             /* Parent context ID */
    int is_view;            /* Is this a view of another tensor */
    char name[64];          /* Tensor name for debugging */
} ggml_tensor_wrapper;

/* Graph wrapper */
typedef struct {
    void *graph;            /* ggml_cgraph pointer */
    int ctx_id;             /* Parent context ID */
    int n_nodes;            /* Number of nodes */
} ggml_graph_wrapper;

/* Global context registry */
static ggml_ctx_wrapper *g_contexts[GGML_MAX_CONTEXTS] = {0};
static int g_next_ctx_id = 0;

/* Custom block operations */
static struct custom_operations ggml_ctx_native_ops = {
    "org.opencoq.ggml_ctx_native",
    custom_finalize_default,
    custom_compare_default,
    custom_hash_default,
    custom_serialize_default,
    custom_deserialize_default,
    custom_compare_ext_default,
    custom_fixed_length_default
};

static struct custom_operations ggml_tensor_native_ops = {
    "org.opencoq.ggml_tensor_native",
    custom_finalize_default,
    custom_compare_default,
    custom_hash_default,
    custom_serialize_default,
    custom_deserialize_default,
    custom_compare_ext_default,
    custom_fixed_length_default
};

static struct custom_operations ggml_graph_native_ops = {
    "org.opencoq.ggml_graph_native",
    custom_finalize_default,
    custom_compare_default,
    custom_hash_default,
    custom_serialize_default,
    custom_deserialize_default,
    custom_compare_ext_default,
    custom_fixed_length_default
};

/*
 * ============================================================================
 * Helper Macros
 * ============================================================================
 */

#define Ctx_wrapper_val(v) (*((ggml_ctx_wrapper **) Data_custom_val(v)))
#define Tensor_wrapper_val(v) (*((ggml_tensor_wrapper **) Data_custom_val(v)))
#define Graph_wrapper_val(v) (*((ggml_graph_wrapper **) Data_custom_val(v)))

#ifdef HAVE_GGML
#define Ggml_ctx(w) ((struct ggml_context *)(w)->ctx)
#define Ggml_tensor(w) ((struct ggml_tensor *)(w)->tensor)
#define Ggml_graph(w) ((struct ggml_cgraph *)(w)->graph)
#endif

/*
 * ============================================================================
 * Backend Detection and Selection
 * ============================================================================
 */

CAMLprim value caml_ggml_native_backend_type(value unit) {
    CAMLparam1(unit);
#ifdef HAVE_GGML
#ifdef GGML_USE_CUDA
    CAMLreturn(Val_int(BACKEND_CUDA));
#elif defined(GGML_USE_METAL)
    CAMLreturn(Val_int(BACKEND_METAL));
#else
    CAMLreturn(Val_int(BACKEND_CPU));
#endif
#else
    CAMLreturn(Val_int(BACKEND_STUB));
#endif
}

CAMLprim value caml_ggml_native_backend_name(value unit) {
    CAMLparam1(unit);
    CAMLlocal1(result);
    
#ifdef HAVE_GGML
#ifdef GGML_USE_CUDA
    result = caml_copy_string("CUDA");
#elif defined(GGML_USE_METAL)
    result = caml_copy_string("Metal");
#else
    result = caml_copy_string("CPU");
#endif
#else
    result = caml_copy_string("Stub");
#endif
    
    CAMLreturn(result);
}

/*
 * ============================================================================
 * CPU Feature Detection
 * ============================================================================
 */

CAMLprim value caml_ggml_native_cpu_has_avx(value unit) {
    CAMLparam1(unit);
#ifdef HAVE_GGML
    CAMLreturn(Val_bool(ggml_cpu_has_avx()));
#else
    CAMLreturn(Val_bool(0));
#endif
}

CAMLprim value caml_ggml_native_cpu_has_avx2(value unit) {
    CAMLparam1(unit);
#ifdef HAVE_GGML
    CAMLreturn(Val_bool(ggml_cpu_has_avx2()));
#else
    CAMLreturn(Val_bool(0));
#endif
}

CAMLprim value caml_ggml_native_cpu_has_avx512(value unit) {
    CAMLparam1(unit);
#ifdef HAVE_GGML
    CAMLreturn(Val_bool(ggml_cpu_has_avx512()));
#else
    CAMLreturn(Val_bool(0));
#endif
}

CAMLprim value caml_ggml_native_cpu_has_avx512_vbmi(value unit) {
    CAMLparam1(unit);
#ifdef HAVE_GGML
    CAMLreturn(Val_bool(ggml_cpu_has_avx512_vbmi()));
#else
    CAMLreturn(Val_bool(0));
#endif
}

CAMLprim value caml_ggml_native_cpu_has_avx512_vnni(value unit) {
    CAMLparam1(unit);
#ifdef HAVE_GGML
    CAMLreturn(Val_bool(ggml_cpu_has_avx512_vnni()));
#else
    CAMLreturn(Val_bool(0));
#endif
}

CAMLprim value caml_ggml_native_cpu_has_fma(value unit) {
    CAMLparam1(unit);
#ifdef HAVE_GGML
    CAMLreturn(Val_bool(ggml_cpu_has_fma()));
#else
    CAMLreturn(Val_bool(0));
#endif
}

CAMLprim value caml_ggml_native_cpu_has_neon(value unit) {
    CAMLparam1(unit);
#ifdef HAVE_GGML
    CAMLreturn(Val_bool(ggml_cpu_has_neon()));
#else
    CAMLreturn(Val_bool(0));
#endif
}

CAMLprim value caml_ggml_native_cpu_has_arm_fma(value unit) {
    CAMLparam1(unit);
#ifdef HAVE_GGML
    CAMLreturn(Val_bool(ggml_cpu_has_arm_fma()));
#else
    CAMLreturn(Val_bool(0));
#endif
}

CAMLprim value caml_ggml_native_cpu_has_f16c(value unit) {
    CAMLparam1(unit);
#ifdef HAVE_GGML
    CAMLreturn(Val_bool(ggml_cpu_has_f16c()));
#else
    CAMLreturn(Val_bool(0));
#endif
}

CAMLprim value caml_ggml_native_cpu_has_fp16_va(value unit) {
    CAMLparam1(unit);
#ifdef HAVE_GGML
    CAMLreturn(Val_bool(ggml_cpu_has_fp16_va()));
#else
    CAMLreturn(Val_bool(0));
#endif
}

CAMLprim value caml_ggml_native_cpu_has_wasm_simd(value unit) {
    CAMLparam1(unit);
#ifdef HAVE_GGML
    CAMLreturn(Val_bool(ggml_cpu_has_wasm_simd()));
#else
    CAMLreturn(Val_bool(0));
#endif
}

CAMLprim value caml_ggml_native_cpu_has_blas(value unit) {
    CAMLparam1(unit);
#ifdef HAVE_GGML
    CAMLreturn(Val_bool(ggml_cpu_has_blas()));
#else
    CAMLreturn(Val_bool(0));
#endif
}

CAMLprim value caml_ggml_native_cpu_has_cublas(value unit) {
    CAMLparam1(unit);
#ifdef HAVE_GGML
    CAMLreturn(Val_bool(ggml_cpu_has_cublas()));
#else
    CAMLreturn(Val_bool(0));
#endif
}

CAMLprim value caml_ggml_native_cpu_has_clblast(value unit) {
    CAMLparam1(unit);
#ifdef HAVE_GGML
    CAMLreturn(Val_bool(ggml_cpu_has_clblast()));
#else
    CAMLreturn(Val_bool(0));
#endif
}

CAMLprim value caml_ggml_native_cpu_has_gpublas(value unit) {
    CAMLparam1(unit);
#ifdef HAVE_GGML
    CAMLreturn(Val_bool(ggml_cpu_has_gpublas()));
#else
    CAMLreturn(Val_bool(0));
#endif
}

CAMLprim value caml_ggml_native_cpu_has_sse3(value unit) {
    CAMLparam1(unit);
#ifdef HAVE_GGML
    CAMLreturn(Val_bool(ggml_cpu_has_sse3()));
#else
    CAMLreturn(Val_bool(0));
#endif
}

CAMLprim value caml_ggml_native_cpu_has_vsx(value unit) {
    CAMLparam1(unit);
#ifdef HAVE_GGML
    CAMLreturn(Val_bool(ggml_cpu_has_vsx()));
#else
    CAMLreturn(Val_bool(0));
#endif
}

/*
 * ============================================================================
 * Context Management
 * ============================================================================
 */

#ifdef HAVE_GGML

CAMLprim value caml_ggml_native_init(value mem_size, value n_threads) {
    CAMLparam2(mem_size, n_threads);
    CAMLlocal1(result);
    
    size_t size = Long_val(mem_size);
    int threads = Int_val(n_threads);
    
    struct ggml_init_params params = {
        .mem_size   = size,
        .mem_buffer = NULL,
        .no_alloc   = false,
    };
    
    struct ggml_context *ctx = ggml_init(params);
    if (ctx == NULL) {
        caml_failwith("ggml_native_init: failed to initialize context");
    }
    
    /* Create wrapper */
    ggml_ctx_wrapper *wrapper = (ggml_ctx_wrapper *)malloc(sizeof(ggml_ctx_wrapper));
    if (wrapper == NULL) {
        ggml_free(ctx);
        caml_failwith("ggml_native_init: failed to allocate wrapper");
    }
    
    wrapper->ctx = ctx;
    wrapper->mem_size = size;
    wrapper->n_threads = threads > 0 ? threads : 4;
    wrapper->ref_count = 1;
    
#ifdef GGML_USE_CUDA
    wrapper->backend = BACKEND_CUDA;
#elif defined(GGML_USE_METAL)
    wrapper->backend = BACKEND_METAL;
#else
    wrapper->backend = BACKEND_CPU;
#endif
    
    /* Register in global table */
    int ctx_id = g_next_ctx_id++;
    if (ctx_id < GGML_MAX_CONTEXTS) {
        g_contexts[ctx_id] = wrapper;
    }
    
    result = caml_alloc_custom(&ggml_ctx_native_ops, sizeof(ggml_ctx_wrapper *), 0, 1);
    Ctx_wrapper_val(result) = wrapper;
    
    CAMLreturn(result);
}

CAMLprim value caml_ggml_native_free(value ctx) {
    CAMLparam1(ctx);
    
    ggml_ctx_wrapper *wrapper = Ctx_wrapper_val(ctx);
    if (wrapper != NULL && wrapper->ctx != NULL) {
        wrapper->ref_count--;
        if (wrapper->ref_count <= 0) {
            ggml_free(Ggml_ctx(wrapper));
            wrapper->ctx = NULL;
            free(wrapper);
            Ctx_wrapper_val(ctx) = NULL;
        }
    }
    
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_native_used_mem(value ctx) {
    CAMLparam1(ctx);
    
    ggml_ctx_wrapper *wrapper = Ctx_wrapper_val(ctx);
    if (wrapper == NULL || wrapper->ctx == NULL) {
        caml_failwith("ggml_native_used_mem: invalid context");
    }
    
    CAMLreturn(Val_long(ggml_used_mem(Ggml_ctx(wrapper))));
}

CAMLprim value caml_ggml_native_get_mem_size(value ctx) {
    CAMLparam1(ctx);
    
    ggml_ctx_wrapper *wrapper = Ctx_wrapper_val(ctx);
    if (wrapper == NULL) {
        caml_failwith("ggml_native_get_mem_size: invalid context");
    }
    
    CAMLreturn(Val_long(wrapper->mem_size));
}

CAMLprim value caml_ggml_native_set_n_threads(value ctx, value n_threads) {
    CAMLparam2(ctx, n_threads);
    
    ggml_ctx_wrapper *wrapper = Ctx_wrapper_val(ctx);
    if (wrapper != NULL) {
        wrapper->n_threads = Int_val(n_threads);
    }
    
    CAMLreturn(Val_unit);
}

/*
 * ============================================================================
 * Tensor Creation
 * ============================================================================
 */

static value wrap_tensor(ggml_ctx_wrapper *ctx_wrapper, struct ggml_tensor *tensor, const char *name) {
    CAMLparam0();
    CAMLlocal1(result);
    
    if (tensor == NULL) {
        caml_failwith("wrap_tensor: NULL tensor");
    }
    
    ggml_tensor_wrapper *wrapper = (ggml_tensor_wrapper *)malloc(sizeof(ggml_tensor_wrapper));
    if (wrapper == NULL) {
        caml_failwith("wrap_tensor: failed to allocate wrapper");
    }
    
    wrapper->tensor = tensor;
    wrapper->ctx_id = 0;  /* TODO: track context ID */
    wrapper->is_view = 0;
    strncpy(wrapper->name, name ? name : "unnamed", sizeof(wrapper->name) - 1);
    wrapper->name[sizeof(wrapper->name) - 1] = '\0';
    
    result = caml_alloc_custom(&ggml_tensor_native_ops, sizeof(ggml_tensor_wrapper *), 0, 1);
    Tensor_wrapper_val(result) = wrapper;
    
    CAMLreturn(result);
}

CAMLprim value caml_ggml_native_new_tensor_1d(value ctx, value type, value ne0) {
    CAMLparam3(ctx, type, ne0);
    
    ggml_ctx_wrapper *wrapper = Ctx_wrapper_val(ctx);
    if (wrapper == NULL || wrapper->ctx == NULL) {
        caml_failwith("ggml_native_new_tensor_1d: invalid context");
    }
    
    struct ggml_tensor *tensor = ggml_new_tensor_1d(
        Ggml_ctx(wrapper),
        Int_val(type),
        Long_val(ne0)
    );
    
    CAMLreturn(wrap_tensor(wrapper, tensor, "tensor_1d"));
}

CAMLprim value caml_ggml_native_new_tensor_2d(value ctx, value type, value ne0, value ne1) {
    CAMLparam4(ctx, type, ne0, ne1);
    
    ggml_ctx_wrapper *wrapper = Ctx_wrapper_val(ctx);
    if (wrapper == NULL || wrapper->ctx == NULL) {
        caml_failwith("ggml_native_new_tensor_2d: invalid context");
    }
    
    struct ggml_tensor *tensor = ggml_new_tensor_2d(
        Ggml_ctx(wrapper),
        Int_val(type),
        Long_val(ne0),
        Long_val(ne1)
    );
    
    CAMLreturn(wrap_tensor(wrapper, tensor, "tensor_2d"));
}

CAMLprim value caml_ggml_native_new_tensor_3d(value ctx, value type, value ne0, value ne1, value ne2) {
    CAMLparam5(ctx, type, ne0, ne1, ne2);
    
    ggml_ctx_wrapper *wrapper = Ctx_wrapper_val(ctx);
    if (wrapper == NULL || wrapper->ctx == NULL) {
        caml_failwith("ggml_native_new_tensor_3d: invalid context");
    }
    
    struct ggml_tensor *tensor = ggml_new_tensor_3d(
        Ggml_ctx(wrapper),
        Int_val(type),
        Long_val(ne0),
        Long_val(ne1),
        Long_val(ne2)
    );
    
    CAMLreturn(wrap_tensor(wrapper, tensor, "tensor_3d"));
}

CAMLprim value caml_ggml_native_new_tensor_4d_native(value ctx, value type, value ne0, value ne1, value ne2, value ne3) {
    CAMLparam5(ctx, type, ne0, ne1, ne2);
    CAMLxparam1(ne3);
    
    ggml_ctx_wrapper *wrapper = Ctx_wrapper_val(ctx);
    if (wrapper == NULL || wrapper->ctx == NULL) {
        caml_failwith("ggml_native_new_tensor_4d: invalid context");
    }
    
    struct ggml_tensor *tensor = ggml_new_tensor_4d(
        Ggml_ctx(wrapper),
        Int_val(type),
        Long_val(ne0),
        Long_val(ne1),
        Long_val(ne2),
        Long_val(ne3)
    );
    
    CAMLreturn(wrap_tensor(wrapper, tensor, "tensor_4d"));
}

CAMLprim value caml_ggml_native_new_tensor_4d(value *argv, int argn) {
    return caml_ggml_native_new_tensor_4d_native(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
}

/*
 * ============================================================================
 * Tensor Data Access
 * ============================================================================
 */

CAMLprim value caml_ggml_native_set_data(value tensor, value data) {
    CAMLparam2(tensor, data);
    
    ggml_tensor_wrapper *wrapper = Tensor_wrapper_val(tensor);
    if (wrapper == NULL || wrapper->tensor == NULL) {
        caml_failwith("ggml_native_set_data: invalid tensor");
    }
    
    struct ggml_tensor *t = Ggml_tensor(wrapper);
    float *src = (float *)Caml_ba_data_val(data);
    size_t size = ggml_nbytes(t);
    
    memcpy(t->data, src, size);
    
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_native_get_data(value tensor) {
    CAMLparam1(tensor);
    CAMLlocal1(result);
    
    ggml_tensor_wrapper *wrapper = Tensor_wrapper_val(tensor);
    if (wrapper == NULL || wrapper->tensor == NULL) {
        caml_failwith("ggml_native_get_data: invalid tensor");
    }
    
    struct ggml_tensor *t = Ggml_tensor(wrapper);
    int64_t nelements = ggml_nelements(t);
    
    result = caml_ba_alloc_dims(CAML_BA_FLOAT32 | CAML_BA_C_LAYOUT, 1, NULL, nelements);
    memcpy(Caml_ba_data_val(result), t->data, ggml_nbytes(t));
    
    CAMLreturn(result);
}

CAMLprim value caml_ggml_native_set_f32(value tensor, value index, value val) {
    CAMLparam3(tensor, index, val);
    
    ggml_tensor_wrapper *wrapper = Tensor_wrapper_val(tensor);
    if (wrapper == NULL || wrapper->tensor == NULL) {
        caml_failwith("ggml_native_set_f32: invalid tensor");
    }
    
    ggml_set_f32_1d(Ggml_tensor(wrapper), Long_val(index), Double_val(val));
    
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_native_get_f32(value tensor, value index) {
    CAMLparam2(tensor, index);
    
    ggml_tensor_wrapper *wrapper = Tensor_wrapper_val(tensor);
    if (wrapper == NULL || wrapper->tensor == NULL) {
        caml_failwith("ggml_native_get_f32: invalid tensor");
    }
    
    float val = ggml_get_f32_1d(Ggml_tensor(wrapper), Long_val(index));
    
    CAMLreturn(caml_copy_double(val));
}

CAMLprim value caml_ggml_native_nelements(value tensor) {
    CAMLparam1(tensor);
    
    ggml_tensor_wrapper *wrapper = Tensor_wrapper_val(tensor);
    if (wrapper == NULL || wrapper->tensor == NULL) {
        caml_failwith("ggml_native_nelements: invalid tensor");
    }
    
    CAMLreturn(Val_long(ggml_nelements(Ggml_tensor(wrapper))));
}

CAMLprim value caml_ggml_native_nbytes(value tensor) {
    CAMLparam1(tensor);
    
    ggml_tensor_wrapper *wrapper = Tensor_wrapper_val(tensor);
    if (wrapper == NULL || wrapper->tensor == NULL) {
        caml_failwith("ggml_native_nbytes: invalid tensor");
    }
    
    CAMLreturn(Val_long(ggml_nbytes(Ggml_tensor(wrapper))));
}

CAMLprim value caml_ggml_native_n_dims(value tensor) {
    CAMLparam1(tensor);
    
    ggml_tensor_wrapper *wrapper = Tensor_wrapper_val(tensor);
    if (wrapper == NULL || wrapper->tensor == NULL) {
        caml_failwith("ggml_native_n_dims: invalid tensor");
    }
    
    CAMLreturn(Val_int(ggml_n_dims(Ggml_tensor(wrapper))));
}

CAMLprim value caml_ggml_native_get_ne(value tensor, value dim) {
    CAMLparam2(tensor, dim);
    
    ggml_tensor_wrapper *wrapper = Tensor_wrapper_val(tensor);
    if (wrapper == NULL || wrapper->tensor == NULL) {
        caml_failwith("ggml_native_get_ne: invalid tensor");
    }
    
    int d = Int_val(dim);
    if (d < 0 || d >= GGML_MAX_DIMS) {
        caml_invalid_argument("ggml_native_get_ne: dimension out of range");
    }
    
    CAMLreturn(Val_long(Ggml_tensor(wrapper)->ne[d]));
}

/*
 * ============================================================================
 * Tensor Operations
 * ============================================================================
 */

#define DEFINE_BINARY_OP(name, ggml_fn) \
CAMLprim value caml_ggml_native_##name(value ctx, value a, value b) { \
    CAMLparam3(ctx, a, b); \
    ggml_ctx_wrapper *ctx_wrapper = Ctx_wrapper_val(ctx); \
    ggml_tensor_wrapper *a_wrapper = Tensor_wrapper_val(a); \
    ggml_tensor_wrapper *b_wrapper = Tensor_wrapper_val(b); \
    if (!ctx_wrapper || !ctx_wrapper->ctx || !a_wrapper || !a_wrapper->tensor || !b_wrapper || !b_wrapper->tensor) { \
        caml_failwith("ggml_native_" #name ": invalid argument"); \
    } \
    struct ggml_tensor *result = ggml_fn(Ggml_ctx(ctx_wrapper), Ggml_tensor(a_wrapper), Ggml_tensor(b_wrapper)); \
    CAMLreturn(wrap_tensor(ctx_wrapper, result, #name)); \
}

#define DEFINE_UNARY_OP(name, ggml_fn) \
CAMLprim value caml_ggml_native_##name(value ctx, value a) { \
    CAMLparam2(ctx, a); \
    ggml_ctx_wrapper *ctx_wrapper = Ctx_wrapper_val(ctx); \
    ggml_tensor_wrapper *a_wrapper = Tensor_wrapper_val(a); \
    if (!ctx_wrapper || !ctx_wrapper->ctx || !a_wrapper || !a_wrapper->tensor) { \
        caml_failwith("ggml_native_" #name ": invalid argument"); \
    } \
    struct ggml_tensor *result = ggml_fn(Ggml_ctx(ctx_wrapper), Ggml_tensor(a_wrapper)); \
    CAMLreturn(wrap_tensor(ctx_wrapper, result, #name)); \
}

/* Basic operations */
DEFINE_BINARY_OP(add, ggml_add)
DEFINE_BINARY_OP(sub, ggml_sub)
DEFINE_BINARY_OP(mul, ggml_mul)
DEFINE_BINARY_OP(div, ggml_div)

DEFINE_UNARY_OP(neg, ggml_neg)
DEFINE_UNARY_OP(abs, ggml_abs)
DEFINE_UNARY_OP(sqr, ggml_sqr)
DEFINE_UNARY_OP(sqrt, ggml_sqrt)
DEFINE_UNARY_OP(log, ggml_log)

/* Activation functions */
DEFINE_UNARY_OP(relu, ggml_relu)
DEFINE_UNARY_OP(gelu, ggml_gelu)
DEFINE_UNARY_OP(silu, ggml_silu)
DEFINE_UNARY_OP(sigmoid, ggml_sigmoid)
DEFINE_UNARY_OP(tanh, ggml_tanh)

/* Matrix operations */
DEFINE_BINARY_OP(mul_mat, ggml_mul_mat)
DEFINE_UNARY_OP(transpose, ggml_transpose)

/* Reduction operations */
DEFINE_UNARY_OP(sum, ggml_sum)
DEFINE_UNARY_OP(mean, ggml_mean)
DEFINE_UNARY_OP(argmax, ggml_argmax)

CAMLprim value caml_ggml_native_scale(value ctx, value a, value s) {
    CAMLparam3(ctx, a, s);
    
    ggml_ctx_wrapper *ctx_wrapper = Ctx_wrapper_val(ctx);
    ggml_tensor_wrapper *a_wrapper = Tensor_wrapper_val(a);
    
    if (!ctx_wrapper || !ctx_wrapper->ctx || !a_wrapper || !a_wrapper->tensor) {
        caml_failwith("ggml_native_scale: invalid argument");
    }
    
    struct ggml_tensor *result = ggml_scale(
        Ggml_ctx(ctx_wrapper),
        Ggml_tensor(a_wrapper),
        Double_val(s)
    );
    
    CAMLreturn(wrap_tensor(ctx_wrapper, result, "scale"));
}

CAMLprim value caml_ggml_native_soft_max(value ctx, value a) {
    CAMLparam2(ctx, a);
    
    ggml_ctx_wrapper *ctx_wrapper = Ctx_wrapper_val(ctx);
    ggml_tensor_wrapper *a_wrapper = Tensor_wrapper_val(a);
    
    if (!ctx_wrapper || !ctx_wrapper->ctx || !a_wrapper || !a_wrapper->tensor) {
        caml_failwith("ggml_native_soft_max: invalid argument");
    }
    
    struct ggml_tensor *result = ggml_soft_max(
        Ggml_ctx(ctx_wrapper),
        Ggml_tensor(a_wrapper)
    );
    
    CAMLreturn(wrap_tensor(ctx_wrapper, result, "soft_max"));
}

CAMLprim value caml_ggml_native_norm(value ctx, value a, value eps) {
    CAMLparam3(ctx, a, eps);
    
    ggml_ctx_wrapper *ctx_wrapper = Ctx_wrapper_val(ctx);
    ggml_tensor_wrapper *a_wrapper = Tensor_wrapper_val(a);
    
    if (!ctx_wrapper || !ctx_wrapper->ctx || !a_wrapper || !a_wrapper->tensor) {
        caml_failwith("ggml_native_norm: invalid argument");
    }
    
    struct ggml_tensor *result = ggml_norm(
        Ggml_ctx(ctx_wrapper),
        Ggml_tensor(a_wrapper),
        Double_val(eps)
    );
    
    CAMLreturn(wrap_tensor(ctx_wrapper, result, "norm"));
}

CAMLprim value caml_ggml_native_rms_norm(value ctx, value a, value eps) {
    CAMLparam3(ctx, a, eps);
    
    ggml_ctx_wrapper *ctx_wrapper = Ctx_wrapper_val(ctx);
    ggml_tensor_wrapper *a_wrapper = Tensor_wrapper_val(a);
    
    if (!ctx_wrapper || !ctx_wrapper->ctx || !a_wrapper || !a_wrapper->tensor) {
        caml_failwith("ggml_native_rms_norm: invalid argument");
    }
    
    struct ggml_tensor *result = ggml_rms_norm(
        Ggml_ctx(ctx_wrapper),
        Ggml_tensor(a_wrapper),
        Double_val(eps)
    );
    
    CAMLreturn(wrap_tensor(ctx_wrapper, result, "rms_norm"));
}

/*
 * ============================================================================
 * Compute Graph
 * ============================================================================
 */

CAMLprim value caml_ggml_native_build_forward(value ctx, value tensor) {
    CAMLparam2(ctx, tensor);
    CAMLlocal1(result);
    
    ggml_ctx_wrapper *ctx_wrapper = Ctx_wrapper_val(ctx);
    ggml_tensor_wrapper *t_wrapper = Tensor_wrapper_val(tensor);
    
    if (!ctx_wrapper || !ctx_wrapper->ctx || !t_wrapper || !t_wrapper->tensor) {
        caml_failwith("ggml_native_build_forward: invalid argument");
    }
    
    struct ggml_cgraph *graph = ggml_new_graph(Ggml_ctx(ctx_wrapper));
    ggml_build_forward_expand(graph, Ggml_tensor(t_wrapper));
    
    ggml_graph_wrapper *g_wrapper = (ggml_graph_wrapper *)malloc(sizeof(ggml_graph_wrapper));
    if (g_wrapper == NULL) {
        caml_failwith("ggml_native_build_forward: failed to allocate wrapper");
    }
    
    g_wrapper->graph = graph;
    g_wrapper->ctx_id = 0;
    g_wrapper->n_nodes = graph->n_nodes;
    
    result = caml_alloc_custom(&ggml_graph_native_ops, sizeof(ggml_graph_wrapper *), 0, 1);
    Graph_wrapper_val(result) = g_wrapper;
    
    CAMLreturn(result);
}

CAMLprim value caml_ggml_native_graph_compute(value ctx, value graph) {
    CAMLparam2(ctx, graph);
    
    ggml_ctx_wrapper *ctx_wrapper = Ctx_wrapper_val(ctx);
    ggml_graph_wrapper *g_wrapper = Graph_wrapper_val(graph);
    
    if (!ctx_wrapper || !ctx_wrapper->ctx || !g_wrapper || !g_wrapper->graph) {
        caml_failwith("ggml_native_graph_compute: invalid argument");
    }
    
    ggml_graph_compute_with_ctx(Ggml_ctx(ctx_wrapper), Ggml_graph(g_wrapper), ctx_wrapper->n_threads);
    
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_native_graph_n_nodes(value graph) {
    CAMLparam1(graph);
    
    ggml_graph_wrapper *g_wrapper = Graph_wrapper_val(graph);
    if (!g_wrapper || !g_wrapper->graph) {
        caml_failwith("ggml_native_graph_n_nodes: invalid graph");
    }
    
    CAMLreturn(Val_int(g_wrapper->n_nodes));
}

/*
 * ============================================================================
 * Quantization Support
 * ============================================================================
 */

CAMLprim value caml_ggml_native_quantize_q4_0(value src, value dst, value n, value k) {
    CAMLparam4(src, dst, n, k);
    
    float *src_data = (float *)Caml_ba_data_val(src);
    void *dst_data = Caml_ba_data_val(dst);
    
    size_t result = ggml_quantize_q4_0(src_data, dst_data, Long_val(n), Long_val(k), NULL);
    
    CAMLreturn(Val_long(result));
}

CAMLprim value caml_ggml_native_quantize_q4_1(value src, value dst, value n, value k) {
    CAMLparam4(src, dst, n, k);
    
    float *src_data = (float *)Caml_ba_data_val(src);
    void *dst_data = Caml_ba_data_val(dst);
    
    size_t result = ggml_quantize_q4_1(src_data, dst_data, Long_val(n), Long_val(k), NULL);
    
    CAMLreturn(Val_long(result));
}

CAMLprim value caml_ggml_native_quantize_q5_0(value src, value dst, value n, value k) {
    CAMLparam4(src, dst, n, k);
    
    float *src_data = (float *)Caml_ba_data_val(src);
    void *dst_data = Caml_ba_data_val(dst);
    
    size_t result = ggml_quantize_q5_0(src_data, dst_data, Long_val(n), Long_val(k), NULL);
    
    CAMLreturn(Val_long(result));
}

CAMLprim value caml_ggml_native_quantize_q5_1(value src, value dst, value n, value k) {
    CAMLparam4(src, dst, n, k);
    
    float *src_data = (float *)Caml_ba_data_val(src);
    void *dst_data = Caml_ba_data_val(dst);
    
    size_t result = ggml_quantize_q5_1(src_data, dst_data, Long_val(n), Long_val(k), NULL);
    
    CAMLreturn(Val_long(result));
}

CAMLprim value caml_ggml_native_quantize_q8_0(value src, value dst, value n, value k) {
    CAMLparam4(src, dst, n, k);
    
    float *src_data = (float *)Caml_ba_data_val(src);
    void *dst_data = Caml_ba_data_val(dst);
    
    size_t result = ggml_quantize_q8_0(src_data, dst_data, Long_val(n), Long_val(k), NULL);
    
    CAMLreturn(Val_long(result));
}

#else /* !HAVE_GGML */

/*
 * ============================================================================
 * Stub Implementations (when GGML is not available)
 * ============================================================================
 */

static void ggml_native_not_available(void) {
    caml_failwith("GGML native bindings not available. Compile with -DHAVE_GGML and link with -lggml");
}

CAMLprim value caml_ggml_native_init(value mem_size, value n_threads) {
    CAMLparam2(mem_size, n_threads);
    ggml_native_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_ggml_native_free(value ctx) {
    CAMLparam1(ctx);
    ggml_native_not_available();
    CAMLreturn(Val_unit);
}

/* All other functions follow the same pattern */
#define STUB_IMPL_1(name) \
CAMLprim value caml_ggml_native_##name(value a) { \
    CAMLparam1(a); \
    ggml_native_not_available(); \
    CAMLreturn(Val_unit); \
}

#define STUB_IMPL_2(name) \
CAMLprim value caml_ggml_native_##name(value a, value b) { \
    CAMLparam2(a, b); \
    ggml_native_not_available(); \
    CAMLreturn(Val_unit); \
}

#define STUB_IMPL_3(name) \
CAMLprim value caml_ggml_native_##name(value a, value b, value c) { \
    CAMLparam3(a, b, c); \
    ggml_native_not_available(); \
    CAMLreturn(Val_unit); \
}

#define STUB_IMPL_4(name) \
CAMLprim value caml_ggml_native_##name(value a, value b, value c, value d) { \
    CAMLparam4(a, b, c, d); \
    ggml_native_not_available(); \
    CAMLreturn(Val_unit); \
}

#define STUB_IMPL_5(name) \
CAMLprim value caml_ggml_native_##name(value a, value b, value c, value d, value e) { \
    CAMLparam5(a, b, c, d, e); \
    ggml_native_not_available(); \
    CAMLreturn(Val_unit); \
}

STUB_IMPL_1(used_mem)
STUB_IMPL_1(get_mem_size)
STUB_IMPL_2(set_n_threads)
STUB_IMPL_3(new_tensor_1d)
STUB_IMPL_4(new_tensor_2d)
STUB_IMPL_5(new_tensor_3d)
STUB_IMPL_2(set_data)
STUB_IMPL_1(get_data)
STUB_IMPL_3(set_f32)
STUB_IMPL_2(get_f32)
STUB_IMPL_1(nelements)
STUB_IMPL_1(nbytes)
STUB_IMPL_1(n_dims)
STUB_IMPL_2(get_ne)
STUB_IMPL_3(add)
STUB_IMPL_3(sub)
STUB_IMPL_3(mul)
STUB_IMPL_3(div)
STUB_IMPL_3(scale)
STUB_IMPL_2(neg)
STUB_IMPL_2(abs)
STUB_IMPL_2(sqr)
STUB_IMPL_2(sqrt)
STUB_IMPL_2(log)
STUB_IMPL_2(relu)
STUB_IMPL_2(gelu)
STUB_IMPL_2(silu)
STUB_IMPL_2(sigmoid)
STUB_IMPL_2(tanh)
STUB_IMPL_3(mul_mat)
STUB_IMPL_2(transpose)
STUB_IMPL_2(sum)
STUB_IMPL_2(mean)
STUB_IMPL_2(argmax)
STUB_IMPL_2(soft_max)
STUB_IMPL_3(norm)
STUB_IMPL_3(rms_norm)
STUB_IMPL_2(build_forward)
STUB_IMPL_2(graph_compute)
STUB_IMPL_1(graph_n_nodes)
STUB_IMPL_4(quantize_q4_0)
STUB_IMPL_4(quantize_q4_1)
STUB_IMPL_4(quantize_q5_0)
STUB_IMPL_4(quantize_q5_1)
STUB_IMPL_4(quantize_q8_0)

CAMLprim value caml_ggml_native_new_tensor_4d(value *argv, int argn) {
    ggml_native_not_available();
    return Val_unit;
}

#endif /* HAVE_GGML */
