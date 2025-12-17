(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** Creative Problem Solving via Combinatorial Hypergraph Traversal *)

(** Problem definition types *)
type problem_constraint = {
  required_nodes : Hypergraph.node_id list;
  forbidden_nodes : Hypergraph.node_id list;
  required_links : Hypergraph.link_id list;
  forbidden_links : Hypergraph.link_id list;
  goal_predicates : (Hypergraph.node_id -> bool) list;
}

type problem_definition = {
  initial_state : Hypergraph.node_id list;
  goal_state : Hypergraph.node_id list;
  constraints : problem_constraint;
  creativity_level : float; (* 0.0 = conservative, 1.0 = highly creative *)
  max_depth : int;
  time_limit : float;
}

(** Traversal strategy types *)
type traversal_strategy =
  | Breadth_first_creative   (** BFS with creativity heuristics *)
  | Depth_first_creative     (** DFS with backtracking and novelty *)
  | Random_walk_attention    (** Attention-guided random exploration *)
  | Genetic_traversal        (** Evolutionary path optimization *)
  | Hybrid_multi_objective   (** Multi-objective optimization approach *)

(** Solution representation *)
type solution_path = {
  nodes : Hypergraph.node_id list;
  links : Hypergraph.link_id list;
  creativity_score : float;
  novelty_score : float;
  feasibility_score : float;
  path_length : int;
  exploration_steps : int;
}

type creative_solution = {
  paths : solution_path list;
  total_exploration_time : float;
  nodes_explored : int;
  novel_associations : (Hypergraph.node_id * Hypergraph.node_id * float) list;
  generated_concepts : Hypergraph.node_id list;
}

(** Creative reasoning types *)
type analogy_mapping = {
  source_pattern : Hypergraph.node_id list;
  target_pattern : Hypergraph.node_id list;
  mapping_strength : float;
  abstraction_level : int;
}

type concept_blend = {
  input_concepts : Hypergraph.node_id list;
  blended_concept : Hypergraph.node_id;
  blend_features : (string * float) list;
  novelty_rating : float;
}

(** Creative problem solving engine *)
type creative_engine = {
  atomspace : Hypergraph.atomspace;
  reasoning_engine : Reasoning_engine.reasoning_engine;
  attention_system : Attention_system.ecan_system;
  mutable explored_paths : solution_path list;
  mutable novel_associations : (Hypergraph.node_id * Hypergraph.node_id * float) list;
  mutable creativity_history : (float * string) list;
  mutable generated_concepts : Hypergraph.node_id list;
}

(** Configuration for creative problem solving *)
type creativity_config = {
  divergent_thinking_ratio : float;     (** 0.0-1.0, balance exploration vs exploitation *)
  novelty_weight : float;               (** Importance of novelty in solutions *)
  feasibility_weight : float;           (** Importance of feasibility vs creativity *)
  attention_focus_cycles : int;         (** Cycles between focused and defocused attention *)
  concept_blending_enabled : bool;      (** Enable concept blending *)
  analogical_reasoning_enabled : bool;  (** Enable analogical reasoning *)
  constraint_relaxation_level : float;  (** How much to relax constraints *)
}

(** Create creative problem solving engine *)
val create_creative_engine : Hypergraph.atomspace -> Reasoning_engine.reasoning_engine -> Attention_system.ecan_system -> creative_engine

(** Default creativity configuration *)
val default_creativity_config : creativity_config

(** Core problem solving functions *)

(** Solve a problem using combinatorial hypergraph traversal *)
val solve_creative_problem : creative_engine -> problem_definition -> creativity_config -> traversal_strategy -> creative_solution

(** Generate multiple alternative solutions *)
val generate_alternative_solutions : creative_engine -> problem_definition -> creativity_config -> int -> creative_solution list

(** Hypergraph traversal algorithms *)

(** Breadth-first traversal with creativity heuristics *)
val breadth_first_creative_traversal : creative_engine -> Hypergraph.node_id list -> problem_constraint -> int -> solution_path list

(** Depth-first traversal with novelty seeking *)
val depth_first_creative_traversal : creative_engine -> Hypergraph.node_id list -> problem_constraint -> int -> solution_path list

(** Attention-guided random walk *)
val attention_guided_random_walk : creative_engine -> Hypergraph.node_id list -> problem_constraint -> int -> solution_path list

(** Genetic algorithm for path optimization *)
val genetic_path_optimization : creative_engine -> Hypergraph.node_id list -> problem_constraint -> int -> int -> solution_path list

(** Multi-objective traversal optimization *)
val multi_objective_traversal : creative_engine -> Hypergraph.node_id list -> problem_constraint -> creativity_config -> solution_path list

(** Creative reasoning functions *)

(** Analogical reasoning - find and apply analogies *)
val find_analogical_mappings : creative_engine -> Hypergraph.node_id list -> Hypergraph.node_id list -> analogy_mapping list

val apply_analogical_reasoning : creative_engine -> analogy_mapping -> problem_definition -> solution_path list

(** Concept blending and fusion *)
val blend_concepts : creative_engine -> Hypergraph.node_id list -> concept_blend

val generate_blended_solutions : creative_engine -> concept_blend list -> problem_definition -> solution_path list

(** Novel association discovery *)
val discover_novel_associations : creative_engine -> Hypergraph.node_id list -> float -> (Hypergraph.node_id * Hypergraph.node_id * float) list

val validate_novel_associations : creative_engine -> (Hypergraph.node_id * Hypergraph.node_id * float) list -> (Hypergraph.node_id * Hypergraph.node_id * float) list

(** Constraint relaxation for creative solutions *)
val relax_constraints : problem_constraint -> float -> problem_constraint

val progressive_constraint_relaxation : creative_engine -> problem_definition -> creativity_config -> creative_solution list

(** Attention and focus management *)

(** Implement focus/defocus cycles for creativity *)
val creative_attention_cycle : creative_engine -> problem_definition -> int -> unit

(** Shift attention to unexplored regions *)
val shift_attention_to_novel_regions : creative_engine -> Hypergraph.node_id list -> unit

(** Balance focused and diffuse thinking *)
val balance_cognitive_modes : creative_engine -> creativity_config -> float -> unit

(** Solution evaluation and ranking *)

(** Calculate creativity score for a solution *)
val calculate_creativity_score : creative_engine -> solution_path -> problem_definition -> float

(** Calculate novelty score based on exploration history *)
val calculate_novelty_score : creative_engine -> solution_path -> float

(** Calculate feasibility score using reasoning engine *)
val calculate_feasibility_score : creative_engine -> solution_path -> problem_definition -> float

(** Rank solutions by multiple criteria *)
val rank_solutions : creative_engine -> solution_path list -> creativity_config -> solution_path list

(** Meta-creative functions *)

(** Analyze creative problem-solving performance *)
val analyze_creative_performance : creative_engine -> (traversal_strategy * float * int) list

(** Suggest improvements to creativity strategy *)
val suggest_creativity_improvements : creative_engine -> creativity_config -> creativity_config

(** Self-modify creative strategies based on experience *)
val self_modify_creative_strategies : creative_engine -> creativity_config

(** Integration with existing systems *)

(** Generate creative reasoning tasks *)
val create_creative_reasoning_tasks : creative_engine -> problem_definition list -> Task_system.cognitive_task list

(** Execute creative problem solving task *)
val execute_creative_task : creative_engine -> Task_system.cognitive_task -> creative_solution

(** Integrate with neural-symbolic fusion for concept generation *)
val neural_guided_concept_generation : creative_engine -> Hypergraph.node_id list -> int -> Hypergraph.node_id list

(** Use tensor operations for similarity-based creativity *)
val tensor_similarity_creative_search : creative_engine -> Hypergraph.tensor_id list -> problem_constraint -> solution_path list

(** Scheme representation and export *)

(** Convert creative solution to Scheme representation *)
val creative_solution_to_scheme : creative_solution -> string

(** Convert problem definition to Scheme *)
val problem_definition_to_scheme : problem_definition -> string

(** Convert creativity config to Scheme *)
val creativity_config_to_scheme : creativity_config -> string

(** Export creative engine state *)
val creative_engine_to_scheme : creative_engine -> string

(** Debugging and diagnostics *)

(** Get traversal statistics *)
val get_traversal_statistics : creative_engine -> (string * int * float) list

(** Get creativity diagnostics *)
val get_creativity_diagnostics : creative_engine -> string

(** Visualize solution paths for analysis *)
val visualize_solution_paths : creative_engine -> solution_path list -> string

(** Benchmark creativity performance *)
val benchmark_creativity : creative_engine -> problem_definition list -> creativity_config list -> (traversal_strategy * float * float) list