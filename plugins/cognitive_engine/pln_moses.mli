(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** PLN-MOSES Integration Interface
    
    Integrates PLN reasoning with MOSES evolutionary search.
*)

open Pln_formulas
open Moses_programs

(** {1 Rule Representation} *)

(** Rule types *)
type rule_type =
  | InferenceRule
  | TransformRule
  | ControlRule
  | MetaRule

(** A PLN rule as a MOSES program *)
type pln_rule_program = {
  name: string;
  program: program;
  rule_type: rule_type;
  applicability: sexpr;
  mutable success_count: int;
  mutable failure_count: int;
  mutable avg_confidence_gain: float;
}

(** {1 Rule Templates} *)

val deduction_template : string
val induction_template : string
val revision_template : string

(** {1 Fitness Evaluation} *)

(** Test case for rule evaluation *)
type rule_test_case = {
  input_tvs: truth_value list;
  expected_tv: truth_value;
  weight: float;
}

(** Evaluate rule program on test cases *)
val evaluate_rule_program : program -> rule_test_case list -> float

(** Generate test cases from PLN formulas *)
val generate_deduction_test_cases : int -> rule_test_case list
val generate_revision_test_cases : int -> rule_test_case list

(** {1 Rule Evolution} *)

(** Evolution configuration *)
type evolution_config = {
  population_size: int;
  max_generations: int;
  mutation_rate: float;
  crossover_rate: float;
  elitism: int;
  test_cases: rule_test_case list;
  target_fitness: float;
}

(** Create default configuration *)
val default_config : rule_test_case list -> evolution_config

(** Evolve a PLN rule using MOSES *)
val evolve_rule : evolution_config -> program

(** {1 Rule Selection} *)

(** Selection strategies *)
type rule_selection_strategy =
  | RandomSelection
  | FitnessProportional
  | UCB1 of float
  | ThompsonSampling
  | EpsilonGreedy of float

(** Rule selector *)
type rule_selector

(** Create a rule selector *)
val create_selector : pln_rule_program list -> rule_selection_strategy -> rule_selector

(** Select a rule to apply *)
val select_rule : rule_selector -> pln_rule_program option

(** Update rule statistics *)
val update_rule_stats : pln_rule_program -> bool -> float -> unit

(** {1 Inference Strategy} *)

(** Inference strategy *)
type inference_strategy = {
  name: string;
  selector_program: program;
  termination_program: program;
  mutable applications: int;
  mutable successes: int;
}

(** Evaluate strategy on reasoning task *)
val evaluate_strategy : inference_strategy -> 'a -> truth_value -> int -> bool

(** {1 Meta-Learning} *)

(** Rule co-occurrence tracking *)
type rule_cooccurrence = {
  rule1_idx: int;
  rule2_idx: int;
  mutable cooccurrence_count: int;
  mutable success_when_together: int;
}

(** Track rule co-occurrences *)
val track_cooccurrence : rule_cooccurrence list -> int -> int -> bool -> rule_cooccurrence list

(** {1 Standard Rules} *)

(** Standard PLN rules library *)
val standard_rules : pln_rule_program list

(** {1 Serialization} *)

val rule_type_to_string : rule_type -> string
val pln_rule_to_scheme : pln_rule_program -> string
val selector_to_scheme : rule_selector -> string
val evolution_result_to_scheme : program -> int -> string
