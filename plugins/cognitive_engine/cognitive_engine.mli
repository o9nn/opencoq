(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** Main Cognitive Engine - Integration Module *)

(** Cognitive engine state *)
type cognitive_engine = {
  atomspace : Hypergraph.atomspace;
  task_queue : Task_system.task_queue;
  ecan_system : Attention_system.ecan_system;
  reasoning_engine : Reasoning_engine.reasoning_engine;
  metacognitive_system : Metacognition.metacognitive_system;
  mutable fusion_context : Neural_symbolic_fusion.fusion_context option;
  mutable cycle_count : int;
  mutable running : bool;
}

(** Cognitive engine configuration *)
type engine_config = {
  max_concurrent_tasks : int;
  ecan_config : Attention_system.ecan_config;
  reasoning_enabled : bool;
  metacognition_enabled : bool;
  cycle_frequency : float;
  fusion_embedding_dim : int;
}

(** Create cognitive engine *)
val create_cognitive_engine : engine_config -> cognitive_engine

(** Default engine configuration *)
val default_engine_config : engine_config

(** Core engine operations *)
val start_engine : cognitive_engine -> unit

val stop_engine : cognitive_engine -> unit

val single_cognitive_cycle : cognitive_engine -> unit

val run_for_cycles : cognitive_engine -> int -> unit

(** High-level cognitive operations *)
val learn_pattern : cognitive_engine -> string -> Hypergraph.node_id list -> unit

val reason_about : cognitive_engine -> Hypergraph.node_id -> Reasoning_engine.inference_result list

val focus_attention_on : cognitive_engine -> Hypergraph.node_id list -> unit

val set_cognitive_goal : cognitive_engine -> string -> unit

(** Knowledge integration *)
val add_knowledge : cognitive_engine -> string -> string -> Hypergraph.node_id

val create_association : cognitive_engine -> Hypergraph.node_id -> Hypergraph.node_id -> Hypergraph.link_type -> Hypergraph.link_id

val query_knowledge : cognitive_engine -> string -> Hypergraph.node_id list

(** Cognitive development *)
val bootstrap_basic_knowledge : cognitive_engine -> unit

val self_improve : cognitive_engine -> int -> unit

val adapt_to_feedback : cognitive_engine -> string -> float -> unit

(** Monitoring and diagnostics *)
val get_engine_status : cognitive_engine -> (bool * int * float * float * int)

val get_cognitive_statistics : cognitive_engine -> string

val export_cognitive_state : cognitive_engine -> string

val import_cognitive_state : cognitive_engine -> string -> bool

(** Scheme integration *)
val execute_scheme_command : cognitive_engine -> string -> string

val cognitive_engine_to_scheme : cognitive_engine -> string

(** Interactive interface *)
val process_natural_language : cognitive_engine -> string -> string

val answer_question : cognitive_engine -> string -> string

val explain_reasoning : cognitive_engine -> Hypergraph.node_id -> string

(** Tensor operations for neural-symbolic integration *)
val configure_tensor_backend : cognitive_engine -> Tensor_backend.backend_type -> unit

val add_neural_representation : cognitive_engine -> Hypergraph.node_id -> float array -> Hypergraph.tensor_shape -> Hypergraph.tensor_id

val get_neural_representation : cognitive_engine -> Hypergraph.node_id -> Hypergraph.tensor list

val compute_concept_similarity : cognitive_engine -> Hypergraph.node_id -> Hypergraph.node_id -> float

val process_with_neural_attention : cognitive_engine -> Hypergraph.tensor_id list -> Hypergraph.tensor_id list

val neural_symbolic_fusion : cognitive_engine -> string -> float array -> Hypergraph.tensor_shape -> (Hypergraph.node_id * Hypergraph.tensor_id)

(** Enhanced Neural-Symbolic Fusion Functions *)

val get_fusion_context : cognitive_engine -> Neural_symbolic_fusion.fusion_context

val enable_enhanced_fusion : cognitive_engine -> int -> unit

val enhanced_neural_symbolic_fusion : cognitive_engine -> string -> float array -> Hypergraph.tensor_shape -> Neural_symbolic_fusion.fusion_strategy -> (Hypergraph.node_id * Hypergraph.tensor_id)

val hierarchical_concept_embedding : cognitive_engine -> Hypergraph.node_id -> Hypergraph.node_id list -> Hypergraph.tensor_id

val compositional_neural_reasoning : cognitive_engine -> Hypergraph.node_id list -> Neural_symbolic_fusion.fusion_strategy -> Hypergraph.tensor_id

val adaptive_neural_attention : cognitive_engine -> Hypergraph.node_id list -> Hypergraph.tensor_id list -> Hypergraph.tensor_id list

val gradient_based_concept_learning : cognitive_engine -> Hypergraph.node_id -> Hypergraph.tensor_id -> unit

val neural_guided_reasoning : cognitive_engine -> Hypergraph.node_id -> Hypergraph.node_id list -> (Hypergraph.node_id * float) list

val enhanced_concept_similarity : cognitive_engine -> Hypergraph.node_id -> Hypergraph.node_id -> float

val neural_symbolic_composition : cognitive_engine -> Hypergraph.node_id list -> Neural_symbolic_fusion.fusion_strategy -> Hypergraph.tensor_id

val cross_modal_attention_analysis : cognitive_engine -> Hypergraph.node_id list -> Hypergraph.tensor_id list -> float array

val suggest_proof_tactics : cognitive_engine -> Hypergraph.node_id -> string list

val constrained_neural_search : cognitive_engine -> Hypergraph.node_id list -> Hypergraph.node_id list -> Hypergraph.node_id list

val create_proof_embedding : cognitive_engine -> Hypergraph.node_id -> Hypergraph.tensor_id

val reinforce_concept_learning : cognitive_engine -> Hypergraph.node_id -> float -> unit

val discover_neural_concept_patterns : cognitive_engine -> Hypergraph.tensor_id list -> (Hypergraph.tensor_id * float) list

val evolve_concept_fusion_strategy : cognitive_engine -> Hypergraph.node_id -> Neural_symbolic_fusion.fusion_strategy -> Neural_symbolic_fusion.fusion_strategy

val get_fusion_diagnostics : cognitive_engine -> (string * float) list

val fusion_context_debug : cognitive_engine -> string