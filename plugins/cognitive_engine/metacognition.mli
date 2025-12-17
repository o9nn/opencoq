(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** Meta-Cognition - Introspection and Self-Modification *)

(** Cognitive process types *)
type cognitive_process =
  | Memory_access
  | Attention_allocation
  | Reasoning_inference  
  | Pattern_recognition
  | Goal_pursuit
  | Self_monitoring

(** Performance metrics *)
type performance_metric = {
  process : cognitive_process;
  success_rate : float;
  average_time : float;
  resource_usage : float;
  improvement_trend : float;
}

(** Self-model - the system's model of itself *)
type self_model = {
  mutable cognitive_state : (cognitive_process * float) list;
  mutable performance_history : performance_metric list;
  mutable current_goals : string list;
  mutable learning_rate : float;
  mutable confidence_level : float;
}

(** Introspection result *)
type introspection_result = {
  observed_process : cognitive_process;
  efficiency_rating : float;
  bottlenecks : string list;
  improvement_suggestions : string list;
  timestamp : float;
}

(** Self-modification action *)
type self_modification =
  | Adjust_attention_parameters of float * float
  | Modify_reasoning_rules of Reasoning_engine.pln_rule list
  | Update_learning_rate of float
  | Reorganize_memory of Hypergraph.node_id list
  | Change_goal_priorities of string list
  | Modify_introspection_depth of int
  | Create_new_cognitive_process of string * (unit -> unit)
  | Optimize_modification_strategy of (introspection_result list -> self_modification list)
  | Update_meta_learning_params of float * float

(** Meta-cognitive system *)
type metacognitive_system = {
  self_model : self_model;
  reasoning_engine : Reasoning_engine.reasoning_engine;
  ecan_system : Attention_system.ecan_system;
  task_queue : Task_system.task_queue;
  mutable introspection_history : introspection_result list;
  mutable modification_history : self_modification list;
  mutable introspection_depth : int;
  mutable meta_learning_rate : float;
  mutable modification_strategy_effectiveness : (string * float) list;
  mutable recursive_improvement_count : int;
}

(** Create meta-cognitive system *)
val create_metacognitive_system : 
  Reasoning_engine.reasoning_engine -> 
  Attention_system.ecan_system -> 
  Task_system.task_queue -> 
  metacognitive_system

(** Self-model operations *)
val initialize_self_model : unit -> self_model

val update_cognitive_state : self_model -> cognitive_process -> float -> unit

val update_performance_metric : self_model -> performance_metric -> unit

val get_current_efficiency : self_model -> cognitive_process -> float option

(** Introspection operations *)
val introspect_attention_system : metacognitive_system -> introspection_result

val introspect_reasoning_performance : metacognitive_system -> introspection_result

val introspect_memory_usage : metacognitive_system -> introspection_result

val introspect_task_execution : metacognitive_system -> introspection_result

val comprehensive_self_assessment : metacognitive_system -> introspection_result list

(** Self-modification operations *)
val plan_self_modification : metacognitive_system -> introspection_result list -> self_modification list

val execute_self_modification : metacognitive_system -> self_modification -> bool

val validate_modification_effects : metacognitive_system -> self_modification -> bool

(** Goal management *)
val set_cognitive_goals : metacognitive_system -> string list -> unit

val evaluate_goal_progress : metacognitive_system -> (string * float) list

val adapt_goals_based_on_performance : metacognitive_system -> unit

(** Learning and adaptation *)
val learn_from_experience : metacognitive_system -> unit

val adapt_to_environment : metacognitive_system -> unit

val optimize_cognitive_resources : metacognitive_system -> unit

(** Meta-level reasoning *)
val reason_about_reasoning : metacognitive_system -> Reasoning_engine.inference_result list

val meta_pattern_recognition : metacognitive_system -> (string * float) list

val predict_future_performance : metacognitive_system -> cognitive_process -> float

(** Integration with other systems *)
val create_metacognitive_tasks : metacognitive_system -> Task_system.cognitive_task list

val attention_guided_introspection : metacognitive_system -> introspection_result list

val recursive_self_improvement : metacognitive_system -> int -> unit

(** Advanced self-improvement operations *)
val meta_recursive_self_improvement : metacognitive_system -> int -> int -> unit

val analyze_modification_patterns : metacognitive_system -> (string * float) list

val generate_new_modification_strategy : metacognitive_system -> (introspection_result list -> self_modification list)

val detect_improvement_convergence : metacognitive_system -> bool

val validate_recursive_stability : metacognitive_system -> bool

(** Monitoring and diagnostics *)
val get_metacognitive_statistics : metacognitive_system -> (int * int * float * float)

val get_improvement_trajectory : metacognitive_system -> (float * float) list

val detect_cognitive_anomalies : metacognitive_system -> string list

(** Scheme representation *)
val cognitive_process_to_scheme : cognitive_process -> string

val performance_metric_to_scheme : performance_metric -> string

val introspection_result_to_scheme : introspection_result -> string

val self_modification_to_scheme : self_modification -> string

val metacognitive_system_to_scheme : metacognitive_system -> string