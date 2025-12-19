(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** GGML OCaml Bindings
    
    This module provides OCaml bindings to the GGML tensor library.
    When GGML is available, operations are dispatched to the C library.
    Otherwise, fallback OCaml implementations are used.
*)

(** {1 Types} *)

(** GGML data types *)
type ggml_type =
  | GGML_TYPE_F32
  | GGML_TYPE_F16
  | GGML_TYPE_Q4_0
  | GGML_TYPE_Q4_1
  | GGML_TYPE_Q5_0
  | GGML_TYPE_Q5_1
  | GGML_TYPE_Q8_0
  | GGML_TYPE_Q8_1
  | GGML_TYPE_I8
  | GGML_TYPE_I16
  | GGML_TYPE_I32

let ggml_type_to_int = function
  | GGML_TYPE_F32 -> 0
  | GGML_TYPE_F16 -> 1
  | GGML_TYPE_Q4_0 -> 2
  | GGML_TYPE_Q4_1 -> 3
  | GGML_TYPE_Q5_0 -> 6
  | GGML_TYPE_Q5_1 -> 7
  | GGML_TYPE_Q8_0 -> 8
  | GGML_TYPE_Q8_1 -> 9
  | GGML_TYPE_I8 -> 16
  | GGML_TYPE_I16 -> 17
  | GGML_TYPE_I32 -> 18

(** Opaque types for GGML objects *)
type ggml_context
type ggml_tensor
type ggml_cgraph

(** Backend type *)
type backend = OCaml_native | GGML_backend

(** {1 External C Bindings} *)

external ggml_init_c : int -> ggml_context = "caml_ggml_init"
external ggml_free_c : ggml_context -> unit = "caml_ggml_free"
external ggml_backend_type_c : unit -> int = "caml_ggml_backend_type"

external ggml_new_tensor_1d_c : ggml_context -> int -> int -> ggml_tensor = "caml_ggml_new_tensor_1d"
external ggml_new_tensor_2d_c : ggml_context -> int -> int -> int -> ggml_tensor = "caml_ggml_new_tensor_2d"
external ggml_new_tensor_3d_c : ggml_context -> int -> int -> int -> int -> ggml_tensor = "caml_ggml_new_tensor_3d"
external ggml_new_tensor_4d_c : ggml_context -> int -> int -> int -> int -> int -> ggml_tensor = "caml_ggml_new_tensor_4d_bytecode" "caml_ggml_new_tensor_4d"

external ggml_set_data_c : ggml_tensor -> (float, Bigarray.float32_elt, Bigarray.c_layout) Bigarray.Array1.t -> unit = "caml_ggml_set_data"
external ggml_get_data_c : ggml_tensor -> (float, Bigarray.float32_elt, Bigarray.c_layout) Bigarray.Array1.t = "caml_ggml_get_data"
external ggml_nelements_c : ggml_tensor -> int = "caml_ggml_nelements"
external ggml_nbytes_c : ggml_tensor -> int = "caml_ggml_nbytes"

external ggml_add_c : ggml_context -> ggml_tensor -> ggml_tensor -> ggml_tensor = "caml_ggml_add"
external ggml_sub_c : ggml_context -> ggml_tensor -> ggml_tensor -> ggml_tensor = "caml_ggml_sub"
external ggml_mul_c : ggml_context -> ggml_tensor -> ggml_tensor -> ggml_tensor = "caml_ggml_mul"
external ggml_div_c : ggml_context -> ggml_tensor -> ggml_tensor -> ggml_tensor = "caml_ggml_div"
external ggml_scale_c : ggml_context -> ggml_tensor -> float -> ggml_tensor = "caml_ggml_scale"
external ggml_neg_c : ggml_context -> ggml_tensor -> ggml_tensor = "caml_ggml_neg"

external ggml_mul_mat_c : ggml_context -> ggml_tensor -> ggml_tensor -> ggml_tensor = "caml_ggml_mul_mat"
external ggml_transpose_c : ggml_context -> ggml_tensor -> ggml_tensor = "caml_ggml_transpose"

external ggml_relu_c : ggml_context -> ggml_tensor -> ggml_tensor = "caml_ggml_relu"
external ggml_gelu_c : ggml_context -> ggml_tensor -> ggml_tensor = "caml_ggml_gelu"
external ggml_silu_c : ggml_context -> ggml_tensor -> ggml_tensor = "caml_ggml_silu"
external ggml_soft_max_c : ggml_context -> ggml_tensor -> ggml_tensor = "caml_ggml_soft_max"

external ggml_build_forward_c : ggml_context -> ggml_tensor -> ggml_cgraph = "caml_ggml_build_forward"
external ggml_graph_compute_c : ggml_context -> ggml_cgraph -> unit = "caml_ggml_graph_compute"

external ggml_used_mem_c : ggml_context -> int = "caml_ggml_used_mem"

external ggml_cpu_has_avx_c : unit -> bool = "caml_ggml_cpu_has_avx"
external ggml_cpu_has_avx2_c : unit -> bool = "caml_ggml_cpu_has_avx2"
external ggml_cpu_has_fma_c : unit -> bool = "caml_ggml_cpu_has_fma"
external ggml_cpu_has_neon_c : unit -> bool = "caml_ggml_cpu_has_neon"

(** {1 High-Level Interface} *)

(** Check if GGML backend is available *)
let is_ggml_available () =
  try
    ggml_backend_type_c () = 1
  with _ -> false

(** Get current backend type *)
let get_backend () =
  if is_ggml_available () then GGML_backend else OCaml_native

(** CPU feature detection *)
module CPU = struct
  let has_avx () = try ggml_cpu_has_avx_c () with _ -> false
  let has_avx2 () = try ggml_cpu_has_avx2_c () with _ -> false
  let has_fma () = try ggml_cpu_has_fma_c () with _ -> false
  let has_neon () = try ggml_cpu_has_neon_c () with _ -> false
  
  let features () =
    let features = [] in
    let features = if has_avx () then "AVX" :: features else features in
    let features = if has_avx2 () then "AVX2" :: features else features in
    let features = if has_fma () then "FMA" :: features else features in
    let features = if has_neon () then "NEON" :: features else features in
    features
end

(** {1 Context Management} *)

module Context = struct
  type t = {
    ctx: ggml_context option;
    mem_size: int;
    mutable tensors: ggml_tensor list;
  }
  
  let create ?(mem_size=16*1024*1024) () =
    if is_ggml_available () then
      let ctx = ggml_init_c mem_size in
      { ctx = Some ctx; mem_size; tensors = [] }
    else
      { ctx = None; mem_size; tensors = [] }
  
  let free t =
    match t.ctx with
    | Some ctx -> ggml_free_c ctx
    | None -> ()
  
  let used_mem t =
    match t.ctx with
    | Some ctx -> ggml_used_mem_c ctx
    | None -> 0
end

(** {1 Tensor Operations} *)

module Tensor = struct
  (** OCaml tensor representation for fallback *)
  type ocaml_tensor = {
    shape: int list;
    data: float array;
  }
  
  (** Unified tensor type *)
  type t = 
    | GGML of ggml_tensor
    | OCaml of ocaml_tensor
  
  let shape = function
    | GGML _ -> [] (* Would need to query GGML *)
    | OCaml t -> t.shape
  
  let nelements = function
    | GGML t -> ggml_nelements_c t
    | OCaml t -> Array.length t.data
  
  (** Create tensor from shape and data *)
  let create ctx shape data =
    match ctx.Context.ctx with
    | Some ggml_ctx ->
      let tensor = match shape with
        | [n] -> ggml_new_tensor_1d_c ggml_ctx (ggml_type_to_int GGML_TYPE_F32) n
        | [m; n] -> ggml_new_tensor_2d_c ggml_ctx (ggml_type_to_int GGML_TYPE_F32) n m
        | [m; n; k] -> ggml_new_tensor_3d_c ggml_ctx (ggml_type_to_int GGML_TYPE_F32) k n m
        | [m; n; k; l] -> ggml_new_tensor_4d_c ggml_ctx (ggml_type_to_int GGML_TYPE_F32) l k n m
        | _ -> failwith "Unsupported tensor shape"
      in
      let ba = Bigarray.Array1.of_array Bigarray.float32 Bigarray.c_layout data in
      ggml_set_data_c tensor ba;
      GGML tensor
    | None ->
      OCaml { shape; data }
  
  (** Get tensor data as float array *)
  let to_array = function
    | GGML t ->
      let ba = ggml_get_data_c t in
      Array.init (Bigarray.Array1.dim ba) (fun i -> ba.{i})
    | OCaml t -> t.data
  
  (** Create tensor from float array *)
  let of_array ctx shape arr =
    create ctx shape arr
  
  (** Create zeros tensor *)
  let zeros ctx shape =
    let size = List.fold_left ( * ) 1 shape in
    create ctx shape (Array.make size 0.0)
  
  (** Create ones tensor *)
  let ones ctx shape =
    let size = List.fold_left ( * ) 1 shape in
    create ctx shape (Array.make size 1.0)
  
  (** Create random tensor *)
  let random ctx shape =
    let size = List.fold_left ( * ) 1 shape in
    let data = Array.init size (fun _ -> Random.float 1.0) in
    create ctx shape data
end

(** {1 Operations} *)

module Ops = struct
  (** OCaml fallback implementations *)
  module Fallback = struct
    let add a b =
      let data_a = Tensor.to_array a in
      let data_b = Tensor.to_array b in
      let result = Array.mapi (fun i x -> x +. data_b.(i)) data_a in
      Tensor.OCaml { shape = Tensor.shape a; data = result }
    
    let sub a b =
      let data_a = Tensor.to_array a in
      let data_b = Tensor.to_array b in
      let result = Array.mapi (fun i x -> x -. data_b.(i)) data_a in
      Tensor.OCaml { shape = Tensor.shape a; data = result }
    
    let mul a b =
      let data_a = Tensor.to_array a in
      let data_b = Tensor.to_array b in
      let result = Array.mapi (fun i x -> x *. data_b.(i)) data_a in
      Tensor.OCaml { shape = Tensor.shape a; data = result }
    
    let scale s a =
      let data = Tensor.to_array a in
      let result = Array.map (fun x -> x *. s) data in
      Tensor.OCaml { shape = Tensor.shape a; data = result }
    
    let neg a =
      let data = Tensor.to_array a in
      let result = Array.map (fun x -> -.x) data in
      Tensor.OCaml { shape = Tensor.shape a; data = result }
    
    let relu a =
      let data = Tensor.to_array a in
      let result = Array.map (fun x -> max 0.0 x) data in
      Tensor.OCaml { shape = Tensor.shape a; data = result }
    
    let sigmoid a =
      let data = Tensor.to_array a in
      let result = Array.map (fun x -> 1.0 /. (1.0 +. exp (-.x))) data in
      Tensor.OCaml { shape = Tensor.shape a; data = result }
    
    let gelu a =
      let data = Tensor.to_array a in
      let result = Array.map (fun x ->
        0.5 *. x *. (1.0 +. tanh (sqrt (2.0 /. Float.pi) *. (x +. 0.044715 *. x *. x *. x)))
      ) data in
      Tensor.OCaml { shape = Tensor.shape a; data = result }
    
    let silu a =
      let data = Tensor.to_array a in
      let result = Array.map (fun x -> x /. (1.0 +. exp (-.x))) data in
      Tensor.OCaml { shape = Tensor.shape a; data = result }
    
    let softmax a =
      let data = Tensor.to_array a in
      let max_val = Array.fold_left max neg_infinity data in
      let exp_data = Array.map (fun x -> exp (x -. max_val)) data in
      let sum_exp = Array.fold_left (+.) 0.0 exp_data in
      let result = Array.map (fun x -> x /. sum_exp) exp_data in
      Tensor.OCaml { shape = Tensor.shape a; data = result }
    
    let matmul a b =
      let data_a = Tensor.to_array a in
      let data_b = Tensor.to_array b in
      match Tensor.shape a, Tensor.shape b with
      | [m; k], [k2; n] when k = k2 ->
        let result = Array.make (m * n) 0.0 in
        for i = 0 to m - 1 do
          for j = 0 to n - 1 do
            let sum = ref 0.0 in
            for l = 0 to k - 1 do
              sum := !sum +. data_a.(i * k + l) *. data_b.(l * n + j)
            done;
            result.(i * n + j) <- !sum
          done
        done;
        Tensor.OCaml { shape = [m; n]; data = result }
      | _ -> failwith "Invalid shapes for matmul"
    
    let transpose a =
      let data = Tensor.to_array a in
      match Tensor.shape a with
      | [rows; cols] ->
        let result = Array.make (rows * cols) 0.0 in
        for i = 0 to rows - 1 do
          for j = 0 to cols - 1 do
            result.(j * rows + i) <- data.(i * cols + j)
          done
        done;
        Tensor.OCaml { shape = [cols; rows]; data = result }
      | _ -> failwith "Transpose only for 2D tensors"
  end
  
  (** Dispatch to GGML or fallback *)
  let add ctx a b =
    match ctx.Context.ctx, a, b with
    | Some ggml_ctx, Tensor.GGML ta, Tensor.GGML tb ->
      Tensor.GGML (ggml_add_c ggml_ctx ta tb)
    | _ -> Fallback.add a b
  
  let sub ctx a b =
    match ctx.Context.ctx, a, b with
    | Some ggml_ctx, Tensor.GGML ta, Tensor.GGML tb ->
      Tensor.GGML (ggml_sub_c ggml_ctx ta tb)
    | _ -> Fallback.sub a b
  
  let mul ctx a b =
    match ctx.Context.ctx, a, b with
    | Some ggml_ctx, Tensor.GGML ta, Tensor.GGML tb ->
      Tensor.GGML (ggml_mul_c ggml_ctx ta tb)
    | _ -> Fallback.mul a b
  
  let scale ctx s a =
    match ctx.Context.ctx, a with
    | Some ggml_ctx, Tensor.GGML ta ->
      Tensor.GGML (ggml_scale_c ggml_ctx ta s)
    | _ -> Fallback.scale s a
  
  let neg ctx a =
    match ctx.Context.ctx, a with
    | Some ggml_ctx, Tensor.GGML ta ->
      Tensor.GGML (ggml_neg_c ggml_ctx ta)
    | _ -> Fallback.neg a
  
  let relu ctx a =
    match ctx.Context.ctx, a with
    | Some ggml_ctx, Tensor.GGML ta ->
      Tensor.GGML (ggml_relu_c ggml_ctx ta)
    | _ -> Fallback.relu a
  
  let gelu ctx a =
    match ctx.Context.ctx, a with
    | Some ggml_ctx, Tensor.GGML ta ->
      Tensor.GGML (ggml_gelu_c ggml_ctx ta)
    | _ -> Fallback.gelu a
  
  let silu ctx a =
    match ctx.Context.ctx, a with
    | Some ggml_ctx, Tensor.GGML ta ->
      Tensor.GGML (ggml_silu_c ggml_ctx ta)
    | _ -> Fallback.silu a
  
  let softmax ctx a =
    match ctx.Context.ctx, a with
    | Some ggml_ctx, Tensor.GGML ta ->
      Tensor.GGML (ggml_soft_max_c ggml_ctx ta)
    | _ -> Fallback.softmax a
  
  let matmul ctx a b =
    match ctx.Context.ctx, a, b with
    | Some ggml_ctx, Tensor.GGML ta, Tensor.GGML tb ->
      Tensor.GGML (ggml_mul_mat_c ggml_ctx ta tb)
    | _ -> Fallback.matmul a b
  
  let transpose ctx a =
    match ctx.Context.ctx, a with
    | Some ggml_ctx, Tensor.GGML ta ->
      Tensor.GGML (ggml_transpose_c ggml_ctx ta)
    | _ -> Fallback.transpose a
end

(** {1 Compute Graph} *)

module Graph = struct
  type t = {
    ctx: Context.t;
    graph: ggml_cgraph option;
    output: Tensor.t;
  }
  
  let build ctx output =
    match ctx.Context.ctx, output with
    | Some ggml_ctx, Tensor.GGML tensor ->
      let graph = ggml_build_forward_c ggml_ctx tensor in
      { ctx; graph = Some graph; output }
    | _ ->
      { ctx; graph = None; output }
  
  let compute t =
    match t.ctx.Context.ctx, t.graph with
    | Some ggml_ctx, Some graph ->
      ggml_graph_compute_c ggml_ctx graph
    | _ -> ()
  
  let result t = t.output
end

(** {1 Utility Functions} *)

let backend_info () =
  let backend = if is_ggml_available () then "GGML" else "OCaml" in
  let features = CPU.features () in
  Printf.sprintf "Backend: %s, CPU features: [%s]" backend (String.concat ", " features)
