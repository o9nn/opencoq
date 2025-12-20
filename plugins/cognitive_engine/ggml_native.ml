(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** GGML Native Bindings for OCaml
    
    This module provides complete native bindings to the GGML library,
    including tensor operations, backend selection, quantization, and
    compute graph execution.
    
    When compiled with HAVE_GGML, these functions call the actual GGML
    library. Otherwise, they raise exceptions.
*)

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

external backend_type : unit -> int = "caml_ggml_native_backend_type"
external backend_name : unit -> string = "caml_ggml_native_backend_name"

let get_backend () =
  match backend_type () with
  | 0 -> CPU
  | 1 -> CUDA
  | 2 -> Metal
  | 3 -> Vulkan
  | _ -> Stub

let is_native_available () =
  get_backend () <> Stub

(** {1 CPU Feature Detection} *)

external cpu_has_avx : unit -> bool = "caml_ggml_native_cpu_has_avx"
external cpu_has_avx2 : unit -> bool = "caml_ggml_native_cpu_has_avx2"
external cpu_has_avx512 : unit -> bool = "caml_ggml_native_cpu_has_avx512"
external cpu_has_avx512_vbmi : unit -> bool = "caml_ggml_native_cpu_has_avx512_vbmi"
external cpu_has_avx512_vnni : unit -> bool = "caml_ggml_native_cpu_has_avx512_vnni"
external cpu_has_fma : unit -> bool = "caml_ggml_native_cpu_has_fma"
external cpu_has_neon : unit -> bool = "caml_ggml_native_cpu_has_neon"
external cpu_has_arm_fma : unit -> bool = "caml_ggml_native_cpu_has_arm_fma"
external cpu_has_f16c : unit -> bool = "caml_ggml_native_cpu_has_f16c"
external cpu_has_fp16_va : unit -> bool = "caml_ggml_native_cpu_has_fp16_va"
external cpu_has_wasm_simd : unit -> bool = "caml_ggml_native_cpu_has_wasm_simd"
external cpu_has_blas : unit -> bool = "caml_ggml_native_cpu_has_blas"
external cpu_has_cublas : unit -> bool = "caml_ggml_native_cpu_has_cublas"
external cpu_has_clblast : unit -> bool = "caml_ggml_native_cpu_has_clblast"
external cpu_has_gpublas : unit -> bool = "caml_ggml_native_cpu_has_gpublas"
external cpu_has_sse3 : unit -> bool = "caml_ggml_native_cpu_has_sse3"
external cpu_has_vsx : unit -> bool = "caml_ggml_native_cpu_has_vsx"

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

let detect_cpu_features () = {
  avx = cpu_has_avx ();
  avx2 = cpu_has_avx2 ();
  avx512 = cpu_has_avx512 ();
  avx512_vbmi = cpu_has_avx512_vbmi ();
  avx512_vnni = cpu_has_avx512_vnni ();
  fma = cpu_has_fma ();
  neon = cpu_has_neon ();
  arm_fma = cpu_has_arm_fma ();
  f16c = cpu_has_f16c ();
  fp16_va = cpu_has_fp16_va ();
  wasm_simd = cpu_has_wasm_simd ();
  blas = cpu_has_blas ();
  cublas = cpu_has_cublas ();
  clblast = cpu_has_clblast ();
  gpublas = cpu_has_gpublas ();
  sse3 = cpu_has_sse3 ();
  vsx = cpu_has_vsx ();
}

(** {1 Context Management} *)

external init : int -> int -> context = "caml_ggml_native_init"
external free : context -> unit = "caml_ggml_native_free"
external used_mem : context -> int = "caml_ggml_native_used_mem"
external get_mem_size : context -> int = "caml_ggml_native_get_mem_size"
external set_n_threads : context -> int -> unit = "caml_ggml_native_set_n_threads"

let create_context ?(mem_size=128*1024*1024) ?(n_threads=4) () =
  init mem_size n_threads

(** {1 Data Type Conversion} *)

let dtype_to_int = function
  | F32 -> 0
  | F16 -> 1
  | Q4_0 -> 2
  | Q4_1 -> 3
  | Q5_0 -> 6
  | Q5_1 -> 7
  | Q8_0 -> 8
  | Q8_1 -> 9
  | I8 -> 16
  | I16 -> 17
  | I32 -> 18

let int_to_dtype = function
  | 0 -> F32
  | 1 -> F16
  | 2 -> Q4_0
  | 3 -> Q4_1
  | 6 -> Q5_0
  | 7 -> Q5_1
  | 8 -> Q8_0
  | 9 -> Q8_1
  | 16 -> I8
  | 17 -> I16
  | 18 -> I32
  | _ -> F32

let dtype_name = function
  | F32 -> "f32"
  | F16 -> "f16"
  | Q4_0 -> "q4_0"
  | Q4_1 -> "q4_1"
  | Q5_0 -> "q5_0"
  | Q5_1 -> "q5_1"
  | Q8_0 -> "q8_0"
  | Q8_1 -> "q8_1"
  | I8 -> "i8"
  | I16 -> "i16"
  | I32 -> "i32"

(** {1 Tensor Creation} *)

external new_tensor_1d_raw : context -> int -> int -> tensor = "caml_ggml_native_new_tensor_1d"
external new_tensor_2d_raw : context -> int -> int -> int -> tensor = "caml_ggml_native_new_tensor_2d"
external new_tensor_3d_raw : context -> int -> int -> int -> int -> tensor = "caml_ggml_native_new_tensor_3d"
external new_tensor_4d_raw : context -> int -> int -> int -> int -> int -> tensor = "caml_ggml_native_new_tensor_4d" "caml_ggml_native_new_tensor_4d"

let new_tensor_1d ctx ?(dtype=F32) ne0 =
  new_tensor_1d_raw ctx (dtype_to_int dtype) ne0

let new_tensor_2d ctx ?(dtype=F32) ne0 ne1 =
  new_tensor_2d_raw ctx (dtype_to_int dtype) ne0 ne1

let new_tensor_3d ctx ?(dtype=F32) ne0 ne1 ne2 =
  new_tensor_3d_raw ctx (dtype_to_int dtype) ne0 ne1 ne2

let new_tensor_4d ctx ?(dtype=F32) ne0 ne1 ne2 ne3 =
  new_tensor_4d_raw ctx (dtype_to_int dtype) ne0 ne1 ne2 ne3

(** {1 Tensor Data Access} *)

external set_data : tensor -> (float, Bigarray.float32_elt, Bigarray.c_layout) Bigarray.Array1.t -> unit = "caml_ggml_native_set_data"
external get_data : tensor -> (float, Bigarray.float32_elt, Bigarray.c_layout) Bigarray.Array1.t = "caml_ggml_native_get_data"
external set_f32 : tensor -> int -> float -> unit = "caml_ggml_native_set_f32"
external get_f32 : tensor -> int -> float = "caml_ggml_native_get_f32"
external nelements : tensor -> int = "caml_ggml_native_nelements"
external nbytes : tensor -> int = "caml_ggml_native_nbytes"
external n_dims : tensor -> int = "caml_ggml_native_n_dims"
external get_ne : tensor -> int -> int = "caml_ggml_native_get_ne"

let shape tensor =
  let dims = n_dims tensor in
  Array.init dims (fun i -> get_ne tensor i)

let set_data_from_array tensor arr =
  let n = nelements tensor in
  let ba = Bigarray.Array1.create Bigarray.float32 Bigarray.c_layout n in
  Array.iteri (fun i v -> Bigarray.Array1.set ba i v) arr;
  set_data tensor ba

let get_data_as_array tensor =
  let ba = get_data tensor in
  Array.init (Bigarray.Array1.dim ba) (fun i -> Bigarray.Array1.get ba i)

(** {1 Tensor Operations} *)

(** Basic operations *)
external add : context -> tensor -> tensor -> tensor = "caml_ggml_native_add"
external sub : context -> tensor -> tensor -> tensor = "caml_ggml_native_sub"
external mul : context -> tensor -> tensor -> tensor = "caml_ggml_native_mul"
external div : context -> tensor -> tensor -> tensor = "caml_ggml_native_div"
external scale : context -> tensor -> float -> tensor = "caml_ggml_native_scale"
external neg : context -> tensor -> tensor = "caml_ggml_native_neg"
external abs : context -> tensor -> tensor = "caml_ggml_native_abs"
external sqr : context -> tensor -> tensor = "caml_ggml_native_sqr"
external sqrt : context -> tensor -> tensor = "caml_ggml_native_sqrt"
external log : context -> tensor -> tensor = "caml_ggml_native_log"

(** Activation functions *)
external relu : context -> tensor -> tensor = "caml_ggml_native_relu"
external gelu : context -> tensor -> tensor = "caml_ggml_native_gelu"
external silu : context -> tensor -> tensor = "caml_ggml_native_silu"
external sigmoid : context -> tensor -> tensor = "caml_ggml_native_sigmoid"
external tanh : context -> tensor -> tensor = "caml_ggml_native_tanh"

(** Matrix operations *)
external mul_mat : context -> tensor -> tensor -> tensor = "caml_ggml_native_mul_mat"
external transpose : context -> tensor -> tensor = "caml_ggml_native_transpose"

(** Reduction operations *)
external sum : context -> tensor -> tensor = "caml_ggml_native_sum"
external mean : context -> tensor -> tensor = "caml_ggml_native_mean"
external argmax : context -> tensor -> tensor = "caml_ggml_native_argmax"

(** Normalization *)
external soft_max : context -> tensor -> tensor = "caml_ggml_native_soft_max"
external norm : context -> tensor -> float -> tensor = "caml_ggml_native_norm"
external rms_norm : context -> tensor -> float -> tensor = "caml_ggml_native_rms_norm"

let layer_norm ctx tensor ?(eps=1e-5) () =
  norm ctx tensor eps

let rms_layer_norm ctx tensor ?(eps=1e-5) () =
  rms_norm ctx tensor eps

(** {1 Compute Graph} *)

external build_forward : context -> tensor -> cgraph = "caml_ggml_native_build_forward"
external graph_compute : context -> cgraph -> unit = "caml_ggml_native_graph_compute"
external graph_n_nodes : cgraph -> int = "caml_ggml_native_graph_n_nodes"

let compute ctx tensor =
  let graph = build_forward ctx tensor in
  graph_compute ctx graph;
  tensor

(** {1 Quantization} *)

external quantize_q4_0 : (float, Bigarray.float32_elt, Bigarray.c_layout) Bigarray.Array1.t -> 
                         (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t -> 
                         int -> int -> int = "caml_ggml_native_quantize_q4_0"

external quantize_q4_1 : (float, Bigarray.float32_elt, Bigarray.c_layout) Bigarray.Array1.t -> 
                         (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t -> 
                         int -> int -> int = "caml_ggml_native_quantize_q4_1"

external quantize_q5_0 : (float, Bigarray.float32_elt, Bigarray.c_layout) Bigarray.Array1.t -> 
                         (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t -> 
                         int -> int -> int = "caml_ggml_native_quantize_q5_0"

external quantize_q5_1 : (float, Bigarray.float32_elt, Bigarray.c_layout) Bigarray.Array1.t -> 
                         (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t -> 
                         int -> int -> int = "caml_ggml_native_quantize_q5_1"

external quantize_q8_0 : (float, Bigarray.float32_elt, Bigarray.c_layout) Bigarray.Array1.t -> 
                         (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t -> 
                         int -> int -> int = "caml_ggml_native_quantize_q8_0"

(** {1 High-Level Operations} *)

(** Linear layer: y = x @ W^T + b *)
let linear ctx x weight ?bias () =
  let y = mul_mat ctx weight x in
  match bias with
  | Some b -> add ctx y b
  | None -> y

(** Multi-head attention *)
let attention ctx q k v ?(scale_factor=None) () =
  let d_k = float_of_int (get_ne k 0) in
  let scale = match scale_factor with
    | Some s -> s
    | None -> 1.0 /. sqrt d_k
  in
  let kt = transpose ctx k in
  let scores = mul_mat ctx q kt in
  let scaled = scale ctx scores scale in
  let attn = soft_max ctx scaled in
  mul_mat ctx attn v

(** {1 Utility Functions} *)

let print_tensor_info tensor =
  let dims = n_dims tensor in
  let shape_str = Array.to_list (shape tensor) 
    |> List.map string_of_int 
    |> String.concat "x" in
  Printf.printf "Tensor: dims=%d, shape=%s, nelements=%d, nbytes=%d\n"
    dims shape_str (nelements tensor) (nbytes tensor)

let print_backend_info () =
  Printf.printf "GGML Backend: %s\n" (backend_name ());
  let features = detect_cpu_features () in
  Printf.printf "CPU Features:\n";
  Printf.printf "  AVX: %b, AVX2: %b, AVX512: %b\n" features.avx features.avx2 features.avx512;
  Printf.printf "  FMA: %b, NEON: %b, SSE3: %b\n" features.fma features.neon features.sse3;
  Printf.printf "  BLAS: %b, cuBLAS: %b, CLBlast: %b\n" features.blas features.cublas features.clblast

(** {1 Scheme Serialization} *)

let backend_to_scheme backend =
  let name = match backend with
    | CPU -> "cpu"
    | CUDA -> "cuda"
    | Metal -> "metal"
    | Vulkan -> "vulkan"
    | Stub -> "stub"
  in
  Printf.sprintf "(ggml-backend %s)" name

let cpu_features_to_scheme features =
  Printf.sprintf "(cpu-features (avx %b) (avx2 %b) (avx512 %b) (fma %b) (neon %b) (blas %b) (cublas %b))"
    features.avx features.avx2 features.avx512 features.fma features.neon features.blas features.cublas

let tensor_to_scheme tensor =
  let shape_str = Array.to_list (shape tensor) 
    |> List.map string_of_int 
    |> String.concat " " in
  Printf.sprintf "(tensor (dims %d) (shape %s) (nelements %d) (nbytes %d))"
    (n_dims tensor) shape_str (nelements tensor) (nbytes tensor)
