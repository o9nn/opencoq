(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** Tensor Backend Interface - Abstraction layer for tensor operations *)

(** Backend types *)
type backend_type = 
  | OCaml_native  (** Pure OCaml implementation *)
  | GGML          (** GGML backend for optimized operations *)

type tensor_data = float array
type tensor_shape = int list

(** Tensor operation context *)
type tensor_context = {
  backend : backend_type;
  mutable device : string; (** "cpu", "gpu", etc. *)
  mutable precision : [`Float32 | `Float16];
}

(** Create tensor context *)
val create_context : backend_type -> tensor_context

(** Basic tensor operations *)
val tensor_add : tensor_context -> tensor_shape -> tensor_data -> tensor_data -> tensor_data
val tensor_multiply : tensor_context -> tensor_shape -> tensor_data -> tensor_data -> tensor_data
val tensor_matmul : tensor_context -> tensor_shape -> tensor_shape -> tensor_data -> tensor_data -> tensor_data
val tensor_scale : tensor_context -> tensor_shape -> float -> tensor_data -> tensor_data
val tensor_transpose : tensor_context -> tensor_shape -> tensor_data -> tensor_data * tensor_shape

(** Advanced operations *)
val tensor_reshape : tensor_context -> tensor_shape -> tensor_shape -> tensor_data -> tensor_data
val tensor_dot_product : tensor_context -> tensor_data -> tensor_data -> float
val tensor_norm : tensor_context -> tensor_data -> float

(** Neural network operations *)
val tensor_relu : tensor_context -> tensor_shape -> tensor_data -> tensor_data
val tensor_sigmoid : tensor_context -> tensor_shape -> tensor_data -> tensor_data
val tensor_softmax : tensor_context -> tensor_shape -> tensor_data -> tensor_data

(** GGML-specific operations (when backend is GGML) *)
val ggml_compute_graph : tensor_context -> tensor_data list -> tensor_data list
val ggml_optimize_memory : tensor_context -> unit -> unit

(** Utility functions *)
val validate_shapes : tensor_shape -> tensor_shape -> bool
val calculate_size : tensor_shape -> int
val tensor_to_string : tensor_shape -> tensor_data -> string