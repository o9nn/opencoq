(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** PLN Integration Module Interface
    
    This module provides integration between PLN truth value formulas
    and the hypergraph atomspace for probabilistic reasoning.
*)

(** {1 Truth Value Extraction} *)

(** Extract truth value from a hypergraph link *)
val get_link_truth_value : Hypergraph.atomspace -> Hypergraph.link_id -> Pln_formulas.truth_value

(** Extract truth value from a hypergraph node *)
val get_node_truth_value : Hypergraph.atomspace -> Hypergraph.node_id -> Pln_formulas.truth_value

(** Update link with new truth value *)
val update_link_truth_value : Hypergraph.atomspace -> Hypergraph.link_id -> Pln_formulas.truth_value -> unit

(** Update node with new truth value *)
val update_node_truth_value : Hypergraph.atomspace -> Hypergraph.node_id -> Pln_formulas.truth_value -> unit

(** {1 PLN Rule Application} *)

(** Apply deduction rule: A->B, B->C |- A->C
    Returns the new link ID and its truth value *)
val apply_deduction : Hypergraph.atomspace -> Hypergraph.link_id -> Hypergraph.link_id -> 
  (Hypergraph.link_id * Pln_formulas.truth_value) option

(** Apply induction rule: A->B, A->C |- B->C *)
val apply_induction : Hypergraph.atomspace -> Hypergraph.link_id -> Hypergraph.link_id -> 
  (Hypergraph.link_id * Pln_formulas.truth_value) option

(** Apply abduction rule: A->C, B->C |- A->B *)
val apply_abduction : Hypergraph.atomspace -> Hypergraph.link_id -> Hypergraph.link_id -> 
  (Hypergraph.link_id * Pln_formulas.truth_value) option

(** Apply revision to combine evidence *)
val apply_revision : Hypergraph.atomspace -> Hypergraph.link_id -> Hypergraph.link_id -> 
  (Hypergraph.link_id * Pln_formulas.truth_value) option

(** Apply modus ponens: A, A->B |- B *)
val apply_modus_ponens : Hypergraph.atomspace -> Hypergraph.node_id -> Hypergraph.link_id -> 
  (Hypergraph.node_id * Pln_formulas.truth_value) option

(** {1 Logical Operations} *)

(** Compute conjunction of two nodes *)
val compute_conjunction : Hypergraph.atomspace -> Hypergraph.node_id -> Hypergraph.node_id -> Pln_formulas.truth_value

(** Compute disjunction of two nodes *)
val compute_disjunction : Hypergraph.atomspace -> Hypergraph.node_id -> Hypergraph.node_id -> Pln_formulas.truth_value

(** Compute negation of a node *)
val compute_negation : Hypergraph.atomspace -> Hypergraph.node_id -> Pln_formulas.truth_value

(** {1 Attention-Weighted Operations} *)

(** Revise with attention weighting *)
val attention_revise : Hypergraph.atomspace -> Hypergraph.link_id -> Hypergraph.link_id -> Pln_formulas.truth_value

(** {1 Inference Chain Building} *)

(** Result of an inference step *)
type inference_step = {
  rule_name: string;
  premises: int list;
  conclusion: int;
  truth_value: Pln_formulas.truth_value;
}

(** Build a deduction chain from a sequence of implications *)
val build_deduction_chain : Hypergraph.atomspace -> Hypergraph.link_id list -> inference_step list

(** {1 Query Interface} *)

(** Query the truth value of a statement *)
val query_truth : Hypergraph.atomspace -> Hypergraph.link_id -> 
  [> `True of Pln_formulas.truth_value | `False of Pln_formulas.truth_value | `Unknown of Pln_formulas.truth_value ]

(** Find all links with truth value above threshold *)
val find_true_links : Hypergraph.atomspace -> ?threshold:float -> unit -> Hypergraph.link_id list

(** Find all uncertain links (low confidence) *)
val find_uncertain_links : Hypergraph.atomspace -> ?threshold:float -> unit -> Hypergraph.link_id list

(** {1 Scheme Serialization} *)

(** Convert inference step to Scheme S-expression *)
val inference_step_to_scheme : inference_step -> string

(** Convert inference chain to Scheme S-expression *)
val inference_chain_to_scheme : inference_step list -> string
