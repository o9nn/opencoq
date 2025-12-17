(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** Hypergraph Cognition Kernel - Core Data Structures *)

(** Node identifiers *)
type node_id = int

(** Link identifiers *)
type link_id = int

(** Tensor identifiers *)
type tensor_id = int

(** Attention values for ECAN *)
type attention_value = {
  sti : float;  (** Short-term importance *)
  lti : float;  (** Long-term importance *)
  vlti : float; (** Very long-term importance *)
}

(** Node types for the AtomSpace *)
type node_type =
  | Concept
  | Predicate
  | Variable
  | Number
  | Link_type

(** Hypergraph node *)
type node = {
  id : node_id;
  node_type : node_type;
  name : string;
  attention : attention_value;
  truth_value : float * float; (** (strength, confidence) *)
}

(** Link types *)
type link_type =
  | Inheritance
  | Similarity
  | Implication
  | Evaluation
  | Execution
  | Custom of string

(** Hypergraph link connecting nodes *)
type link = {
  id : link_id;
  link_type : link_type;
  outgoing : node_id list;
  attention : attention_value;
  truth_value : float * float;
}

(** Tensor shapes for neural-symbolic integration *)
type tensor_shape = int list

(** Tensor for storing distributed representations *)
type tensor = {
  id : tensor_id;
  shape : tensor_shape;
  data : float array;
  associated_node : node_id option;
}

(** AtomSpace - the main hypergraph store *)
type atomspace = {
  mutable nodes : (node_id, node) Hashtbl.t;
  mutable links : (link_id, link) Hashtbl.t;
  mutable tensors : (tensor_id, tensor) Hashtbl.t;
  mutable next_node_id : node_id;
  mutable next_link_id : link_id;
  mutable next_tensor_id : tensor_id;
  mutable node_index : (string, node_id list) Hashtbl.t;
}

(** Create empty AtomSpace *)
val create_atomspace : unit -> atomspace

(** Node operations *)
val add_node : atomspace -> node_type -> string -> node_id
val get_node : atomspace -> node_id -> node option
val update_node_attention : atomspace -> node_id -> attention_value -> unit
val update_node_truth : atomspace -> node_id -> float * float -> unit
val remove_node : atomspace -> node_id -> unit

(** Link operations *)
val add_link : atomspace -> link_type -> node_id list -> link_id
val get_link : atomspace -> link_id -> link option
val update_link_attention : atomspace -> link_id -> attention_value -> unit
val update_link_truth : atomspace -> link_id -> float * float -> unit
val remove_link : atomspace -> link_id -> unit

(** Tensor operations *)
val add_tensor : atomspace -> tensor_shape -> float array -> node_id option -> tensor_id
val get_tensor : atomspace -> tensor_id -> tensor option
val update_tensor_data : atomspace -> tensor_id -> float array -> unit
val remove_tensor : atomspace -> tensor_id -> unit

(** Query operations *)
val find_nodes_by_name : atomspace -> string -> node_id list
val find_nodes_by_type : atomspace -> node_type -> node_id list
val find_links_by_type : atomspace -> link_type -> link_id list
val get_incoming_links : atomspace -> node_id -> link_id list
val get_outgoing_links : atomspace -> node_id -> link_id list

(** Attention allocation primitives (ECAN) *)
val spread_activation : atomspace -> node_id -> float -> unit
val decay_attention : atomspace -> float -> unit
val get_high_attention_atoms : atomspace -> int -> (node_id * link_id) list

(** Scheme S-expression conversion *)
val node_to_scheme : node -> string
val link_to_scheme : link -> string
val tensor_to_scheme : tensor -> string
val atomspace_to_scheme : atomspace -> string