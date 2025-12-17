(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** Reasoning Engine - PLN/MOSES Integration Stubs *)

(** Rule types for PLN (Probabilistic Logic Networks) *)
type pln_rule =
  | Deduction_rule
  | Induction_rule
  | Abduction_rule
  | Revision_rule
  | Similarity_rule
  | Inheritance_rule
  | Temporal_rule
  | Causal_rule

(** Temporal Logic Types *)
type temporal_operator =
  | Always        (** □ - Always/Globally *)
  | Eventually    (** ◊ - Eventually/Finally *) 
  | Next          (** ○ - Next *)
  | Previous      (** ● - Previous *)
  | Until         (** U - Until *)
  | Since         (** S - Since *)
  | Release       (** R - Release *)
  | Weak_until    (** W - Weak Until *)

type temporal_formula = {
  operator : temporal_operator;
  operands : Hypergraph.link_id list;
  time_bounds : (int * int) option;  (** Optional time bounds (min, max) *)
  temporal_context : int;            (** Current temporal context/state *)
}

(** Causal Reasoning Types *)
type causal_relation_type =
  | Direct_cause       (** A directly causes B *)
  | Indirect_cause     (** A indirectly causes B through mediators *)
  | Necessary_cause    (** A is necessary for B *)
  | Sufficient_cause   (** A is sufficient for B *)
  | Contributory_cause (** A contributes to B *)
  | Preventive_cause   (** A prevents B *)

type causal_strength = {
  probability : float;      (** P(effect|cause) *)
  confidence : float;       (** Confidence in the causal relationship *)
  temporal_lag : int;       (** Time delay between cause and effect *)
  context_sensitivity : float; (** How context-dependent this relation is *)
}

type causal_relationship = {
  cause : Hypergraph.link_id;
  effect : Hypergraph.link_id;
  relation_type : causal_relation_type;
  strength : causal_strength;
  mediators : Hypergraph.link_id list; (** Intermediate causes *)
  confounders : Hypergraph.link_id list; (** Potential confounding variables *)
}

(** Temporal State Management *)
type temporal_state = {
  current_time : int;
  time_horizon : int;
  temporal_knowledge : (int, Hypergraph.link_id list) Hashtbl.t;
  causal_graph : (Hypergraph.link_id, causal_relationship list) Hashtbl.t;
}

(** PLN Logic Types (L dimension) *)
type pln_logic_type =
  | And_logic
  | Or_logic
  | Not_logic
  | Implication_logic
  | Equivalence_logic
  | Inheritance_logic
  | Similarity_logic
  | Evaluation_logic

(** PLN Probability States (P dimension) *)
type pln_probability_state =
  | True_state of float    (** Probability of being true *)
  | False_state of float   (** Probability of being false *)
  | Unknown_state of float (** Probability of being unknown *)
  | Contradictory_state of float (** Probability of contradiction *)

(** PLN Node Tensor (L, P) - Logic types × Probability states *)
type pln_tensor = {
  logic_types : pln_logic_type array;       (** L dimension *)
  probability_states : pln_probability_state array; (** P dimension *)
  tensor_data : float array array;          (** (L × P) matrix *)
  associated_node : Hypergraph.node_id option;
}

(** Inference context *)
type inference_context = {
  premises : Hypergraph.link_id list;
  conclusion : Hypergraph.link_id option;
  confidence_threshold : float;
  strength_threshold : float;
}

(** Inference result *)
type inference_result = {
  conclusion_link : Hypergraph.link_id;
  applied_rule : pln_rule;
  truth_value : float * float;
  confidence : float;
  premises_used : Hypergraph.link_id list;
}

(** MOSES (Meta-Optimizing Semantic Evolutionary Search) candidate *)
type moses_candidate = {
  program : string; (** S-expression representation *)
  fitness : float;
  complexity : int;
  generation : int;
}

(** MOSES genetic operation types *)
type moses_operation =
  | Crossover of moses_candidate * moses_candidate
  | Mutation of moses_candidate * float  (** candidate and mutation rate *)
  | Selection of moses_candidate list * int  (** population and selection size *)

(** MOSES population statistics *)
type moses_stats = {
  generation : int;
  best_fitness : float;
  average_fitness : float;
  diversity_score : float;
  convergence_rate : float;
}

(** Reasoning engine state *)
type reasoning_engine = {
  atomspace : Hypergraph.atomspace;
  pln_rules : pln_rule list;
  mutable moses_population : moses_candidate list;
  inference_cache : (Hypergraph.link_id list, inference_result) Hashtbl.t;
  mutable inference_count : int;
}

(** Create reasoning engine *)
val create_reasoning_engine : Hypergraph.atomspace -> reasoning_engine

(** PLN Tensor Operations *)

(** Default logic types for PLN tensors *)
val default_logic_types : pln_logic_type array

(** Default probability states for PLN tensors *)
val default_probability_states : pln_probability_state array

(** Create PLN tensor with specified dimensions *)
val create_pln_tensor : pln_logic_type array -> pln_probability_state array -> Hypergraph.node_id option -> pln_tensor

(** Create PLN tensor with default dimensions *)
val create_default_pln_tensor : Hypergraph.node_id option -> pln_tensor

(** Set value in PLN tensor *)
val set_pln_tensor_value : pln_tensor -> int -> int -> float -> unit

(** Get value from PLN tensor *)
val get_pln_tensor_value : pln_tensor -> int -> int -> float

(** Get PLN tensor dimensions *)
val get_pln_tensor_dimensions : pln_tensor -> int * int

(** Convert PLN tensor to flat array for backend operations *)
val pln_tensor_to_flat_array : pln_tensor -> float array

(** Convert flat array back to PLN tensor data *)
val flat_array_to_pln_tensor_data : float array -> int -> int -> float array array

(** Integration with tensor backend *)

(** Store PLN tensor in atomspace using tensor backend *)
val store_pln_tensor_in_atomspace : Hypergraph.atomspace -> pln_tensor -> Hypergraph.tensor_id

(** Load PLN tensor from atomspace *)
val load_pln_tensor_from_atomspace : Hypergraph.atomspace -> Hypergraph.tensor_id -> pln_logic_type array -> pln_probability_state array -> pln_tensor option

(** PLN tensor addition using backend *)
val add_pln_tensors : Hypergraph.atomspace -> pln_tensor -> pln_tensor -> pln_tensor

(** PLN tensor multiplication using backend *)
val multiply_pln_tensors : Hypergraph.atomspace -> pln_tensor -> pln_tensor -> pln_tensor

(** PLN Rule application with tensors *)

(** Initialize PLN tensor for a node based on rule type *)
val initialize_pln_tensor_for_rule : pln_rule -> Hypergraph.node_id -> pln_tensor

(** Compute confidence from PLN tensor *)
val compute_confidence_from_pln_tensor : pln_tensor -> float

(** Extract truth value from PLN tensor *)
val extract_truth_value_from_pln_tensor : pln_tensor -> float * float

(** String representations and debugging *)

(** Convert PLN logic type to string *)
val pln_logic_type_to_string : pln_logic_type -> string

(** Convert PLN probability state to string *)
val pln_probability_state_to_string : pln_probability_state -> string

(** Convert PLN tensor to string representation *)
val pln_tensor_to_string : pln_tensor -> string

(** PLN (Probabilistic Logic Networks) operations *)
val apply_pln_rule : reasoning_engine -> pln_rule -> inference_context -> inference_result option

val forward_chaining : reasoning_engine -> int -> inference_result list

val backward_chaining : reasoning_engine -> Hypergraph.link_id -> inference_result list

val find_applicable_rules : reasoning_engine -> Hypergraph.link_id list -> (pln_rule * inference_context) list

(** Truth value revision and combination *)
val revise_truth_values : (float * float) -> (float * float) -> (float * float)

val combine_truth_values : (float * float) list -> (float * float)

val calculate_confidence : inference_result -> float

(** MOSES (Meta-Optimizing Semantic Evolutionary Search) stubs *)
val initialize_moses_population : reasoning_engine -> int -> unit

val evolve_moses_generation : reasoning_engine -> unit

val evaluate_moses_candidate : reasoning_engine -> moses_candidate -> float

val get_best_moses_candidates : reasoning_engine -> int -> moses_candidate list

val moses_candidate_to_atomspace : reasoning_engine -> moses_candidate -> Hypergraph.link_id option

(** Enhanced MOSES genetic operations *)
val moses_crossover : moses_candidate -> moses_candidate -> moses_candidate * moses_candidate

val moses_mutate : moses_candidate -> float -> moses_candidate

val moses_selection : moses_candidate list -> int -> moses_candidate list

val moses_tournament_selection : moses_candidate list -> int -> int -> moses_candidate list

val calculate_population_diversity : moses_candidate list -> float

val get_moses_statistics : reasoning_engine -> moses_stats

(** Advanced MOSES program generation *)
val generate_complex_program : int -> string

val parse_sexpr_to_ast : string -> string  (** Simple AST representation *)

val ast_to_sexpr : string -> string

val evaluate_program_semantics : reasoning_engine -> string -> float

(** Integration between MOSES and PLN *)
val moses_candidate_to_pln_rule : reasoning_engine -> moses_candidate -> pln_rule option

val pln_rule_to_moses_candidate : reasoning_engine -> pln_rule -> moses_candidate

val evolve_pln_rules_with_moses : reasoning_engine -> int -> pln_rule list

val apply_moses_optimized_inference : reasoning_engine -> Hypergraph.link_id list -> inference_result list

(** Pattern mining and discovery *)
val discover_patterns : reasoning_engine -> int -> Hypergraph.link_id list

val find_frequent_subgraphs : reasoning_engine -> float -> Hypergraph.link_id list

val extract_association_rules : reasoning_engine -> float -> (Hypergraph.link_id * Hypergraph.link_id * float) list

(** Meta-cognition and introspection *)
val analyze_reasoning_performance : reasoning_engine -> (pln_rule * float * int) list

val suggest_new_rules : reasoning_engine -> pln_rule list

val self_modify_rules : reasoning_engine -> unit

(** Attention-guided reasoning *)
val attention_guided_inference : reasoning_engine -> Attention_system.ecan_system -> inference_result list

val focus_reasoning : reasoning_engine -> Hypergraph.node_id list -> inference_result list

(** Integration with task system *)
val create_reasoning_tasks : reasoning_engine -> Hypergraph.node_id list -> Task_system.cognitive_task list

val execute_reasoning_task : reasoning_engine -> Task_system.cognitive_task -> unit

(** Scheme representation *)
val pln_rule_to_scheme : pln_rule -> string

val inference_result_to_scheme : inference_result -> string

val moses_candidate_to_scheme : moses_candidate -> string

val reasoning_engine_to_scheme : reasoning_engine -> string

(** Temporal Logic Operations *)
val create_temporal_state : int -> int -> temporal_state

val evaluate_temporal_formula : reasoning_engine -> temporal_state -> temporal_formula -> bool

val apply_temporal_operator : temporal_operator -> Hypergraph.link_id list -> int -> temporal_state -> bool

val advance_temporal_state : temporal_state -> unit

val add_temporal_knowledge : temporal_state -> int -> Hypergraph.link_id -> unit

val get_temporal_knowledge : temporal_state -> int -> Hypergraph.link_id list

(** Causal Reasoning Operations *)
val create_causal_relationship : Hypergraph.link_id -> Hypergraph.link_id -> causal_relation_type -> causal_strength -> causal_relationship

val add_causal_relationship : temporal_state -> causal_relationship -> unit

val discover_causal_relationships : reasoning_engine -> temporal_state -> float -> causal_relationship list

val causal_intervention : reasoning_engine -> temporal_state -> Hypergraph.link_id -> float -> temporal_state

val counterfactual_reasoning : reasoning_engine -> temporal_state -> Hypergraph.link_id -> temporal_state

val compute_causal_strength : reasoning_engine -> temporal_state -> Hypergraph.link_id -> Hypergraph.link_id -> causal_strength

val find_causal_path : temporal_state -> Hypergraph.link_id -> Hypergraph.link_id -> causal_relationship list option

(** Pearl's Causal Hierarchy *)
val observational_query : reasoning_engine -> temporal_state -> Hypergraph.link_id -> float

val interventional_query : reasoning_engine -> temporal_state -> Hypergraph.link_id -> Hypergraph.link_id -> float

val counterfactual_query : reasoning_engine -> temporal_state -> Hypergraph.link_id -> Hypergraph.link_id -> float

(** Integration Functions *)
val temporal_causal_inference : reasoning_engine -> temporal_state -> temporal_formula -> inference_result list

val update_reasoning_engine_with_temporal : reasoning_engine -> temporal_state -> reasoning_engine