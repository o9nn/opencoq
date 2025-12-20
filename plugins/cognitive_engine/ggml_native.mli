(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** GGML Native Bindings Interface *)

(** {1 Types} *)

(** Backend types *)
type backend =
  | CPU
  | CUDA
  | Metal
  | Vulkan
  | Stub

(** Data types for tensors *)
type dtype =
  | F32
  | F16
  | Q4_0
  | Q4_1
  | Q5_0
  | Q5_1
  | Q8_0
  | Q8_1
  | I8
  | I16
  | I32

(** Opaque context type *)
type context

(** Opaque tensor type *)
type tensor

(** Opaque compute graph type *)
type cgraph

(** {1 Backend Detection} *)

(** Get current backend *)
val get_backend : unit -> backend

(** Get backend name as string *)
val backend_name : unit -> string

(** Check if native GGML is available *)
val is_native_available : unit -> bool

(** {1 CPU Feature Detection} *)

type cpu_features = {
  avx: bool;
  avx2: bool;
  avx512: bool;
  avx512_vbmi: bool;
  avx512_vnni: bool;
  fma: bool;
  neon: bool;
  arm_fma: bool;
  f16c: bool;
  fp16_va: bool;
  wasm_simd: bool;
  blas: bool;
  cublas: bool;
  clblast: bool;
  gpublas: bool;
  sse3: bool;
  vsx: bool;
}

(** Detect CPU features *)
val detect_cpu_features : unit -> cpu_features

(** Individual feature checks *)
val cpu_has_avx : unit -> bool
val cpu_has_avx2 : unit -> bool
val cpu_has_avx512 : unit -> bool
val cpu_has_fma : unit -> bool
val cpu_has_neon : unit -> bool
val cpu_has_blas : unit -> bool
val cpu_has_cublas : unit -> bool

(** {1 Context Management} *)

(** Create a new GGML context *)
val create_context : ?mem_size:int -> ?n_threads:int -> unit -> context

(** Initialize context (low-level) *)
val init : int -> int -> context

(** Free context *)
val free : context -> unit

(** Get used memory in context *)
val used_mem : context -> int

(** Get total memory size of context *)
val get_mem_size : context -> int

(** Set number of threads for computation *)
val set_n_threads : context -> int -> unit

(** {1 Data Type Utilities} *)

(** Convert dtype to integer code *)
val dtype_to_int : dtype -> int

(** Convert integer code to dtype *)
val int_to_dtype : int -> dtype

(** Get dtype name as string *)
val dtype_name : dtype -> string

(** {1 Tensor Creation} *)

(** Create 1D tensor *)
val new_tensor_1d : context -> ?dtype:dtype -> int -> tensor

(** Create 2D tensor *)
val new_tensor_2d : context -> ?dtype:dtype -> int -> int -> tensor

(** Create 3D tensor *)
val new_tensor_3d : context -> ?dtype:dtype -> int -> int -> int -> tensor

(** Create 4D tensor *)
val new_tensor_4d : context -> ?dtype:dtype -> int -> int -> int -> int -> tensor

(** {1 Tensor Data Access} *)

(** Set tensor data from bigarray *)
val set_data : tensor -> (float, Bigarray.float32_elt, Bigarray.c_layout) Bigarray.Array1.t -> unit

(** Get tensor data as bigarray *)
val get_data : tensor -> (float, Bigarray.float32_elt, Bigarray.c_layout) Bigarray.Array1.t

(** Set single float value *)
val set_f32 : tensor -> int -> float -> unit

(** Get single float value *)
val get_f32 : tensor -> int -> float

(** Get number of elements *)
val nelements : tensor -> int

(** Get number of bytes *)
val nbytes : tensor -> int

(** Get number of dimensions *)
val n_dims : tensor -> int

(** Get size of dimension *)
val get_ne : tensor -> int -> int

(** Get tensor shape as array *)
val shape : tensor -> int array

(** Set data from float array *)
val set_data_from_array : tensor -> float array -> unit

(** Get data as float array *)
val get_data_as_array : tensor -> float array

(** {1 Basic Operations} *)

val add : context -> tensor -> tensor -> tensor
val sub : context -> tensor -> tensor -> tensor
val mul : context -> tensor -> tensor -> tensor
val div : context -> tensor -> tensor -> tensor
val scale : context -> tensor -> float -> tensor
val neg : context -> tensor -> tensor
val abs : context -> tensor -> tensor
val sqr : context -> tensor -> tensor
val sqrt : context -> tensor -> tensor
val log : context -> tensor -> tensor

(** {1 Activation Functions} *)

val relu : context -> tensor -> tensor
val gelu : context -> tensor -> tensor
val silu : context -> tensor -> tensor
val sigmoid : context -> tensor -> tensor
val tanh : context -> tensor -> tensor

(** {1 Matrix Operations} *)

val mul_mat : context -> tensor -> tensor -> tensor
val transpose : context -> tensor -> tensor

(** {1 Reduction Operations} *)

val sum : context -> tensor -> tensor
val mean : context -> tensor -> tensor
val argmax : context -> tensor -> tensor

(** {1 Normalization} *)

val soft_max : context -> tensor -> tensor
val norm : context -> tensor -> float -> tensor
val rms_norm : context -> tensor -> float -> tensor
val layer_norm : context -> tensor -> ?eps:float -> unit -> tensor
val rms_layer_norm : context -> tensor -> ?eps:float -> unit -> tensor

(** {1 Compute Graph} *)

(** Build forward compute graph *)
val build_forward : context -> tensor -> cgraph

(** Execute compute graph *)
val graph_compute : context -> cgraph -> unit

(** Get number of nodes in graph *)
val graph_n_nodes : cgraph -> int

(** Compute tensor (build graph and execute) *)
val compute : context -> tensor -> tensor

(** {1 Quantization} *)

val quantize_q4_0 : (float, Bigarray.float32_elt, Bigarray.c_layout) Bigarray.Array1.t -> 
                    (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t -> 
                    int -> int -> int

val quantize_q4_1 : (float, Bigarray.float32_elt, Bigarray.c_layout) Bigarray.Array1.t -> 
                    (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t -> 
                    int -> int -> int

val quantize_q5_0 : (float, Bigarray.float32_elt, Bigarray.c_layout) Bigarray.Array1.t -> 
                    (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t -> 
                    int -> int -> int

val quantize_q5_1 : (float, Bigarray.float32_elt, Bigarray.c_layout) Bigarray.Array1.t -> 
                    (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t -> 
                    int -> int -> int

val quantize_q8_0 : (float, Bigarray.float32_elt, Bigarray.c_layout) Bigarray.Array1.t -> 
                    (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t -> 
                    int -> int -> int

(** {1 High-Level Operations} *)

(** Linear layer: y = x @ W^T + b *)
val linear : context -> tensor -> tensor -> ?bias:tensor -> unit -> tensor

(** Multi-head attention *)
val attention : context -> tensor -> tensor -> tensor -> ?scale_factor:float option -> unit -> tensor

(** {1 Utility Functions} *)

(** Print tensor information *)
val print_tensor_info : tensor -> unit

(** Print backend information *)
val print_backend_info : unit -> unit

(** {1 Scheme Serialization} *)

val backend_to_scheme : backend -> string
val cpu_features_to_scheme : cpu_features -> string
val tensor_to_scheme : tensor -> string
