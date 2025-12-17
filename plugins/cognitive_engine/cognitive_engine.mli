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