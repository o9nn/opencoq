(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** Test Suite for MOSES S-Expression Programs *)

open Moses_programs

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

let assert_eq expected actual name =
  incr test_count;
  if expected = actual then begin
    incr pass_count;
    Printf.printf "  ✅ %s\n" name
  end else begin
    incr fail_count;
    Printf.printf "  ❌ %s: expected %s, got %s\n" name expected actual
  end

let section name =
  Printf.printf "\n=== %s ===\n" name

(** Test cases *)

let test_parsing () =
  section "S-Expression Parsing";
  
  (* Simple atoms *)
  let e1 = parse_sexpr "x" in
  assert_eq "x" (sexpr_to_string e1) "parse atom";
  
  (* Numbers *)
  let e2 = parse_sexpr "42" in
  assert_eq "42" (sexpr_to_string e2) "parse integer";
  
  let e3 = parse_sexpr "3.14" in
  assert_true (String.sub (sexpr_to_string e3) 0 4 = "3.14") "parse float";
  
  (* Booleans *)
  let e4 = parse_sexpr "#t" in
  assert_eq "#t" (sexpr_to_string e4) "parse true";
  
  let e5 = parse_sexpr "#f" in
  assert_eq "#f" (sexpr_to_string e5) "parse false";
  
  (* Lists *)
  let e6 = parse_sexpr "(+ 1 2)" in
  assert_eq "(+ 1 2)" (sexpr_to_string e6) "parse simple list";
  
  let e7 = parse_sexpr "(if (< x 0) (neg x) x)" in
  assert_eq "(if (< x 0) (neg x) x)" (sexpr_to_string e7) "parse nested list";
  
  (* Quoted expressions *)
  let e8 = parse_sexpr "'(a b c)" in
  assert_eq "'(a b c)" (sexpr_to_string e8) "parse quoted list"

let test_program_creation () =
  section "Program Creation";
  
  let p1 = create_program "(+ $x0 $x1)" in
  assert_eq 2 p1.arity "arity detection";
  assert_true (List.mem "$x0" p1.variables && List.mem "$x1" p1.variables) "variable extraction";
  
  let p2 = create_program "(and (> $x0 0) (< $x0 10))" in
  assert_eq 1 p2.arity "single variable arity";
  
  Printf.printf "  ℹ️  Program complexity: %d\n" p2.complexity

let test_evaluation () =
  section "Expression Evaluation";
  
  (* Arithmetic *)
  let p1 = create_program "(+ $x0 $x1)" in
  let r1 = eval_program p1 [3.0; 4.0] in
  (match r1 with
   | Prim (PFloat f) -> assert_true (abs_float (f -. 7.0) < 0.001) "addition evaluation"
   | _ -> assert_true false "addition evaluation (wrong type)");
  
  let p2 = create_program "(* $x0 $x1)" in
  let r2 = eval_program p2 [3.0; 4.0] in
  (match r2 with
   | Prim (PFloat f) -> assert_true (abs_float (f -. 12.0) < 0.001) "multiplication evaluation"
   | _ -> assert_true false "multiplication evaluation (wrong type)");
  
  (* Conditionals *)
  let p3 = create_program "(if (< $x0 0) (neg $x0) $x0)" in
  let r3a = eval_program p3 [-5.0] in
  (match r3a with
   | Prim (PFloat f) -> assert_true (abs_float (f -. 5.0) < 0.001) "conditional (negative)"
   | _ -> assert_true false "conditional (negative) - wrong type");
  
  let r3b = eval_program p3 [5.0] in
  (match r3b with
   | Prim (PFloat f) -> assert_true (abs_float (f -. 5.0) < 0.001) "conditional (positive)"
   | _ -> assert_true false "conditional (positive) - wrong type");
  
  (* Boolean *)
  let p4 = create_program "(and #t #f)" in
  let r4 = eval_program p4 [] in
  (match r4 with
   | Prim (PBool b) -> assert_true (b = false) "boolean and"
   | _ -> assert_true false "boolean and - wrong type");
  
  let p5 = create_program "(or #t #f)" in
  let r5 = eval_program p5 [] in
  (match r5 with
   | Prim (PBool b) -> assert_true (b = true) "boolean or"
   | _ -> assert_true false "boolean or - wrong type")

let test_simplification () =
  section "Expression Simplification";
  
  (* Boolean simplifications *)
  let e1 = parse_sexpr "(and #t x)" in
  let s1 = simplify e1 in
  assert_eq "x" (sexpr_to_string s1) "simplify (and #t x)";
  
  let e2 = parse_sexpr "(or #f x)" in
  let s2 = simplify e2 in
  assert_eq "x" (sexpr_to_string s2) "simplify (or #f x)";
  
  let e3 = parse_sexpr "(not (not x))" in
  let s3 = simplify e3 in
  assert_eq "x" (sexpr_to_string s3) "simplify double negation";
  
  (* Arithmetic simplifications *)
  let e4 = parse_sexpr "(+ 0 x)" in
  let s4 = simplify e4 in
  assert_eq "x" (sexpr_to_string s4) "simplify (+ 0 x)";
  
  let e5 = parse_sexpr "(* 1 x)" in
  let s5 = simplify e5 in
  assert_eq "x" (sexpr_to_string s5) "simplify (* 1 x)";
  
  let e6 = parse_sexpr "(* 0 x)" in
  let s6 = simplify e6 in
  assert_eq "0" (sexpr_to_string s6) "simplify (* 0 x)";
  
  (* Constant folding *)
  let e7 = parse_sexpr "(+ 2 3)" in
  let s7 = simplify e7 in
  assert_eq "5" (sexpr_to_string s7) "constant folding addition";
  
  let e8 = parse_sexpr "(* 4 5)" in
  let s8 = simplify e8 in
  assert_eq "20" (sexpr_to_string s8) "constant folding multiplication"

let test_genetic_operators () =
  section "Genetic Operators";
  
  (* Mutation *)
  let p1 = create_program "(+ $x0 1)" in
  let mutated = mutate ~rate:1.0 p1 in
  assert_true (mutated.generation = p1.generation + 1) "mutation increments generation";
  Printf.printf "  ℹ️  Original: %s\n" (sexpr_to_string p1.expr);
  Printf.printf "  ℹ️  Mutated:  %s\n" (sexpr_to_string mutated.expr);
  
  (* Crossover *)
  let p2 = create_program "(* $x0 2)" in
  let p3 = create_program "(- $x0 3)" in
  let (c1, c2) = crossover p2 p3 in
  assert_true (c1.generation >= max p2.generation p3.generation) "crossover increments generation";
  Printf.printf "  ℹ️  Parent 1: %s\n" (sexpr_to_string p2.expr);
  Printf.printf "  ℹ️  Parent 2: %s\n" (sexpr_to_string p3.expr);
  Printf.printf "  ℹ️  Child 1:  %s\n" (sexpr_to_string c1.expr);
  Printf.printf "  ℹ️  Child 2:  %s\n" (sexpr_to_string c2.expr);
  
  (* Point mutation *)
  let p4 = create_program "(+ 5 $x0)" in
  let point_mutated = point_mutate ~rate:1.0 p4 in
  Printf.printf "  ℹ️  Original:      %s\n" (sexpr_to_string p4.expr);
  Printf.printf "  ℹ️  Point mutated: %s\n" (sexpr_to_string point_mutated.expr)

let test_fitness_evaluation () =
  section "Fitness Evaluation";
  
  (* Boolean fitness *)
  let test_cases_bool = [
    ([0.0; 0.0], false);
    ([0.0; 1.0], true);
    ([1.0; 0.0], true);
    ([1.0; 1.0], true);
  ] in
  
  let p_or = create_program "(or (> $x0 0.5) (> $x1 0.5))" in
  let fitness_or = boolean_fitness test_cases_bool p_or in
  Printf.printf "  ℹ️  OR program fitness: %.2f\n" fitness_or;
  assert_true (fitness_or >= 0.75) "OR program fitness reasonable";
  
  (* Regression fitness *)
  let test_cases_reg = [
    ([1.0], 2.0);
    ([2.0], 4.0);
    ([3.0], 6.0);
    ([4.0], 8.0);
  ] in
  
  let p_double = create_program "(* $x0 2)" in
  let fitness_double = regression_fitness test_cases_reg p_double in
  Printf.printf "  ℹ️  Double program fitness: %.4f\n" fitness_double;
  assert_true (fitness_double > 0.99) "perfect regression fitness"

let test_population () =
  section "Population Management";
  
  let pop = create_population 10 3 in
  assert_eq 10 (Array.length pop.programs) "population size";
  assert_eq 0 pop.generation "initial generation";
  
  Printf.printf "  ℹ️  Sample programs from population:\n";
  for i = 0 to min 2 (Array.length pop.programs - 1) do
    Printf.printf "      %d: %s\n" i (sexpr_to_string pop.programs.(i).expr)
  done;
  
  (* Test tournament selection *)
  let test_cases = [([1.0], 2.0); ([2.0], 4.0)] in
  let fitness_fn = regression_fitness test_cases in
  let evaluated_pop = evaluate_population fitness_fn pop in
  
  Printf.printf "  ℹ️  Best fitness: %.4f\n" evaluated_pop.best_fitness;
  Printf.printf "  ℹ️  Avg fitness:  %.4f\n" evaluated_pop.avg_fitness;
  
  let selected = tournament_select evaluated_pop in
  Printf.printf "  ℹ️  Tournament selected: %s (fitness: %.4f)\n" 
    (sexpr_to_string selected.expr) selected.fitness

let test_evolution () =
  section "Evolution (Mini MOSES Run)";
  
  (* Simple regression: find f(x) = 2x + 1 *)
  let test_cases = [
    ([0.0], 1.0);
    ([1.0], 3.0);
    ([2.0], 5.0);
    ([3.0], 7.0);
    ([4.0], 9.0);
  ] in
  
  let fitness_fn = regression_fitness test_cases in
  
  Printf.printf "  ℹ️  Target function: f(x) = 2x + 1\n";
  Printf.printf "  ℹ️  Running mini evolution (5 generations, 20 individuals)...\n";
  
  let pop = ref (create_population 20 3) in
  pop := evaluate_population fitness_fn !pop;
  
  for _ = 1 to 5 do
    pop := evolve_population fitness_fn !pop
  done;
  
  let sorted = Array.copy !pop.programs in
  Array.sort (fun a b -> compare b.fitness a.fitness) sorted;
  
  Printf.printf "  ℹ️  Best after 5 generations:\n";
  Printf.printf "      Expression: %s\n" (sexpr_to_string sorted.(0).expr);
  Printf.printf "      Fitness:    %.4f\n" sorted.(0).fitness;
  Printf.printf "      Complexity: %d\n" sorted.(0).complexity;
  
  assert_true (!pop.generation = 5) "evolution ran 5 generations";
  assert_true (!pop.best_fitness > 0.0) "some fitness achieved"

let test_scheme_serialization () =
  section "Scheme Serialization";
  
  let p = create_program "(+ (* $x0 2) 1)" in
  p.fitness <- 0.95;
  
  let scheme = program_to_scheme p in
  Printf.printf "  ℹ️  Program to Scheme:\n%s\n" scheme;
  
  assert_true (String.length scheme > 0) "scheme serialization produces output";
  assert_true (String.sub scheme 0 14 = "(moses-program") "scheme starts with moses-program"

let () =
  Printf.printf "\n";
  Printf.printf "╔══════════════════════════════════════════════════════════╗\n";
  Printf.printf "║     MOSES S-Expression Programs - Test Suite             ║\n";
  Printf.printf "╚══════════════════════════════════════════════════════════╝\n";
  
  test_parsing ();
  test_program_creation ();
  test_evaluation ();
  test_simplification ();
  test_genetic_operators ();
  test_fitness_evaluation ();
  test_population ();
  test_evolution ();
  test_scheme_serialization ();
  
  Printf.printf "\n";
  Printf.printf "╔══════════════════════════════════════════════════════════╗\n";
  Printf.printf "║                    Test Summary                          ║\n";
  Printf.printf "╠══════════════════════════════════════════════════════════╣\n";
  Printf.printf "║  Total:  %3d                                             ║\n" !test_count;
  Printf.printf "║  Passed: %3d                                             ║\n" !pass_count;
  Printf.printf "║  Failed: %3d                                             ║\n" !fail_count;
  Printf.printf "╚══════════════════════════════════════════════════════════╝\n";
  
  if !fail_count = 0 then
    Printf.printf "\n🧬 All MOSES program tests passed! 🧬\n\n"
  else
    Printf.printf "\n⚠️  Some tests failed. Please review. ⚠️\n\n"
