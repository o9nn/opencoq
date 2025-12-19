(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** GGML OCaml Bindings Interface
    
    This module provides OCaml bindings to the GGML tensor library
    with automatic fallback to pure OCaml implementations.
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

(** Backend type *)
type backend = OCaml_native | GGML_backend

(** Check if GGML backend is available *)
val is_ggml_available : unit -> bool

(** Get current backend type *)
val get_backend : unit -> backend

(** {1 CPU Feature Detection} *)

module CPU : sig
  val has_avx : unit -> bool
  val has_avx2 : unit -> bool
  val has_fma : unit -> bool
  val has_neon : unit -> bool
  val features : unit -> string list
end

(** {1 Context Management} *)

module Context : sig
  type t
  
  (** Create a new GGML context with optional memory size *)
  val create : ?mem_size:int -> unit -> t
  
  (** Free context resources *)
  val free : t -> unit
  
  (** Get memory used by context *)
  val used_mem : t -> int
end

(** {1 Tensor Operations} *)

module Tensor : sig
  (** Tensor type (GGML or OCaml fallback) *)
  type t
  
  (** Get tensor shape *)
  val shape : t -> int list
  
  (** Get number of elements *)
  val nelements : t -> int
  
  (** Create tensor from shape and data *)
  val create : Context.t -> int list -> float array -> t
  
  (** Get tensor data as float array *)
  val to_array : t -> float array
  
  (** Create tensor from float array *)
  val of_array : Context.t -> int list -> float array -> t
  
  (** Create zeros tensor *)
  val zeros : Context.t -> int list -> t
  
  (** Create ones tensor *)
  val ones : Context.t -> int list -> t
  
  (** Create random tensor *)
  val random : Context.t -> int list -> t
end

(** {1 Operations} *)

module Ops : sig
  (** Element-wise addition *)
  val add : Context.t -> Tensor.t -> Tensor.t -> Tensor.t
  
  (** Element-wise subtraction *)
  val sub : Context.t -> Tensor.t -> Tensor.t -> Tensor.t
  
  (** Element-wise multiplication *)
  val mul : Context.t -> Tensor.t -> Tensor.t -> Tensor.t
  
  (** Scalar multiplication *)
  val scale : Context.t -> float -> Tensor.t -> Tensor.t
  
  (** Negation *)
  val neg : Context.t -> Tensor.t -> Tensor.t
  
  (** ReLU activation *)
  val relu : Context.t -> Tensor.t -> Tensor.t
  
  (** GELU activation *)
  val gelu : Context.t -> Tensor.t -> Tensor.t
  
  (** SiLU activation *)
  val silu : Context.t -> Tensor.t -> Tensor.t
  
  (** Softmax *)
  val softmax : Context.t -> Tensor.t -> Tensor.t
  
  (** Matrix multiplication *)
  val matmul : Context.t -> Tensor.t -> Tensor.t -> Tensor.t
  
  (** Transpose *)
  val transpose : Context.t -> Tensor.t -> Tensor.t
end

(** {1 Compute Graph} *)

module Graph : sig
  type t
  
  (** Build compute graph from output tensor *)
  val build : Context.t -> Tensor.t -> t
  
  (** Execute compute graph *)
  val compute : t -> unit
  
  (** Get result tensor *)
  val result : t -> Tensor.t
end

(** {1 Utility Functions} *)

(** Get backend information string *)
val backend_info : unit -> string
