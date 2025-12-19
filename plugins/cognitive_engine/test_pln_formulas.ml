(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** Test Suite for PLN Truth Value Formulas *)

open Pln_formulas

(** Test utilities *)
let test_count = ref 0
let pass_count = ref 0
let fail_count = ref 0

let assert_float_eq ?(eps=0.001) expected actual name =
  incr test_count;
  if abs_float (expected -. actual) < eps then begin
    incr pass_count;
    Printf.printf "  ✅ %s: expected %.4f, got %.4f\n" name expected actual
  end else begin
    incr fail_count;
    Printf.printf "  ❌ %s: expected %.4f, got %.4f\n" name expected actual
  end

let assert_tv_valid tv name =
  incr test_count;
  if tv.strength >= 0.0 && tv.strength <= 1.0 &&
     tv.confidence >= 0.0 && tv.confidence <= 1.0 then begin
    incr pass_count;
    Printf.printf "  ✅ %s: TV is valid %s\n" name (tv_to_string tv)
  end else begin
    incr fail_count;
    Printf.printf "  ❌ %s: TV is invalid %s\n" name (tv_to_string tv)
  end

let section name =
  Printf.printf "\n=== %s ===\n" name

(** Test cases *)

let test_truth_value_construction () =
  section "Truth Value Construction";
  
  let tv1 = make_tv 0.8 0.9 in
  assert_float_eq 0.8 tv1.strength "make_tv strength";
  assert_float_eq 0.9 tv1.confidence "make_tv confidence";
  assert_tv_valid tv1 "make_tv";
  
  let tv2 = make_tv 1.5 (-0.1) in (* Should clamp *)
  assert_float_eq 1.0 tv2.strength "clamped strength";
  assert_float_eq 0.0 tv2.confidence "clamped confidence";
  
  let tv3 = make_tv_from_count 0.7 100.0 in
  assert_tv_valid tv3 "make_tv_from_count";
  Printf.printf "  ℹ️  Count 100 -> confidence %.4f\n" tv3.confidence

let test_deduction () =
  section "Deduction Formula";
  
  (* A->B with strength 0.9, B->C with strength 0.8, B with strength 0.7 *)
  let tv_ab = make_tv 0.9 0.8 in
  let tv_bc = make_tv 0.8 0.8 in
  let tv_b = make_tv 0.7 0.9 in
  
  let tv_ac = deduction tv_ab tv_bc tv_b in
  assert_tv_valid tv_ac "deduction result";
  Printf.printf "  ℹ️  A->B=%s, B->C=%s, B=%s => A->C=%s\n"
    (tv_to_string tv_ab) (tv_to_string tv_bc) (tv_to_string tv_b) (tv_to_string tv_ac);
  
  (* Simple deduction *)
  let tv_ac_simple = deduction_simple tv_ab tv_bc in
  assert_float_eq (0.9 *. 0.8) tv_ac_simple.strength "simple deduction strength";
  Printf.printf "  ℹ️  Simple deduction: %s\n" (tv_to_string tv_ac_simple)

let test_induction () =
  section "Induction Formula";
  
  let tv_ab = make_tv 0.8 0.7 in
  let tv_ac = make_tv 0.7 0.7 in
  let tv_a = make_tv 0.6 0.8 in
  
  let tv_bc = induction tv_ab tv_ac tv_a in
  assert_tv_valid tv_bc "induction result";
  Printf.printf "  ℹ️  A->B=%s, A->C=%s, A=%s => B->C=%s\n"
    (tv_to_string tv_ab) (tv_to_string tv_ac) (tv_to_string tv_a) (tv_to_string tv_bc)

let test_abduction () =
  section "Abduction Formula";
  
  let tv_ac = make_tv 0.8 0.7 in
  let tv_bc = make_tv 0.7 0.7 in
  let tv_c = make_tv 0.6 0.8 in
  
  let tv_ab = abduction tv_ac tv_bc tv_c in
  assert_tv_valid tv_ab "abduction result";
  Printf.printf "  ℹ️  A->C=%s, B->C=%s, C=%s => A->B=%s\n"
    (tv_to_string tv_ac) (tv_to_string tv_bc) (tv_to_string tv_c) (tv_to_string tv_ab)

let test_revision () =
  section "Revision Formula";
  
  let tv1 = make_tv 0.8 0.6 in
  let tv2 = make_tv 0.6 0.4 in
  
  let tv_revised = revision tv1 tv2 in
  assert_tv_valid tv_revised "revision result";
  (* Revised strength should be between the two *)
  assert_float_eq true (tv_revised.strength >= 0.6 && tv_revised.strength <= 0.8) 1.0 "revision strength in range";
  Printf.printf "  ℹ️  TV1=%s, TV2=%s => Revised=%s\n"
    (tv_to_string tv1) (tv_to_string tv2) (tv_to_string tv_revised)

let test_logical_connectives () =
  section "Logical Connectives";
  
  let tv_a = make_tv 0.8 0.9 in
  let tv_b = make_tv 0.7 0.8 in
  
  (* Conjunction *)
  let tv_and = conjunction tv_a tv_b in
  assert_float_eq (0.8 *. 0.7) tv_and.strength "conjunction strength";
  Printf.printf "  ℹ️  A=%s AND B=%s => %s\n"
    (tv_to_string tv_a) (tv_to_string tv_b) (tv_to_string tv_and);
  
  (* Disjunction *)
  let tv_or = disjunction tv_a tv_b in
  assert_float_eq (0.8 +. 0.7 -. 0.8 *. 0.7) tv_or.strength "disjunction strength";
  Printf.printf "  ℹ️  A=%s OR B=%s => %s\n"
    (tv_to_string tv_a) (tv_to_string tv_b) (tv_to_string tv_or);
  
  (* Negation *)
  let tv_not = negation tv_a in
  assert_float_eq 0.2 tv_not.strength "negation strength";
  Printf.printf "  ℹ️  NOT A=%s => %s\n"
    (tv_to_string tv_a) (tv_to_string tv_not);
  
  (* Implication *)
  let tv_impl = implication tv_a tv_b in
  assert_tv_valid tv_impl "implication result";
  Printf.printf "  ℹ️  A=%s -> B=%s => %s\n"
    (tv_to_string tv_a) (tv_to_string tv_b) (tv_to_string tv_impl);
  
  (* Equivalence *)
  let tv_equiv = equivalence tv_a tv_b in
  assert_tv_valid tv_equiv "equivalence result";
  Printf.printf "  ℹ️  A=%s <-> B=%s => %s\n"
    (tv_to_string tv_a) (tv_to_string tv_b) (tv_to_string tv_equiv)

let test_modus_ponens () =
  section "Modus Ponens";
  
  let tv_a = make_tv 0.9 0.8 in
  let tv_impl = make_tv 0.85 0.9 in
  
  let tv_b = modus_ponens tv_a tv_impl in
  assert_float_eq (0.9 *. 0.85) tv_b.strength "modus ponens strength";
  Printf.printf "  ℹ️  A=%s, A->B=%s => B=%s\n"
    (tv_to_string tv_a) (tv_to_string tv_impl) (tv_to_string tv_b)

let test_modus_tollens () =
  section "Modus Tollens";
  
  let tv_not_b = make_tv 0.9 0.8 in
  let tv_impl = make_tv 0.85 0.9 in
  
  let tv_not_a = modus_tollens tv_not_b tv_impl in
  assert_tv_valid tv_not_a "modus tollens result";
  Printf.printf "  ℹ️  ¬B=%s, A->B=%s => ¬A=%s\n"
    (tv_to_string tv_not_b) (tv_to_string tv_impl) (tv_to_string tv_not_a)

let test_quantifiers () =
  section "Quantifier Formulas";
  
  let instances = [
    make_tv 0.9 0.8;
    make_tv 0.85 0.7;
    make_tv 0.8 0.9;
    make_tv 0.95 0.6;
  ] in
  
  let tv_forall = universal_intro instances in
  assert_float_eq 0.8 tv_forall.strength "universal min strength";
  Printf.printf "  ℹ️  ∀x.P(x) from %d instances => %s\n"
    (List.length instances) (tv_to_string tv_forall);
  
  let tv_exists = existential_intro instances in
  assert_float_eq 0.95 tv_exists.strength "existential max strength";
  Printf.printf "  ℹ️  ∃x.P(x) from %d instances => %s\n"
    (List.length instances) (tv_to_string tv_exists)

let test_bayes () =
  section "Bayes Rule";
  
  let tv_b_given_a = make_tv 0.8 0.9 in  (* P(B|A) *)
  let tv_a = make_tv 0.3 0.8 in          (* P(A) *)
  let tv_b = make_tv 0.5 0.7 in          (* P(B) *)
  
  let tv_a_given_b = bayes tv_b_given_a tv_a tv_b in
  (* P(A|B) = P(B|A) * P(A) / P(B) = 0.8 * 0.3 / 0.5 = 0.48 *)
  assert_float_eq 0.48 tv_a_given_b.strength "bayes strength";
  Printf.printf "  ℹ️  P(B|A)=%s, P(A)=%s, P(B)=%s => P(A|B)=%s\n"
    (tv_to_string tv_b_given_a) (tv_to_string tv_a) (tv_to_string tv_b) (tv_to_string tv_a_given_b)

let test_temporal () =
  section "Temporal Logic";
  
  let tv_ab = make_tv 0.9 0.8 in
  let tv_bc = make_tv 0.8 0.8 in
  
  let tv_ac_t1 = temporal_deduction tv_ab tv_bc 1.0 in
  let tv_ac_t5 = temporal_deduction tv_ab tv_bc 5.0 in
  let tv_ac_t10 = temporal_deduction tv_ab tv_bc 10.0 in
  
  Printf.printf "  ℹ️  Temporal deduction with gap=1: %s\n" (tv_to_string tv_ac_t1);
  Printf.printf "  ℹ️  Temporal deduction with gap=5: %s\n" (tv_to_string tv_ac_t5);
  Printf.printf "  ℹ️  Temporal deduction with gap=10: %s\n" (tv_to_string tv_ac_t10);
  
  (* Confidence should decrease with time gap *)
  incr test_count;
  if tv_ac_t1.confidence > tv_ac_t5.confidence && 
     tv_ac_t5.confidence > tv_ac_t10.confidence then begin
    incr pass_count;
    Printf.printf "  ✅ Temporal decay: confidence decreases with time gap\n"
  end else begin
    incr fail_count;
    Printf.printf "  ❌ Temporal decay: confidence should decrease with time gap\n"
  end

let test_attention_weighted () =
  section "Attention-Weighted Revision";
  
  let tv1 = make_tv 0.9 0.7 in
  let tv2 = make_tv 0.5 0.7 in
  
  (* Equal attention *)
  let tv_eq = attention_weighted_revision tv1 tv2 1.0 1.0 in
  Printf.printf "  ℹ️  Equal attention (1.0, 1.0): %s\n" (tv_to_string tv_eq);
  
  (* Bias toward tv1 *)
  let tv_bias1 = attention_weighted_revision tv1 tv2 10.0 1.0 in
  Printf.printf "  ℹ️  Bias toward TV1 (10.0, 1.0): %s\n" (tv_to_string tv_bias1);
  
  (* Bias toward tv2 *)
  let tv_bias2 = attention_weighted_revision tv1 tv2 1.0 10.0 in
  Printf.printf "  ℹ️  Bias toward TV2 (1.0, 10.0): %s\n" (tv_to_string tv_bias2);
  
  incr test_count;
  if tv_bias1.strength > tv_eq.strength && tv_eq.strength > tv_bias2.strength then begin
    incr pass_count;
    Printf.printf "  ✅ Attention weighting works correctly\n"
  end else begin
    incr fail_count;
    Printf.printf "  ❌ Attention weighting incorrect\n"
  end

let test_utility_functions () =
  section "Utility Functions";
  
  let tv = make_tv 0.8 0.9 in
  
  (* String conversion *)
  let str = tv_to_string tv in
  Printf.printf "  ℹ️  tv_to_string: %s\n" str;
  
  (* Scheme conversion *)
  let scheme = tv_to_scheme tv in
  Printf.printf "  ℹ️  tv_to_scheme: %s\n" scheme;
  
  (* Parse from Scheme *)
  let tv_parsed = tv_from_scheme scheme in
  assert_float_eq tv.strength tv_parsed.strength "scheme roundtrip strength";
  assert_float_eq tv.confidence tv_parsed.confidence "scheme roundtrip confidence";
  
  (* Boolean checks *)
  let tv_true = make_tv 0.9 0.8 in
  let tv_false = make_tv 0.1 0.8 in
  let tv_unknown = make_tv 0.5 0.1 in
  
  incr test_count;
  if is_true tv_true && not (is_true tv_false) then begin
    incr pass_count;
    Printf.printf "  ✅ is_true works correctly\n"
  end else begin
    incr fail_count;
    Printf.printf "  ❌ is_true incorrect\n"
  end;
  
  incr test_count;
  if is_false tv_false && not (is_false tv_true) then begin
    incr pass_count;
    Printf.printf "  ✅ is_false works correctly\n"
  end else begin
    incr fail_count;
    Printf.printf "  ❌ is_false incorrect\n"
  end;
  
  incr test_count;
  if is_unknown tv_unknown && not (is_unknown tv_true) then begin
    incr pass_count;
    Printf.printf "  ✅ is_unknown works correctly\n"
  end else begin
    incr fail_count;
    Printf.printf "  ❌ is_unknown incorrect\n"
  end

let () =
  Printf.printf "\n";
  Printf.printf "╔══════════════════════════════════════════════════════════╗\n";
  Printf.printf "║     PLN Truth Value Formulas - Test Suite                ║\n";
  Printf.printf "╚══════════════════════════════════════════════════════════╝\n";
  
  test_truth_value_construction ();
  test_deduction ();
  test_induction ();
  test_abduction ();
  test_revision ();
  test_logical_connectives ();
  test_modus_ponens ();
  test_modus_tollens ();
  test_quantifiers ();
  test_bayes ();
  test_temporal ();
  test_attention_weighted ();
  test_utility_functions ();
  
  Printf.printf "\n";
  Printf.printf "╔══════════════════════════════════════════════════════════╗\n";
  Printf.printf "║                    Test Summary                          ║\n";
  Printf.printf "╠══════════════════════════════════════════════════════════╣\n";
  Printf.printf "║  Total:  %3d                                             ║\n" !test_count;
  Printf.printf "║  Passed: %3d                                             ║\n" !pass_count;
  Printf.printf "║  Failed: %3d                                             ║\n" !fail_count;
  Printf.printf "╚══════════════════════════════════════════════════════════╝\n";
  
  if !fail_count = 0 then
    Printf.printf "\n🧠 All PLN formula tests passed! 🧠\n\n"
  else
    Printf.printf "\n⚠️  Some tests failed. Please review. ⚠️\n\n"
