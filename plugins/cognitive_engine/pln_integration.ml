(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** PLN Integration Module
    
    This module integrates the PLN truth value formulas with the
    reasoning engine and hypergraph atomspace.
*)

open Pln_formulas

(** Extract truth value from a hypergraph link *)
let get_link_truth_value atomspace link_id =
  match Hypergraph.get_link atomspace link_id with
  | Some link ->
    make_tv link.strength link.confidence
  | None ->
    make_tv 0.5 0.0  (* Unknown *)

(** Extract truth value from a hypergraph node *)
let get_node_truth_value atomspace node_id =
  match Hypergraph.get_node atomspace node_id with
  | Some node ->
    make_tv node.strength node.confidence
  | None ->
    make_tv 0.5 0.0  (* Unknown *)

(** Update link with new truth value *)
let update_link_truth_value atomspace link_id tv =
  match Hypergraph.get_link atomspace link_id with
  | Some link ->
    let updated_link = { link with
      strength = tv.strength;
      confidence = tv.confidence;
    } in
    Hypergraph.update_link atomspace link_id updated_link
  | None -> ()

(** Update node with new truth value *)
let update_node_truth_value atomspace node_id tv =
  match Hypergraph.get_node atomspace node_id with
  | Some node ->
    let updated_node = { node with
      strength = tv.strength;
      confidence = tv.confidence;
    } in
    Hypergraph.update_node atomspace node_id updated_node
  | None -> ()

(** ================================================================== *)
(** PLN Rule Application with Real Formulas *)
(** ================================================================== *)

(** Apply deduction rule: A->B, B->C |- A->C
    
    Finds implication links that can be chained and computes
    the resulting truth value using PLN deduction formula.
*)
let apply_deduction atomspace premise1_id premise2_id =
  let tv1 = get_link_truth_value atomspace premise1_id in
  let tv2 = get_link_truth_value atomspace premise2_id in
  
  (* Get the intermediate node (B) for full deduction *)
  let tv_b = match Hypergraph.get_link atomspace premise1_id with
    | Some link when List.length link.outgoing >= 2 ->
      let b_id = List.nth link.outgoing 1 in
      get_node_truth_value atomspace b_id
    | _ -> make_tv 0.5 0.5
  in
  
  let result_tv = deduction tv1 tv2 tv_b in
  
  (* Create the conclusion link A->C *)
  let (a_id, c_id) = match 
    Hypergraph.get_link atomspace premise1_id,
    Hypergraph.get_link atomspace premise2_id 
  with
    | Some l1, Some l2 when List.length l1.outgoing >= 1 && List.length l2.outgoing >= 2 ->
      (List.hd l1.outgoing, List.nth l2.outgoing 1)
    | _ -> (0, 0)
  in
  
  if a_id > 0 && c_id > 0 then begin
    let new_link_id = Hypergraph.add_link atomspace Hypergraph.Implication [a_id; c_id] in
    update_link_truth_value atomspace new_link_id result_tv;
    Some (new_link_id, result_tv)
  end else
    None

(** Apply induction rule: A->B, A->C |- B->C *)
let apply_induction atomspace premise1_id premise2_id =
  let tv1 = get_link_truth_value atomspace premise1_id in
  let tv2 = get_link_truth_value atomspace premise2_id in
  
  (* Get the common antecedent (A) *)
  let tv_a = match Hypergraph.get_link atomspace premise1_id with
    | Some link when List.length link.outgoing >= 1 ->
      let a_id = List.hd link.outgoing in
      get_node_truth_value atomspace a_id
    | _ -> make_tv 0.5 0.5
  in
  
  let result_tv = induction tv1 tv2 tv_a in
  
  (* Create the conclusion link B->C *)
  let (b_id, c_id) = match 
    Hypergraph.get_link atomspace premise1_id,
    Hypergraph.get_link atomspace premise2_id 
  with
    | Some l1, Some l2 when List.length l1.outgoing >= 2 && List.length l2.outgoing >= 2 ->
      (List.nth l1.outgoing 1, List.nth l2.outgoing 1)
    | _ -> (0, 0)
  in
  
  if b_id > 0 && c_id > 0 then begin
    let new_link_id = Hypergraph.add_link atomspace Hypergraph.Implication [b_id; c_id] in
    update_link_truth_value atomspace new_link_id result_tv;
    Some (new_link_id, result_tv)
  end else
    None

(** Apply abduction rule: A->C, B->C |- A->B *)
let apply_abduction atomspace premise1_id premise2_id =
  let tv1 = get_link_truth_value atomspace premise1_id in
  let tv2 = get_link_truth_value atomspace premise2_id in
  
  (* Get the common consequent (C) *)
  let tv_c = match Hypergraph.get_link atomspace premise1_id with
    | Some link when List.length link.outgoing >= 2 ->
      let c_id = List.nth link.outgoing 1 in
      get_node_truth_value atomspace c_id
    | _ -> make_tv 0.5 0.5
  in
  
  let result_tv = abduction tv1 tv2 tv_c in
  
  (* Create the conclusion link A->B *)
  let (a_id, b_id) = match 
    Hypergraph.get_link atomspace premise1_id,
    Hypergraph.get_link atomspace premise2_id 
  with
    | Some l1, Some l2 when List.length l1.outgoing >= 1 && List.length l2.outgoing >= 1 ->
      (List.hd l1.outgoing, List.hd l2.outgoing)
    | _ -> (0, 0)
  in
  
  if a_id > 0 && b_id > 0 then begin
    let new_link_id = Hypergraph.add_link atomspace Hypergraph.Implication [a_id; b_id] in
    update_link_truth_value atomspace new_link_id result_tv;
    Some (new_link_id, result_tv)
  end else
    None

(** Apply revision to combine evidence for the same statement *)
let apply_revision atomspace link_id1 link_id2 =
  let tv1 = get_link_truth_value atomspace link_id1 in
  let tv2 = get_link_truth_value atomspace link_id2 in
  
  let result_tv = revision tv1 tv2 in
  
  (* Update the first link with revised truth value *)
  update_link_truth_value atomspace link_id1 result_tv;
  Some (link_id1, result_tv)

(** Apply modus ponens: A, A->B |- B *)
let apply_modus_ponens atomspace node_id impl_link_id =
  let tv_a = get_node_truth_value atomspace node_id in
  let tv_impl = get_link_truth_value atomspace impl_link_id in
  
  let result_tv = modus_ponens tv_a tv_impl in
  
  (* Get the consequent node B and update its truth value *)
  match Hypergraph.get_link atomspace impl_link_id with
  | Some link when List.length link.outgoing >= 2 ->
    let b_id = List.nth link.outgoing 1 in
    update_node_truth_value atomspace b_id result_tv;
    Some (b_id, result_tv)
  | _ -> None

(** ================================================================== *)
(** Logical Operations *)
(** ================================================================== *)

(** Compute conjunction of two nodes *)
let compute_conjunction atomspace node1_id node2_id =
  let tv1 = get_node_truth_value atomspace node1_id in
  let tv2 = get_node_truth_value atomspace node2_id in
  conjunction tv1 tv2

(** Compute disjunction of two nodes *)
let compute_disjunction atomspace node1_id node2_id =
  let tv1 = get_node_truth_value atomspace node1_id in
  let tv2 = get_node_truth_value atomspace node2_id in
  disjunction tv1 tv2

(** Compute negation of a node *)
let compute_negation atomspace node_id =
  let tv = get_node_truth_value atomspace node_id in
  negation tv

(** ================================================================== *)
(** Attention-Weighted Operations *)
(** ================================================================== *)

(** Revise with attention weighting *)
let attention_revise atomspace link_id1 link_id2 =
  let tv1 = get_link_truth_value atomspace link_id1 in
  let tv2 = get_link_truth_value atomspace link_id2 in
  
  (* Get attention values *)
  let sti1 = match Hypergraph.get_link atomspace link_id1 with
    | Some link -> link.attention.sti
    | None -> 1.0
  in
  let sti2 = match Hypergraph.get_link atomspace link_id2 with
    | Some link -> link.attention.sti
    | None -> 1.0
  in
  
  attention_weighted_revision tv1 tv2 sti1 sti2

(** ================================================================== *)
(** Inference Chain Building *)
(** ================================================================== *)

(** Result of an inference step *)
type inference_step = {
  rule_name: string;
  premises: int list;
  conclusion: int;
  truth_value: truth_value;
}

(** Build a deduction chain from a sequence of implications *)
let build_deduction_chain atomspace link_ids =
  let rec chain acc = function
    | [] | [_] -> List.rev acc
    | l1 :: l2 :: rest ->
      match apply_deduction atomspace l1 l2 with
      | Some (new_id, tv) ->
        let step = {
          rule_name = "deduction";
          premises = [l1; l2];
          conclusion = new_id;
          truth_value = tv;
        } in
        chain (step :: acc) (new_id :: rest)
      | None -> List.rev acc
  in
  chain [] link_ids

(** ================================================================== *)
(** Query Interface *)
(** ================================================================== *)

(** Query the truth value of a statement *)
let query_truth atomspace link_id =
  let tv = get_link_truth_value atomspace link_id in
  if is_true tv then
    `True tv
  else if is_false tv then
    `False tv
  else
    `Unknown tv

(** Find all links with truth value above threshold *)
let find_true_links atomspace ?(threshold=0.5) () =
  let all_links = Hypergraph.get_all_links atomspace in
  List.filter (fun link_id ->
    let tv = get_link_truth_value atomspace link_id in
    is_true ~threshold tv
  ) all_links

(** Find all uncertain links (low confidence) *)
let find_uncertain_links atomspace ?(threshold=0.3) () =
  let all_links = Hypergraph.get_all_links atomspace in
  List.filter (fun link_id ->
    let tv = get_link_truth_value atomspace link_id in
    is_unknown ~threshold tv
  ) all_links

(** ================================================================== *)
(** Scheme Serialization *)
(** ================================================================== *)

(** Convert inference step to Scheme *)
let inference_step_to_scheme step =
  Printf.sprintf "(inference-step (rule %s) (premises %s) (conclusion %d) %s)"
    step.rule_name
    (String.concat " " (List.map string_of_int step.premises))
    step.conclusion
    (tv_to_scheme step.truth_value)

(** Convert inference chain to Scheme *)
let inference_chain_to_scheme steps =
  let steps_str = String.concat "\n  " (List.map inference_step_to_scheme steps) in
  Printf.sprintf "(inference-chain\n  %s)" steps_str
