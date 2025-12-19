(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** PLN-MOSES Integration Module
    
    This module integrates Probabilistic Logic Networks (PLN) with
    Meta-Optimizing Semantic Evolutionary Search (MOSES) to enable:
    
    - Evolutionary discovery of PLN inference rules
    - Optimization of rule application strategies
    - Learning of truth value computation formulas
    - Adaptive reasoning patterns
*)

open Pln_formulas
open Moses_programs

(** {1 Rule Representation} *)

(** A PLN rule represented as a MOSES program *)
type pln_rule_program = {
  name: string;
  program: program;
  rule_type: rule_type;
  applicability: sexpr;  (** Condition for when rule applies *)
  mutable success_count: int;
  mutable failure_count: int;
  mutable avg_confidence_gain: float;
}

and rule_type =
  | InferenceRule      (** Derives new knowledge *)
  | TransformRule      (** Transforms existing knowledge *)
  | ControlRule        (** Controls inference process *)
  | MetaRule           (** Operates on other rules *)

(** {1 Rule Templates} *)

(** Template for deduction-like rules *)
let deduction_template = 
  "(lambda ($tv1 $tv2 $tv_b)
     (let ((s1 (strength $tv1))
           (c1 (confidence $tv1))
           (s2 (strength $tv2))
           (c2 (confidence $tv2))
           (sb (strength $tv_b)))
       (make-tv
         (* s1 s2)
         (* c1 c2 (- 1 (abs (- sb (* s1 s2))))))))"

(** Template for induction-like rules *)
let induction_template =
  "(lambda ($tv1 $tv2 $tv_a)
     (let ((s1 (strength $tv1))
           (c1 (confidence $tv1))
           (s2 (strength $tv2))
           (c2 (confidence $tv2))
           (sa (strength $tv_a)))
       (make-tv
         (/ (* s1 s2) (+ sa 0.001))
         (* c1 c2 sa))))"

(** Template for revision-like rules *)
let revision_template =
  "(lambda ($tv1 $tv2)
     (let ((s1 (strength $tv1))
           (c1 (confidence $tv1))
           (s2 (strength $tv2))
           (c2 (confidence $tv2))
           (w1 (/ c1 (- 1 c1)))
           (w2 (/ c2 (- 1 c2))))
       (make-tv
         (/ (+ (* w1 s1) (* w2 s2)) (+ w1 w2))
         (/ (+ w1 w2) (+ w1 w2 1)))))"

(** {1 Fitness Functions for PLN Rules} *)

(** Test case for rule evaluation *)
type rule_test_case = {
  input_tvs: truth_value list;
  expected_tv: truth_value;
  weight: float;  (** Importance of this test case *)
}

(** Evaluate a rule program on test cases *)
let evaluate_rule_program prog test_cases =
  let total_error = List.fold_left (fun acc test ->
    try
      (* Convert truth values to program inputs *)
      let inputs = List.concat_map (fun tv -> [tv.strength; tv.confidence]) test.input_tvs in
      let result = eval_program prog inputs in
      
      (* Extract strength and confidence from result *)
      let (result_s, result_c) = match result with
        | List [Prim (PFloat s); Prim (PFloat c)] -> (s, c)
        | Prim (PFloat s) -> (s, 0.5)  (* Default confidence *)
        | _ -> (0.5, 0.0)  (* Unknown result *)
      in
      
      (* Compute error *)
      let strength_error = (result_s -. test.expected_tv.strength) ** 2.0 in
      let confidence_error = (result_c -. test.expected_tv.confidence) ** 2.0 in
      acc +. test.weight *. (strength_error +. confidence_error)
    with _ ->
      acc +. test.weight *. 2.0  (* Penalty for errors *)
  ) 0.0 test_cases in
  
  (* Convert to fitness (higher is better) *)
  1.0 /. (1.0 +. total_error)

(** Generate test cases from PLN formulas *)
let generate_deduction_test_cases n =
  List.init n (fun _ ->
    let tv1 = { strength = Random.float 1.0; confidence = 0.3 +. Random.float 0.6 } in
    let tv2 = { strength = Random.float 1.0; confidence = 0.3 +. Random.float 0.6 } in
    let tv_b = { strength = Random.float 1.0; confidence = 0.5 } in
    let expected = deduction tv1 tv2 tv_b in
    { input_tvs = [tv1; tv2; tv_b]; expected_tv = expected; weight = 1.0 }
  )

let generate_revision_test_cases n =
  List.init n (fun _ ->
    let tv1 = { strength = Random.float 1.0; confidence = 0.2 +. Random.float 0.7 } in
    let tv2 = { strength = Random.float 1.0; confidence = 0.2 +. Random.float 0.7 } in
    let expected = revision tv1 tv2 in
    { input_tvs = [tv1; tv2]; expected_tv = expected; weight = 1.0 }
  )

(** {1 Rule Evolution} *)

(** Configuration for rule evolution *)
type evolution_config = {
  population_size: int;
  max_generations: int;
  mutation_rate: float;
  crossover_rate: float;
  elitism: int;
  test_cases: rule_test_case list;
  target_fitness: float;
}

let default_config test_cases = {
  population_size = 50;
  max_generations = 100;
  mutation_rate = 0.15;
  crossover_rate = 0.7;
  elitism = 2;
  test_cases;
  target_fitness = 0.95;
}

(** Evolve a PLN rule using MOSES *)
let evolve_rule config =
  let fitness_fn prog = evaluate_rule_program prog config.test_cases in
  
  (* Create initial population with rule-specific primitives *)
  let pop = ref (create_population config.population_size 4) in
  pop := evaluate_population fitness_fn !pop;
  
  let generation = ref 0 in
  while !generation < config.max_generations && !pop.best_fitness < config.target_fitness do
    pop := evolve_population 
      ~mutation_rate:config.mutation_rate 
      ~crossover_rate:config.crossover_rate
      ~elitism:config.elitism
      fitness_fn !pop;
    incr generation
  done;
  
  (* Return best program *)
  let sorted = Array.copy !pop.programs in
  Array.sort (fun a b -> compare b.fitness a.fitness) sorted;
  sorted.(0)

(** {1 Rule Application Strategy} *)

(** Strategy for selecting which rule to apply *)
type rule_selection_strategy =
  | RandomSelection
  | FitnessProportional
  | UCB1 of float  (** Upper Confidence Bound with exploration parameter *)
  | ThompsonSampling
  | EpsilonGreedy of float

(** Rule selector state *)
type rule_selector = {
  rules: pln_rule_program array;
  strategy: rule_selection_strategy;
  mutable total_applications: int;
}

(** Create a rule selector *)
let create_selector rules strategy = {
  rules = Array.of_list rules;
  strategy;
  total_applications = 0;
}

(** Select a rule to apply *)
let select_rule selector =
  if Array.length selector.rules = 0 then None
  else begin
    selector.total_applications <- selector.total_applications + 1;
    let idx = match selector.strategy with
      | RandomSelection ->
        Random.int (Array.length selector.rules)
      
      | FitnessProportional ->
        let total_fitness = Array.fold_left (fun acc r -> acc +. r.program.fitness) 0.0 selector.rules in
        let target = Random.float total_fitness in
        let rec find acc i =
          if i >= Array.length selector.rules then Array.length selector.rules - 1
          else
            let new_acc = acc +. selector.rules.(i).program.fitness in
            if new_acc >= target then i else find new_acc (i + 1)
        in
        find 0.0 0
      
      | UCB1 exploration ->
        let scores = Array.mapi (fun i rule ->
          let n = float_of_int (rule.success_count + rule.failure_count + 1) in
          let avg_reward = if n > 1.0 then 
            float_of_int rule.success_count /. (n -. 1.0)
          else 0.5 in
          let exploration_bonus = exploration *. sqrt (log (float_of_int selector.total_applications) /. n) in
          avg_reward +. exploration_bonus
        ) selector.rules in
        let max_idx = ref 0 in
        Array.iteri (fun i s -> if s > scores.(!max_idx) then max_idx := i) scores;
        !max_idx
      
      | ThompsonSampling ->
        (* Sample from Beta distribution for each rule *)
        let samples = Array.map (fun rule ->
          let alpha = float_of_int (rule.success_count + 1) in
          let beta = float_of_int (rule.failure_count + 1) in
          (* Approximate Beta sampling using mean + noise *)
          let mean = alpha /. (alpha +. beta) in
          let variance = (alpha *. beta) /. ((alpha +. beta) ** 2.0 *. (alpha +. beta +. 1.0)) in
          mean +. (Random.float 1.0 -. 0.5) *. sqrt variance *. 2.0
        ) selector.rules in
        let max_idx = ref 0 in
        Array.iteri (fun i s -> if s > samples.(!max_idx) then max_idx := i) samples;
        !max_idx
      
      | EpsilonGreedy epsilon ->
        if Random.float 1.0 < epsilon then
          Random.int (Array.length selector.rules)
        else begin
          let max_idx = ref 0 in
          let max_success = ref 0.0 in
          Array.iteri (fun i rule ->
            let n = float_of_int (rule.success_count + rule.failure_count + 1) in
            let rate = float_of_int rule.success_count /. n in
            if rate > !max_success then begin
              max_success := rate;
              max_idx := i
            end
          ) selector.rules;
          !max_idx
        end
    in
    Some selector.rules.(idx)
  end

(** Update rule statistics after application *)
let update_rule_stats rule success confidence_gain =
  if success then begin
    rule.success_count <- rule.success_count + 1;
    rule.avg_confidence_gain <- 
      (rule.avg_confidence_gain *. float_of_int (rule.success_count - 1) +. confidence_gain) 
      /. float_of_int rule.success_count
  end else
    rule.failure_count <- rule.failure_count + 1

(** {1 Inference Strategy Evolution} *)

(** An inference strategy as a MOSES program *)
type inference_strategy = {
  name: string;
  selector_program: program;  (** Program that selects next rule *)
  termination_program: program;  (** Program that decides when to stop *)
  mutable applications: int;
  mutable successes: int;
}

(** Evaluate inference strategy on a reasoning task *)
let evaluate_strategy strategy atomspace goal_tv max_steps =
  let steps = ref 0 in
  let current_confidence = ref 0.0 in
  
  while !steps < max_steps && !current_confidence < goal_tv.confidence do
    (* Strategy decides next action *)
    let inputs = [!current_confidence; float_of_int !steps; float_of_int max_steps] in
    let _ = eval_program strategy.selector_program inputs in
    
    (* Simulate confidence improvement *)
    current_confidence := !current_confidence +. Random.float 0.1;
    incr steps
  done;
  
  strategy.applications <- strategy.applications + 1;
  if !current_confidence >= goal_tv.confidence then
    strategy.successes <- strategy.successes + 1;
  
  !current_confidence >= goal_tv.confidence

(** {1 Meta-Learning} *)

(** Learn which rules work well together *)
type rule_cooccurrence = {
  rule1_idx: int;
  rule2_idx: int;
  mutable cooccurrence_count: int;
  mutable success_when_together: int;
}

(** Track rule co-occurrences *)
let track_cooccurrence cooccurrences rule1_idx rule2_idx success =
  let key = if rule1_idx < rule2_idx then (rule1_idx, rule2_idx) else (rule2_idx, rule1_idx) in
  match List.find_opt (fun c -> (c.rule1_idx, c.rule2_idx) = key) cooccurrences with
  | Some c ->
    c.cooccurrence_count <- c.cooccurrence_count + 1;
    if success then c.success_when_together <- c.success_when_together + 1;
    cooccurrences
  | None ->
    { rule1_idx = fst key; 
      rule2_idx = snd key; 
      cooccurrence_count = 1; 
      success_when_together = if success then 1 else 0 
    } :: cooccurrences

(** {1 Rule Library} *)

(** Standard PLN rules as MOSES programs *)
let standard_rules = [
  (* Deduction rule *)
  {
    name = "deduction";
    program = create_program "(* (strength $x0) (strength $x1))";
    rule_type = InferenceRule;
    applicability = parse_sexpr "(and (implication? $x0) (implication? $x1) (chain? $x0 $x1))";
    success_count = 0;
    failure_count = 0;
    avg_confidence_gain = 0.0;
  };
  
  (* Modus ponens rule *)
  {
    name = "modus_ponens";
    program = create_program "(if (> (strength $x0) 0.5) (strength $x1) 0.5)";
    rule_type = InferenceRule;
    applicability = parse_sexpr "(and (node? $x0) (implication? $x1) (antecedent? $x0 $x1))";
    success_count = 0;
    failure_count = 0;
    avg_confidence_gain = 0.0;
  };
  
  (* Revision rule *)
  {
    name = "revision";
    program = create_program "(/ (+ (* $x0 $x2) (* $x1 $x3)) (+ $x2 $x3))";
    rule_type = TransformRule;
    applicability = parse_sexpr "(same-statement? $x0 $x1)";
    success_count = 0;
    failure_count = 0;
    avg_confidence_gain = 0.0;
  };
  
  (* Conjunction rule *)
  {
    name = "conjunction";
    program = create_program "(* (strength $x0) (strength $x1))";
    rule_type = InferenceRule;
    applicability = parse_sexpr "#t";
    success_count = 0;
    failure_count = 0;
    avg_confidence_gain = 0.0;
  };
]

(** {1 Scheme Serialization} *)

let rule_type_to_string = function
  | InferenceRule -> "inference"
  | TransformRule -> "transform"
  | ControlRule -> "control"
  | MetaRule -> "meta"

let pln_rule_to_scheme rule =
  Printf.sprintf "(pln-rule (name %s) (type %s) (fitness %.4f) (success %d) (failure %d) (avg-gain %.4f)\n  (program %s)\n  (applicability %s))"
    rule.name
    (rule_type_to_string rule.rule_type)
    rule.program.fitness
    rule.success_count
    rule.failure_count
    rule.avg_confidence_gain
    (sexpr_to_string rule.program.expr)
    (sexpr_to_string rule.applicability)

let selector_to_scheme selector =
  let strategy_str = match selector.strategy with
    | RandomSelection -> "random"
    | FitnessProportional -> "fitness-proportional"
    | UCB1 c -> Printf.sprintf "(ucb1 %.2f)" c
    | ThompsonSampling -> "thompson-sampling"
    | EpsilonGreedy e -> Printf.sprintf "(epsilon-greedy %.2f)" e
  in
  let rules_str = Array.to_list selector.rules 
    |> List.map pln_rule_to_scheme 
    |> String.concat "\n  " in
  Printf.sprintf "(rule-selector (strategy %s) (total-applications %d)\n  %s)"
    strategy_str selector.total_applications rules_str

let evolution_result_to_scheme prog generations =
  Printf.sprintf "(evolution-result (generations %d) (fitness %.4f) (complexity %d)\n  (program %s))"
    generations prog.fitness prog.complexity (sexpr_to_string prog.expr)
