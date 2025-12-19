(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** PLN Truth Value Formulas Interface
    
    This module provides the core Probabilistic Logic Networks (PLN)
    truth value formulas for probabilistic reasoning.
*)

(** {1 Truth Value Type} *)

(** Truth value representation with strength, confidence, and count *)
type truth_value = {
  strength: float;     (** Probability estimate [0, 1] *)
  confidence: float;   (** Confidence in the estimate [0, 1] *)
  count: float;        (** Evidence count (derived from confidence) *)
}

(** {1 Truth Value Construction} *)

(** Create truth value from strength and confidence *)
val make_tv : float -> float -> truth_value

(** Create truth value from strength and evidence count *)
val make_tv_from_count : float -> float -> truth_value

(** Convert confidence to evidence count *)
val confidence_to_count : ?k:float -> float -> float

(** Convert evidence count to confidence *)
val count_to_confidence : ?k:float -> float -> float

(** {1 First-Order PLN Formulas} *)

(** Deduction: A->B, B->C, B |- A->C *)
val deduction : truth_value -> truth_value -> truth_value -> truth_value

(** Simplified deduction for independent premises: A->B, B->C |- A->C *)
val deduction_simple : truth_value -> truth_value -> truth_value

(** Induction: A->B, A->C, A |- B->C *)
val induction : truth_value -> truth_value -> truth_value -> truth_value

(** Abduction: A->C, B->C, C |- A->B *)
val abduction : truth_value -> truth_value -> truth_value -> truth_value

(** Revision: Combine multiple truth values for the same statement *)
val revision : truth_value -> truth_value -> truth_value

(** {1 Second-Order PLN Formulas} *)

(** Similarity from inheritance: A->B, B->A |- A<->B *)
val similarity_from_inheritance : truth_value -> truth_value -> truth_value

(** Inheritance from similarity: A<->B, A⊂B |- A->B *)
val inheritance_from_similarity : truth_value -> truth_value -> truth_value

(** {1 Logical Connective Formulas} *)

(** Conjunction: A, B |- A ∧ B *)
val conjunction : truth_value -> truth_value -> truth_value

(** Disjunction: A, B |- A ∨ B *)
val disjunction : truth_value -> truth_value -> truth_value

(** Negation: A |- ¬A *)
val negation : truth_value -> truth_value

(** Implication: A, B |- A → B *)
val implication : truth_value -> truth_value -> truth_value

(** Equivalence: A, B |- A ↔ B *)
val equivalence : truth_value -> truth_value -> truth_value

(** {1 Higher-Order PLN Formulas} *)

(** Modus Ponens: A, A→B |- B *)
val modus_ponens : truth_value -> truth_value -> truth_value

(** Modus Tollens: ¬B, A→B |- ¬A *)
val modus_tollens : truth_value -> truth_value -> truth_value

(** {1 Quantifier Formulas} *)

(** Universal introduction: Combine instances to form ∀x.P(x) *)
val universal_intro : truth_value list -> truth_value

(** Existential introduction: ∃x.P(x) from instances *)
val existential_intro : truth_value list -> truth_value

(** {1 Bayesian Formulas} *)

(** Bayes rule: P(A|B) from P(B|A), P(A), P(B) *)
val bayes : truth_value -> truth_value -> truth_value -> truth_value

(** {1 Temporal Logic Formulas} *)

(** Temporal deduction with time gap decay *)
val temporal_deduction : truth_value -> truth_value -> float -> truth_value

(** Predictive implication with temporal decay *)
val predictive_implication : truth_value -> float -> truth_value

(** {1 Attention-Weighted Formulas} *)

(** Attention-weighted revision with STI bias *)
val attention_weighted_revision : truth_value -> truth_value -> float -> float -> truth_value

(** {1 Utility Functions} *)

(** Convert truth value to string representation *)
val tv_to_string : truth_value -> string

(** Convert truth value to Scheme S-expression *)
val tv_to_scheme : truth_value -> string

(** Parse truth value from Scheme S-expression *)
val tv_from_scheme : string -> truth_value

(** Check if truth value represents "true" *)
val is_true : ?threshold:float -> truth_value -> bool

(** Check if truth value represents "false" *)
val is_false : ?threshold:float -> truth_value -> bool

(** Check if truth value is "unknown" (low confidence) *)
val is_unknown : ?threshold:float -> truth_value -> bool

(** Compare truth values by strength *)
val compare_by_strength : truth_value -> truth_value -> int

(** Compare truth values by confidence *)
val compare_by_confidence : truth_value -> truth_value -> int

(** Compute weighted score for ranking *)
val tv_score : ?strength_weight:float -> truth_value -> float
