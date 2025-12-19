(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** Test Suite for PLN-MOSES Integration *)

open Pln_formulas
open Moses_programs
open Pln_moses

(** Test utilities *)
let test_count = ref 0
let pass_count = ref 0
let fail_count = ref 0

let assert_true condition name =
  incr test_count;
  if condition then begin
    incr pass_count;
    Printf.printf "  ✅ %s\n" name
  end else begin
    incr fail_count;
    Printf.printf "  ❌ %s\n" name
  end

let assert_float_ge actual expected name =
  incr test_count;
  if actual >= expected then begin
    incr pass_count;
    Printf.printf "  ✅ %s: %.4f >= %.4f\n" name actual expected
  end else begin
    incr fail_count;
    Printf.printf "  ❌ %s: %.4f < %.4f\n" name actual expected
  end

let section name =
  Printf.printf "\n=== %s ===\n" name

(** Test cases *)

let test_rule_types () =
  section "Rule Types";
  
  assert_true (rule_type_to_string InferenceRule = "inference") "inference rule type";
  assert_true (rule_type_to_string TransformRule = "transform") "transform rule type";
  assert_true (rule_type_to_string ControlRule = "control") "control rule type";
  assert_true (rule_type_to_string MetaRule = "meta") "meta rule type"

let test_standard_rules () =
  section "Standard Rules Library";
  
  let rules = standard_rules in
  assert_true (List.length rules >= 4) "at least 4 standard rules";
  
  Printf.printf "  ℹ️  Standard rules:\n";
  List.iter (fun rule ->
    Printf.printf "      - %s (%s)\n" rule.name (rule_type_to_string rule.rule_type)
  ) rules;
  
  (* Check deduction rule exists *)
  let has_deduction = List.exists (fun r -> r.name = "deduction") rules in
  assert_true has_deduction "has deduction rule";
  
  (* Check modus ponens rule exists *)
  let has_mp = List.exists (fun r -> r.name = "modus_ponens") rules in
  assert_true has_mp "has modus ponens rule"

let test_test_case_generation () =
  section "Test Case Generation";
  
  let deduction_cases = generate_deduction_test_cases 10 in
  assert_true (List.length deduction_cases = 10) "generates 10 deduction cases";
  
  (* Check test case structure *)
  let first_case = List.hd deduction_cases in
  assert_true (List.length first_case.input_tvs = 3) "deduction has 3 input TVs";
  assert_true (first_case.weight = 1.0) "default weight is 1.0";
  
  let revision_cases = generate_revision_test_cases 5 in
  assert_true (List.length revision_cases = 5) "generates 5 revision cases";
  
  let first_rev = List.hd revision_cases in
  assert_true (List.length first_rev.input_tvs = 2) "revision has 2 input TVs"

let test_rule_evaluation () =
  section "Rule Program Evaluation";
  
  (* Create a simple multiplication program *)
  let prog = create_program "(* $x0 $x1)" in
  
  (* Create test cases where expected is product of strengths *)
  let test_cases = [
    { input_tvs = [{ strength = 0.8; confidence = 0.9 }; { strength = 0.7; confidence = 0.8 }];
      expected_tv = { strength = 0.56; confidence = 0.72 };
      weight = 1.0 };
    { input_tvs = [{ strength = 0.5; confidence = 0.5 }; { strength = 0.5; confidence = 0.5 }];
      expected_tv = { strength = 0.25; confidence = 0.25 };
      weight = 1.0 };
  ] in
  
  let fitness = evaluate_rule_program prog test_cases in
  Printf.printf "  ℹ️  Multiplication program fitness: %.4f\n" fitness;
  assert_true (fitness > 0.0) "fitness is positive"

let test_rule_selector_creation () =
  section "Rule Selector Creation";
  
  let rules = standard_rules in
  
  let selector_random = create_selector rules RandomSelection in
  assert_true (Option.is_some (select_rule selector_random)) "random selector works";
  
  let selector_ucb = create_selector rules (UCB1 1.41) in
  assert_true (Option.is_some (select_rule selector_ucb)) "UCB1 selector works";
  
  let selector_eps = create_selector rules (EpsilonGreedy 0.1) in
  assert_true (Option.is_some (select_rule selector_eps)) "epsilon-greedy selector works"

let test_rule_selection_strategies () =
  section "Rule Selection Strategies";
  
  let rules = standard_rules in
  
  (* Test random selection *)
  let selector = create_selector rules RandomSelection in
  let selections = Array.init 100 (fun _ -> 
    match select_rule selector with
    | Some r -> r.name
    | None -> "none"
  ) in
  let unique = Array.to_list selections |> List.sort_uniq String.compare in
  Printf.printf "  ℹ️  Random selection unique rules: %d\n" (List.length unique);
  assert_true (List.length unique > 1) "random selects different rules";
  
  (* Test fitness proportional *)
  let selector2 = create_selector rules FitnessProportional in
  let _ = select_rule selector2 in
  assert_true true "fitness proportional runs"

let test_rule_stats_update () =
  section "Rule Statistics Update";
  
  let rule = List.hd standard_rules in
  
  assert_true (rule.success_count = 0) "initial success count is 0";
  assert_true (rule.failure_count = 0) "initial failure count is 0";
  
  update_rule_stats rule true 0.1;
  assert_true (rule.success_count = 1) "success count incremented";
  
  update_rule_stats rule false 0.0;
  assert_true (rule.failure_count = 1) "failure count incremented";
  
  update_rule_stats rule true 0.2;
  Printf.printf "  ℹ️  Avg confidence gain: %.4f\n" rule.avg_confidence_gain;
  assert_true (rule.avg_confidence_gain > 0.0) "avg confidence gain updated"

let test_cooccurrence_tracking () =
  section "Rule Co-occurrence Tracking";
  
  let cooccurrences = [] in
  
  let cooccurrences = track_cooccurrence cooccurrences 0 1 true in
  assert_true (List.length cooccurrences = 1) "first co-occurrence added";
  
  let cooccurrences = track_cooccurrence cooccurrences 0 1 true in
  let first = List.hd cooccurrences in
  assert_true (first.cooccurrence_count = 2) "co-occurrence count incremented";
  assert_true (first.success_when_together = 2) "success count incremented";
  
  let cooccurrences = track_cooccurrence cooccurrences 0 1 false in
  let first = List.hd cooccurrences in
  assert_true (first.cooccurrence_count = 3) "count incremented on failure";
  assert_true (first.success_when_together = 2) "success unchanged on failure"

let test_scheme_serialization () =
  section "Scheme Serialization";
  
  let rule = List.hd standard_rules in
  let scheme = pln_rule_to_scheme rule in
  Printf.printf "  ℹ️  Rule to Scheme:\n%s\n" scheme;
  assert_true (String.sub scheme 0 9 = "(pln-rule") "rule serialization starts correctly";
  
  let selector = create_selector standard_rules (UCB1 1.41) in
  let _ = select_rule selector in  (* Generate some activity *)
  let selector_scheme = selector_to_scheme selector in
  Printf.printf "  ℹ️  Selector to Scheme (first 100 chars):\n%.100s...\n" selector_scheme;
  assert_true (String.sub selector_scheme 0 14 = "(rule-selector") "selector serialization starts correctly"

let test_evolution_config () =
  section "Evolution Configuration";
  
  let test_cases = generate_deduction_test_cases 20 in
  let config = default_config test_cases in
  
  assert_true (config.population_size = 50) "default population size";
  assert_true (config.max_generations = 100) "default max generations";
  assert_float_ge config.target_fitness 0.9 "target fitness >= 0.9";
  assert_true (List.length config.test_cases = 20) "test cases included"

let test_mini_evolution () =
  section "Mini Evolution Run";
  
  (* Generate test cases for a simple rule *)
  let test_cases = [
    { input_tvs = [{ strength = 0.8; confidence = 0.9 }; { strength = 0.7; confidence = 0.8 }];
      expected_tv = { strength = 0.56; confidence = 0.72 };
      weight = 1.0 };
    { input_tvs = [{ strength = 0.5; confidence = 0.5 }; { strength = 0.6; confidence = 0.6 }];
      expected_tv = { strength = 0.30; confidence = 0.30 };
      weight = 1.0 };
    { input_tvs = [{ strength = 0.9; confidence = 0.9 }; { strength = 0.9; confidence = 0.9 }];
      expected_tv = { strength = 0.81; confidence = 0.81 };
      weight = 1.0 };
  ] in
  
  let config = {
    population_size = 20;
    max_generations = 10;
    mutation_rate = 0.2;
    crossover_rate = 0.7;
    elitism = 2;
    test_cases;
    target_fitness = 0.8;
  } in
  
  Printf.printf "  ℹ️  Running mini evolution (10 generations, 20 individuals)...\n";
  let best = evolve_rule config in
  
  Printf.printf "  ℹ️  Best evolved rule:\n";
  Printf.printf "      Expression: %s\n" (sexpr_to_string best.expr);
  Printf.printf "      Fitness:    %.4f\n" best.fitness;
  Printf.printf "      Complexity: %d\n" best.complexity;
  
  assert_true (best.fitness > 0.0) "evolved rule has positive fitness"

let () =
  Printf.printf "\n";
  Printf.printf "╔══════════════════════════════════════════════════════════╗\n";
  Printf.printf "║     PLN-MOSES Integration - Test Suite                   ║\n";
  Printf.printf "╚══════════════════════════════════════════════════════════╝\n";
  
  test_rule_types ();
  test_standard_rules ();
  test_test_case_generation ();
  test_rule_evaluation ();
  test_rule_selector_creation ();
  test_rule_selection_strategies ();
  test_rule_stats_update ();
  test_cooccurrence_tracking ();
  test_scheme_serialization ();
  test_evolution_config ();
  test_mini_evolution ();
  
  Printf.printf "\n";
  Printf.printf "╔══════════════════════════════════════════════════════════╗\n";
  Printf.printf "║                    Test Summary                          ║\n";
  Printf.printf "╠══════════════════════════════════════════════════════════╣\n";
  Printf.printf "║  Total:  %3d                                             ║\n" !test_count;
  Printf.printf "║  Passed: %3d                                             ║\n" !pass_count;
  Printf.printf "║  Failed: %3d                                             ║\n" !fail_count;
  Printf.printf "╚══════════════════════════════════════════════════════════╝\n";
  
  if !fail_count = 0 then
    Printf.printf "\n🧬 All PLN-MOSES integration tests passed! 🧬\n\n"
  else
    Printf.printf "\n⚠️  Some tests failed. Please review. ⚠️\n\n"
