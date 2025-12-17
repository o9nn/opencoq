(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** Enhanced Neural-Symbolic Fusion Architecture *)

(** Fusion strategy types *)
type fusion_strategy = 
  | Embedding_Based     (** Map symbols to neural embeddings *)
  | Compositional       (** Compose neural representations from symbolic structure *)
  | Attention_Guided    (** Use attention mechanisms for selective fusion *)
  | Hierarchical        (** Multi-level fusion from embeddings to reasoning *)

(** Neural-symbolic binding *)
type neural_symbolic_binding = {
  symbolic_id : int;
  neural_id : int;
  binding_strength : float;
  fusion_strategy : fusion_strategy;
  created_at : float;
  last_updated : float;
}

(** Fusion context *)
type fusion_context = {
  atomspace : Hypergraph.atomspace;
  mutable bindings : (int, neural_symbolic_binding) Hashtbl.t;
  mutable fusion_history : neural_symbolic_binding list;
  embedding_dimension : int;
  learning_rate : float;
}

(** Create fusion context *)
val create_fusion_context : Hypergraph.atomspace -> int -> fusion_context

(** Enhanced bidirectional translation *)
val symbol_to_neural : fusion_context -> int -> fusion_strategy -> int option
val neural_to_symbol : fusion_context -> int -> int option
val create_neural_symbolic_binding : fusion_context -> int -> int -> fusion_strategy -> float -> unit

(** Hierarchical fusion operations *)
val hierarchical_embed : fusion_context -> int -> int list -> int
val compositional_reasoning : fusion_context -> int list -> fusion_strategy -> int
val adaptive_attention_fusion : fusion_context -> int list -> int list -> int list

(** Gradient-based symbolic learning *)
val compute_symbolic_gradients : fusion_context -> int -> int -> float array
val update_symbolic_knowledge : fusion_context -> int -> float array -> unit
val neural_guided_inference : fusion_context -> int -> int list -> (int * float) list

(** Neural-symbolic similarity and operations *)
val enhanced_concept_similarity : fusion_context -> int -> int -> float
val neural_symbolic_composition : fusion_context -> int list -> fusion_strategy -> int
val cross_modal_attention : fusion_context -> int list -> int list -> float array

(** Proof-theoretic integration *)
val neural_guided_tactic_suggestion : fusion_context -> int -> string list
val symbolic_constraint_neural_search : fusion_context -> int list -> int list -> int list
val proof_embedding : fusion_context -> int -> int

(** Learning and adaptation *)
val reinforcement_update : fusion_context -> int -> float -> unit
val discover_neural_patterns : fusion_context -> int list -> (int * float) list
val evolve_fusion_strategy : fusion_context -> int -> fusion_strategy -> fusion_strategy

(** Debugging and introspection *)
val fusion_context_to_scheme : fusion_context -> string
val analyze_binding_quality : fusion_context -> int -> float
val get_fusion_statistics : fusion_context -> (string * float) list

(** Integration with gradient-based attention optimization *)
val compute_attention_gradients_from_neural : fusion_context -> Attention_system.attention_tensor -> int list -> int list -> float array
val neural_guided_attention_optimization : fusion_context -> Attention_system.ecan_system -> Attention_system.attention_tensor -> Attention_system.gradient_attention_config -> unit
val create_attention_guided_embeddings : fusion_context -> Attention_system.attention_tensor -> int list -> (int * int) list
val attention_driven_reinforcement_learning : fusion_context -> Attention_system.ecan_system -> Attention_system.attention_tensor -> (int * float) list -> unit
val neural_symbolic_attention_cycle : fusion_context -> Attention_system.ecan_system -> Attention_system.attention_tensor -> Attention_system.gradient_attention_config -> (int * float) list -> ((string * float) list * (float * float * float * float) * (float * float * int * int))