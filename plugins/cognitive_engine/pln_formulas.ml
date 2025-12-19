(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** PLN Truth Value Formulas - Complete Implementation
    
    This module implements the core Probabilistic Logic Networks (PLN)
    truth value formulas based on the OpenCog PLN specification.
    
    Reference: OpenCog PLN Book (Goertzel et al.)
*)

(** Truth value representation *)
type truth_value = {
  strength: float;     (** Probability estimate [0, 1] *)
  confidence: float;   (** Confidence in the estimate [0, 1] *)
  count: float;        (** Evidence count (optional, derived) *)
}

(** Default confidence-to-count conversion factor *)
let k_default = 800.0

(** Convert confidence to count: n = k * c / (1 - c) *)
let confidence_to_count ?(k=k_default) confidence =
  if confidence >= 1.0 then infinity
  else k *. confidence /. (1.0 -. confidence)

(** Convert count to confidence: c = n / (n + k) *)
let count_to_confidence ?(k=k_default) count =
  count /. (count +. k)

(** Create truth value from strength and confidence *)
let make_tv strength confidence =
  let strength = max 0.0 (min 1.0 strength) in
  let confidence = max 0.0 (min 1.0 confidence) in
  { strength; confidence; count = confidence_to_count confidence }

(** Create truth value from strength and count *)
let make_tv_from_count strength count =
  let strength = max 0.0 (min 1.0 strength) in
  let count = max 0.0 count in
  { strength; confidence = count_to_confidence count; count }

(** ================================================================== *)
(** First-Order PLN Formulas *)
(** ================================================================== *)

(** Deduction: A->B, B->C |- A->C
    
    sAC = sAB * sBC + (1 - sAB) * (sC - sB * sBC) / (1 - sB)
    
    When sB = 1, use limit: sAC = sAB * sBC
*)
let deduction tv_ab tv_bc tv_b =
  let s_ab = tv_ab.strength in
  let s_bc = tv_bc.strength in
  let s_b = tv_b.strength in
  let s_c = s_bc in (* Approximation when C's TV is not available *)
  
  let strength =
    if s_b >= 0.9999 then
      s_ab *. s_bc
    else
      s_ab *. s_bc +. (1.0 -. s_ab) *. (s_c -. s_b *. s_bc) /. (1.0 -. s_b)
  in
  
  (* Confidence decreases with chain length *)
  let confidence = tv_ab.confidence *. tv_bc.confidence *. tv_b.confidence in
  
  make_tv strength confidence

(** Deduction with independent premises (simplified)
    sAC = sAB * sBC
*)
let deduction_simple tv_ab tv_bc =
  let strength = tv_ab.strength *. tv_bc.strength in
  let confidence = tv_ab.confidence *. tv_bc.confidence in
  make_tv strength confidence

(** Induction: A->B, A->C |- B->C
    
    sBC = sAB * sAC + (1 - sAB) * sC
    
    This is a weaker form of inference with lower confidence.
*)
let induction tv_ab tv_ac tv_a =
  let s_ab = tv_ab.strength in
  let s_ac = tv_ac.strength in
  let s_a = tv_a.strength in
  let s_c = tv_ac.strength in (* Approximation *)
  
  let strength =
    if s_a >= 0.9999 then
      s_ab *. s_ac
    else
      (s_ab *. s_ac +. (1.0 -. s_ab) *. s_c *. (1.0 -. s_a)) /. 
      (s_ab *. s_a +. (1.0 -. s_ab) *. (1.0 -. s_a))
  in
  
  (* Induction has lower confidence than deduction *)
  let confidence = tv_ab.confidence *. tv_ac.confidence *. tv_a.confidence *. 0.5 in
  
  make_tv strength confidence

(** Abduction: A->C, B->C |- A->B
    
    Similar to induction but reasoning backwards from effects.
*)
let abduction tv_ac tv_bc tv_c =
  let s_ac = tv_ac.strength in
  let s_bc = tv_bc.strength in
  let s_c = tv_c.strength in
  
  let strength =
    if s_c >= 0.9999 then
      s_ac *. s_bc
    else
      (s_ac *. s_bc *. s_c) /. 
      (s_ac *. s_c +. (1.0 -. s_ac) *. (1.0 -. s_c))
  in
  
  (* Abduction has even lower confidence *)
  let confidence = tv_ac.confidence *. tv_bc.confidence *. tv_c.confidence *. 0.3 in
  
  make_tv strength confidence

(** Revision: Combine multiple truth values for the same statement
    
    s_new = (s1 * c1 + s2 * c2) / (c1 + c2)
    c_new = c1 + c2 - c1 * c2 (for independent evidence)
    
    Using count-based formula for more accuracy:
    n_new = n1 + n2
    s_new = (s1 * n1 + s2 * n2) / n_new
*)
let revision tv1 tv2 =
  let n1 = tv1.count in
  let n2 = tv2.count in
  let n_new = n1 +. n2 in
  
  let strength =
    if n_new > 0.0 then
      (tv1.strength *. n1 +. tv2.strength *. n2) /. n_new
    else
      (tv1.strength +. tv2.strength) /. 2.0
  in
  
  make_tv_from_count strength n_new

(** ================================================================== *)
(** Second-Order PLN Formulas (Similarity, Inheritance) *)
(** ================================================================== *)

(** Similarity from Inheritance: A->B, B->A |- A<->B
    
    sAB_sim = sAB_inh * sBa_inh
*)
let similarity_from_inheritance tv_ab tv_ba =
  let strength = tv_ab.strength *. tv_ba.strength in
  let confidence = tv_ab.confidence *. tv_ba.confidence in
  make_tv strength confidence

(** Inheritance from Similarity and Subset: A<->B, A⊂B |- A->B
    
    sAB_inh = sAB_sim / sA_subset_B
*)
let inheritance_from_similarity tv_sim tv_subset =
  let strength =
    if tv_subset.strength > 0.0 then
      tv_sim.strength /. tv_subset.strength
    else
      tv_sim.strength
  in
  let confidence = tv_sim.confidence *. tv_subset.confidence in
  make_tv (min 1.0 strength) confidence

(** ================================================================== *)
(** Logical Connective Formulas *)
(** ================================================================== *)

(** AND: A, B |- A ∧ B
    
    For independent A and B: s(A∧B) = sA * sB
*)
let conjunction tv_a tv_b =
  let strength = tv_a.strength *. tv_b.strength in
  let confidence = tv_a.confidence *. tv_b.confidence in
  make_tv strength confidence

(** OR: A, B |- A ∨ B
    
    For independent A and B: s(A∨B) = sA + sB - sA * sB
*)
let disjunction tv_a tv_b =
  let s_a = tv_a.strength in
  let s_b = tv_b.strength in
  let strength = s_a +. s_b -. s_a *. s_b in
  let confidence = tv_a.confidence *. tv_b.confidence in
  make_tv strength confidence

(** NOT: A |- ¬A
    
    s(¬A) = 1 - sA
*)
let negation tv_a =
  let strength = 1.0 -. tv_a.strength in
  make_tv strength tv_a.confidence

(** Implication: A, B |- A → B
    
    s(A→B) = sB / sA (when sA > 0)
    
    More sophisticated: s(A→B) = s(A∧B) / sA
*)
let implication tv_a tv_b =
  let strength =
    if tv_a.strength > 0.0 then
      min 1.0 (tv_b.strength /. tv_a.strength)
    else
      1.0 (* Vacuously true *)
  in
  let confidence = tv_a.confidence *. tv_b.confidence in
  make_tv strength confidence

(** Equivalence: A, B |- A ↔ B
    
    s(A↔B) = s(A→B) * s(B→A)
*)
let equivalence tv_a tv_b =
  let tv_ab = implication tv_a tv_b in
  let tv_ba = implication tv_b tv_a in
  let strength = tv_ab.strength *. tv_ba.strength in
  let confidence = tv_ab.confidence *. tv_ba.confidence in
  make_tv strength confidence

(** ================================================================== *)
(** Higher-Order PLN Formulas *)
(** ================================================================== *)

(** Modus Ponens: A, A→B |- B
    
    sB = sA * s(A→B) + (1 - sA) * sB_prior
    
    When prior is unknown, use: sB = sA * s(A→B)
*)
let modus_ponens tv_a tv_impl =
  let strength = tv_a.strength *. tv_impl.strength in
  let confidence = tv_a.confidence *. tv_impl.confidence in
  make_tv strength confidence

(** Modus Tollens: ¬B, A→B |- ¬A
    
    s(¬A) = s(¬B) * s(A→B) / (s(¬B) * s(A→B) + (1 - s(A→B)))
*)
let modus_tollens tv_not_b tv_impl =
  let s_not_b = tv_not_b.strength in
  let s_impl = tv_impl.strength in
  
  let denominator = s_not_b *. s_impl +. (1.0 -. s_impl) in
  let strength =
    if denominator > 0.0 then
      s_not_b *. s_impl /. denominator
    else
      0.5
  in
  let confidence = tv_not_b.confidence *. tv_impl.confidence *. 0.8 in
  make_tv strength confidence

(** ================================================================== *)
(** Quantifier Formulas *)
(** ================================================================== *)

(** Universal Introduction: Combine instances to form ∀x.P(x)
    
    Uses minimum strength across instances with adjusted confidence.
*)
let universal_intro instances =
  if instances = [] then
    make_tv 1.0 0.0
  else
    let min_strength = List.fold_left (fun acc tv -> min acc tv.strength) 1.0 instances in
    let avg_confidence = 
      (List.fold_left (fun acc tv -> acc +. tv.confidence) 0.0 instances) /.
      float_of_int (List.length instances)
    in
    (* Confidence increases with number of instances *)
    let n = float_of_int (List.length instances) in
    let confidence = avg_confidence *. (1.0 -. 1.0 /. (n +. 1.0)) in
    make_tv min_strength confidence

(** Existential Introduction: ∃x.P(x) from P(a)
    
    Uses maximum strength across instances.
*)
let existential_intro instances =
  if instances = [] then
    make_tv 0.0 0.0
  else
    let max_strength = List.fold_left (fun acc tv -> max acc tv.strength) 0.0 instances in
    let max_confidence = List.fold_left (fun acc tv -> max acc tv.confidence) 0.0 instances in
    make_tv max_strength max_confidence

(** ================================================================== *)
(** Bayesian Formulas *)
(** ================================================================== *)

(** Bayes Rule: P(A|B) from P(B|A), P(A), P(B)
    
    P(A|B) = P(B|A) * P(A) / P(B)
*)
let bayes tv_b_given_a tv_a tv_b =
  let strength =
    if tv_b.strength > 0.0 then
      min 1.0 (tv_b_given_a.strength *. tv_a.strength /. tv_b.strength)
    else
      0.5
  in
  let confidence = tv_b_given_a.confidence *. tv_a.confidence *. tv_b.confidence in
  make_tv strength confidence

(** ================================================================== *)
(** Temporal Logic Formulas *)
(** ================================================================== *)

(** Temporal Deduction: A(t)->B(t), B(t)->C(t+1) |- A(t)->C(t+1)
    
    Accounts for temporal decay in confidence.
*)
let temporal_deduction tv_ab tv_bc time_gap =
  let decay_factor = exp (-0.1 *. time_gap) in
  let strength = tv_ab.strength *. tv_bc.strength in
  let confidence = tv_ab.confidence *. tv_bc.confidence *. decay_factor in
  make_tv strength confidence

(** Predictive Implication: A(t) -> B(t+delta)
    
    Strength decays with temporal distance.
*)
let predictive_implication tv_base delta =
  let decay = exp (-0.05 *. delta) in
  let strength = tv_base.strength *. decay in
  let confidence = tv_base.confidence *. decay in
  make_tv strength confidence

(** ================================================================== *)
(** Attention-Weighted Formulas *)
(** ================================================================== *)

(** Attention-weighted revision: Combine with attention bias *)
let attention_weighted_revision tv1 tv2 sti1 sti2 =
  let total_sti = sti1 +. sti2 in
  if total_sti <= 0.0 then
    revision tv1 tv2
  else
    let w1 = sti1 /. total_sti in
    let w2 = sti2 /. total_sti in
    let strength = tv1.strength *. w1 +. tv2.strength *. w2 in
    let confidence = tv1.confidence *. w1 +. tv2.confidence *. w2 in
    make_tv strength confidence

(** ================================================================== *)
(** Utility Functions *)
(** ================================================================== *)

(** Truth value to string *)
let tv_to_string tv =
  Printf.sprintf "<%.4f, %.4f>" tv.strength tv.confidence

(** Truth value to Scheme S-expression *)
let tv_to_scheme tv =
  Printf.sprintf "(stv %.6f %.6f)" tv.strength tv.confidence

(** Parse truth value from Scheme *)
let tv_from_scheme str =
  try
    Scanf.sscanf str "(stv %f %f)" (fun s c -> make_tv s c)
  with _ ->
    make_tv 0.5 0.0

(** Check if truth value is "true" (high strength and confidence) *)
let is_true ?(threshold=0.5) tv =
  tv.strength >= threshold && tv.confidence >= 0.5

(** Check if truth value is "false" (low strength, high confidence) *)
let is_false ?(threshold=0.5) tv =
  tv.strength < threshold && tv.confidence >= 0.5

(** Check if truth value is "unknown" (low confidence) *)
let is_unknown ?(threshold=0.3) tv =
  tv.confidence < threshold

(** Compare truth values by strength *)
let compare_by_strength tv1 tv2 =
  compare tv1.strength tv2.strength

(** Compare truth values by confidence *)
let compare_by_confidence tv1 tv2 =
  compare tv1.confidence tv2.confidence

(** Weighted combination of strength and confidence for ranking *)
let tv_score ?(strength_weight=0.7) tv =
  strength_weight *. tv.strength +. (1.0 -. strength_weight) *. tv.confidence
