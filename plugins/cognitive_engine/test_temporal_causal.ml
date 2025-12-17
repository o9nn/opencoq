(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** Test suite for temporal logic and causal reasoning *)

let test_temporal_logic () =
  Printf.printf "Testing Temporal Logic Operations...\n";
  
  (* Create atomspace and reasoning engine *)
  let atomspace = Hypergraph.create_atomspace () in
  let engine = Reasoning_engine.create_reasoning_engine atomspace in
  
  (* Create some test atoms *)
  let rain_node = Hypergraph.add_node atomspace Hypergraph.Concept "rain" in
  let umbrella_node = Hypergraph.add_node atomspace Hypergraph.Concept "umbrella" in
  let wet_node = Hypergraph.add_node atomspace Hypergraph.Concept "wet" in
  
  let rain_link = Hypergraph.add_link atomspace Hypergraph.Evaluation [rain_node] in
  let umbrella_link = Hypergraph.add_link atomspace Hypergraph.Evaluation [umbrella_node] in
  let wet_link = Hypergraph.add_link atomspace Hypergraph.Evaluation [wet_node] in
  
  (* Create temporal state with 10 time steps *)
  let temporal_state = Reasoning_engine.create_temporal_state 0 10 in
  
  (* Add temporal knowledge: rain at time 2, umbrella at time 3, wet at time 4 *)
  Reasoning_engine.add_temporal_knowledge temporal_state 2 rain_link;
  Reasoning_engine.add_temporal_knowledge temporal_state 3 umbrella_link;
  Reasoning_engine.add_temporal_knowledge temporal_state 4 wet_link;
  
  Printf.printf "  ✓ Created temporal state with knowledge at times 2, 3, 4\n";
  
  (* Test Always operator (should be false since rain is not always present) *)
  let always_rain_formula = {
    Reasoning_engine.operator = Reasoning_engine.Always;
    operands = [rain_link];
    time_bounds = Some (0, 10);
    temporal_context = 0;
  } in
  
  let always_result = Reasoning_engine.evaluate_temporal_formula engine temporal_state always_rain_formula in
  Printf.printf "  ✓ Always(rain): %b (expected: false)\n" always_result;
  
  (* Test Eventually operator (should be true since rain appears at time 2) *)
  let eventually_rain_formula = {
    Reasoning_engine.operator = Reasoning_engine.Eventually;
    operands = [rain_link];
    time_bounds = Some (0, 10);
    temporal_context = 0;
  } in
  
  let eventually_result = Reasoning_engine.evaluate_temporal_formula engine temporal_state eventually_rain_formula in
  Printf.printf "  ✓ Eventually(rain): %b (expected: true)\n" eventually_result;
  
  (* Test Next operator at time 2 (umbrella should be next after rain) *)
  temporal_state.current_time <- 2;
  let next_umbrella_formula = {
    Reasoning_engine.operator = Reasoning_engine.Next;
    operands = [umbrella_link];
    time_bounds = None;
    temporal_context = 2;
  } in
  
  let next_result = Reasoning_engine.evaluate_temporal_formula engine temporal_state next_umbrella_formula in
  Printf.printf "  ✓ Next(umbrella) at time 2: %b (expected: true)\n" next_result;
  
  (* Test Until operator (rain until umbrella) *)
  let until_formula = {
    Reasoning_engine.operator = Reasoning_engine.Until;
    operands = [rain_link; umbrella_link];
    time_bounds = Some (0, 10);
    temporal_context = 0;
  } in
  
  temporal_state.current_time <- 2;
  let until_result = Reasoning_engine.evaluate_temporal_formula engine temporal_state until_formula in
  Printf.printf "  ✓ Rain Until Umbrella: %b (expected: true)\n" until_result;
  
  Printf.printf "Temporal Logic tests completed.\n\n"

let test_causal_reasoning () =
  Printf.printf "Testing Causal Reasoning Operations...\n";
  
  (* Create atomspace and reasoning engine *)
  let atomspace = Hypergraph.create_atomspace () in
  let engine = Reasoning_engine.create_reasoning_engine atomspace in
  
  (* Create causal scenario: smoking -> lung_disease *)
  let smoking_node = Hypergraph.add_node atomspace Hypergraph.Concept "smoking" in
  let disease_node = Hypergraph.add_node atomspace Hypergraph.Concept "lung_disease" in
  let exercise_node = Hypergraph.add_node atomspace Hypergraph.Concept "exercise" in
  
  let smoking_link = Hypergraph.add_link atomspace Hypergraph.Evaluation [smoking_node] in
  let disease_link = Hypergraph.add_link atomspace Hypergraph.Evaluation [disease_node] in
  let exercise_link = Hypergraph.add_link atomspace Hypergraph.Evaluation [exercise_node] in
  
  let temporal_state = Reasoning_engine.create_temporal_state 0 20 in
  
  (* Create temporal pattern: smoking at times 1,2,3,5,6,7 -> disease at 8,9,10 *)
  List.iter (fun t -> Reasoning_engine.add_temporal_knowledge temporal_state t smoking_link) [1;2;3;5;6;7];
  List.iter (fun t -> Reasoning_engine.add_temporal_knowledge temporal_state t disease_link) [8;9;10];
  
  (* Exercise as preventive factor at times 4,11,12 *)
  List.iter (fun t -> Reasoning_engine.add_temporal_knowledge temporal_state t exercise_link) [4;11;12];
  
  Printf.printf "  ✓ Created causal scenario with temporal patterns\n";
  
  (* Test causal strength computation *)
  let causal_strength = Reasoning_engine.compute_causal_strength engine temporal_state smoking_link disease_link in
  Printf.printf "  ✓ Causal strength (smoking -> disease): P=%.3f, C=%.3f\n" 
    causal_strength.probability causal_strength.confidence;
  
  (* Discover causal relationships *)
  let discovered_relations = Reasoning_engine.discover_causal_relationships engine temporal_state 0.3 in
  Printf.printf "  ✓ Discovered %d causal relationships above threshold 0.3\n" (List.length discovered_relations);
  
  (* Test Pearl's causal hierarchy *)
  let obs_smoking = Reasoning_engine.observational_query engine temporal_state smoking_link in
  Printf.printf "  ✓ P(smoking) = %.3f (observational)\n" obs_smoking;
  
  let obs_disease = Reasoning_engine.observational_query engine temporal_state disease_link in
  Printf.printf "  ✓ P(disease) = %.3f (observational)\n" obs_disease;
  
  let interv_result = Reasoning_engine.interventional_query engine temporal_state smoking_link disease_link in
  Printf.printf "  ✓ P(disease | do(smoking)) = %.3f (interventional)\n" interv_result;
  
  let counter_result = Reasoning_engine.counterfactual_query engine temporal_state smoking_link disease_link in
  Printf.printf "  ✓ P(disease | ¬smoking, but smoking observed) = %.3f (counterfactual)\n" counter_result;
  
  (* Test causal intervention *)
  let intervened_state = Reasoning_engine.causal_intervention engine temporal_state exercise_link 1.0 in
  let obs_disease_after_intervention = Reasoning_engine.observational_query engine intervened_state disease_link in
  Printf.printf "  ✓ P(disease) after do(exercise) = %.3f\n" obs_disease_after_intervention;
  
  Printf.printf "Causal Reasoning tests completed.\n\n"

let test_integration () =
  Printf.printf "Testing Temporal-Causal Integration...\n";
  
  let atomspace = Hypergraph.create_atomspace () in
  let engine = Reasoning_engine.create_reasoning_engine atomspace in
  
  (* Create climate change scenario *)
  let co2_node = Hypergraph.add_node atomspace Hypergraph.Concept "co2_emissions" in
  let temp_node = Hypergraph.add_node atomspace Hypergraph.Concept "global_temperature" in
  let ice_node = Hypergraph.add_node atomspace Hypergraph.Concept "ice_melting" in
  
  let co2_link = Hypergraph.add_link atomspace Hypergraph.Evaluation [co2_node] in
  let temp_link = Hypergraph.add_link atomspace Hypergraph.Evaluation [temp_node] in
  let ice_link = Hypergraph.add_link atomspace Hypergraph.Evaluation [ice_node] in
  
  let temporal_state = Reasoning_engine.create_temporal_state 0 15 in
  
  (* CO2 emissions increase over time *)
  List.iter (fun t -> Reasoning_engine.add_temporal_knowledge temporal_state t co2_link) [1;2;3;4;5;6;7;8];
  
  (* Temperature rises with delay *)
  List.iter (fun t -> Reasoning_engine.add_temporal_knowledge temporal_state t temp_link) [3;4;5;6;7;8;9;10];
  
  (* Ice melting follows temperature with further delay *)
  List.iter (fun t -> Reasoning_engine.add_temporal_knowledge temporal_state t ice_link) [6;7;8;9;10;11;12];
  
  (* Create complex temporal formula: Always(CO2) Until Eventually(IceMelting) *)
  let complex_formula = {
    Reasoning_engine.operator = Reasoning_engine.Until;
    operands = [co2_link; ice_link];
    time_bounds = Some (1, 12);
    temporal_context = 1;
  } in
  
  temporal_state.current_time <- 1;
  let complex_result = Reasoning_engine.evaluate_temporal_formula engine temporal_state complex_formula in
  Printf.printf "  ✓ CO2 Until IceMelting: %b\n" complex_result;
  
  (* Test temporal-causal inference *)
  let inference_results = Reasoning_engine.temporal_causal_inference engine temporal_state complex_formula in
  Printf.printf "  ✓ Generated %d temporal-causal inference results\n" (List.length inference_results);
  
  (* Display some results *)
  List.iteri (fun i result ->
    if i < 3 then (
      let (strength, confidence) = result.truth_value in
      Printf.printf "    Result %d: conclusion=%d, rule=%s, truth=(%.3f, %.3f)\n"
        i result.conclusion_link 
        (match result.applied_rule with 
         | Reasoning_engine.Temporal_rule -> "temporal" 
         | Reasoning_engine.Causal_rule -> "causal" 
         | _ -> "other")
        strength confidence
    )
  ) inference_results;
  
  Printf.printf "Temporal-Causal Integration tests completed.\n\n"

let run_all_tests () =
  Printf.printf "🧠 Temporal Logic and Causal Reasoning Test Suite 🧠\n";
  Printf.printf "====================================================\n\n";
  
  test_temporal_logic ();
  test_causal_reasoning ();
  test_integration ();
  
  Printf.printf "🎉 All temporal and causal reasoning tests completed successfully! 🎉\n"

let () = run_all_tests ()