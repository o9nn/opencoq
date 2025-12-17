(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** ECAN (Economic Attention Networks) - Attention Allocation System *)

(** Attention events *)
type attention_event =
  | Stimulus of Hypergraph.node_id * float
  | Decay of float
  | Rent_collection of float
  | Spread_activation of Hypergraph.node_id * float
  | Gradient_update of Hypergraph.node_id * float array

(** Multi-head attention tensor structure (A, T) *)
type attention_tensor = {
  attention_heads : int;        (** A - number of attention heads *)
  temporal_depth : int;         (** T - temporal depth for attention patterns *)
  mutable tensor_data : float array array; (** [A][T] tensor data *)
  mutable gradients : float array array;   (** Gradient information for optimization *)
  mutable head_weights : float array;      (** Importance weights for each head *)
  mutable temporal_weights : float array;  (** Weights for temporal positions *)
}

(** Gradient-based attention optimization configuration *)
type gradient_attention_config = {
  learning_rate : float;
  momentum_factor : float;
  gradient_clipping : float;
  update_frequency : int;
  economic_weight : float;  (** Weight for ECAN economic considerations *)
}

(** Attention bank for economic attention allocation *)
type attention_bank = {
  mutable total_sti : float;
  mutable available_sti : float;
  mutable total_lti : float;
  mutable available_lti : float;
  mutable minimum_sti : float;
  mutable minimum_lti : float;
}

(** Attention allocation configuration *)
type ecan_config = {
  sti_funds : float;
  lti_funds : float;
  decay_factor : float;
  rent_rate : float;
  spread_threshold : float;
  forgetting_threshold : float;
}

(** Attentional focus - high attention atoms *)
type attentional_focus = {
  mutable focus_size : int;
  mutable focused_atoms : (Hypergraph.node_id * Hypergraph.link_id) list;
  mutable update_frequency : int;
}

(** ECAN system state *)
type ecan_system = {
  atomspace : Hypergraph.atomspace;
  attention_bank : attention_bank;
  config : ecan_config;
  attentional_focus : attentional_focus;
  mutable event_history : attention_event list;
}

(** Create ECAN system *)
val create_ecan_system : Hypergraph.atomspace -> ecan_config -> ecan_system

(** Default ECAN configuration *)
val default_ecan_config : ecan_config

(** Attention bank operations *)
val initialize_attention_bank : float -> float -> attention_bank

val allocate_sti : attention_bank -> float -> bool

val allocate_lti : attention_bank -> float -> bool

val return_sti : attention_bank -> float -> unit

val return_lti : attention_bank -> float -> unit

val get_bank_status : attention_bank -> (float * float * float * float)

(** Core ECAN operations *)
val stimulate_atom : ecan_system -> Hypergraph.node_id -> float -> unit

val spread_activation : ecan_system -> Hypergraph.node_id -> unit

val apply_decay : ecan_system -> unit

val collect_rent : ecan_system -> unit

val forget_low_attention_atoms : ecan_system -> unit

(** Attentional focus management *)
val update_attentional_focus : ecan_system -> unit

val get_focused_atoms : ecan_system -> (Hypergraph.node_id * Hypergraph.link_id) list

val is_in_focus : ecan_system -> Hypergraph.node_id -> bool

(** Attention-guided processing *)
val get_attention_guided_tasks : ecan_system -> Task_system.task_type list

val prioritize_by_attention : ecan_system -> Hypergraph.node_id list -> Hypergraph.node_id list

(** Economic dynamics *)
val calculate_importance : ecan_system -> Hypergraph.node_id -> float

val wage_attention : ecan_system -> Hypergraph.node_id -> float -> unit

val attention_competition : ecan_system -> Hypergraph.node_id list -> Hypergraph.node_id list

(** ECAN cycle - main processing loop *)
val ecan_cycle : ecan_system -> unit

(** Gradient-based attention optimization *)
val create_attention_tensor : int -> int -> attention_tensor

val default_gradient_attention_config : gradient_attention_config

val update_attention_gradients : attention_tensor -> Hypergraph.node_id -> float array -> unit

val apply_gradient_optimization : ecan_system -> attention_tensor -> gradient_attention_config -> unit

val compute_attention_head_importance : attention_tensor -> Hypergraph.node_id -> float array

val allocate_compute_cycles_by_attention : ecan_system -> attention_tensor -> gradient_attention_config -> float array

val temporal_attention_decay : attention_tensor -> float -> unit

val economic_gradient_integration : ecan_system -> attention_tensor -> gradient_attention_config -> unit

(** Monitoring and diagnostics *)
val get_attention_statistics : ecan_system -> (float * float * int * int)

val get_most_important_atoms : ecan_system -> int -> Hypergraph.node_id list

val get_attention_tensor_stats : attention_tensor -> (float * float * float * float)

val get_attention_distribution : ecan_system -> (float * int) list

(** Scheme representation *)
val attention_event_to_scheme : attention_event -> string

val attention_bank_to_scheme : attention_bank -> string

val ecan_config_to_scheme : ecan_config -> string

val ecan_system_to_scheme : ecan_system -> string