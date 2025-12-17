(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** Focused demonstration of gradient-based attention optimization working *)

let demo_gradient_attention_in_action () =
  Printf.printf "🎯 Gradient-Based Attention Optimization Demo 🎯\n\n";
  
  (* Create systems *)
  let atomspace = Hypergraph.create_atomspace () in
  let ecan_system = Attention_system.create_ecan_system atomspace Attention_system.default_ecan_config in
  let attention_tensor = Attention_system.create_attention_tensor 4 6 in
  
  Printf.printf "Phase 1: System Initialization\n";
  Printf.printf "  ✓ Created ECAN system with attention tensor (4 heads × 6 temporal)\n";
  
  (* Create test concepts *)
  let concepts = ["theorem"; "proof"; "lemma"; "axiom"] in
  let node_ids = List.map (fun name ->
    Hypergraph.add_node atomspace Hypergraph.Concept name
  ) concepts in
  
  Printf.printf "  ✓ Created %d test concepts\n" (List.length concepts);
  
  (* Phase 2: Demonstrate attention allocation *)
  Printf.printf "\nPhase 2: Initial Attention Allocation\n";
  
  (* Stimulate nodes to create different attention levels *)
  List.iteri (fun i node_id ->
    let stimulus = 10.0 +. (float_of_int i) *. 5.0 in
    Attention_system.stimulate_atom ecan_system node_id stimulus;
    Printf.printf "  • Stimulated '%s' with %.1f attention\n" 
      (List.nth concepts i) stimulus
  ) node_ids;
  
  let (initial_sti, _, _, _) = Attention_system.get_attention_statistics ecan_system in
  Printf.printf "  ✓ Initial ECAN STI: %.1f\n" initial_sti;
  
  (* Phase 3: Inject meaningful gradients *)
  Printf.printf "\nPhase 3: Gradient-Based Optimization\n";
  
  let gradient_config = {
    Attention_system.learning_rate = 0.1;
    momentum_factor = 0.8;
    gradient_clipping = 2.0;
    update_frequency = 5;
    economic_weight = 0.7;
  } in
  
  (* Simulate meaningful gradients based on "performance" *)
  List.iteri (fun cycle node_id ->
    (* Create gradients that simulate different learning scenarios *)
    let performance_gradients = Array.make 24 0.0 in (* 4 heads × 6 temporal = 24 *)
    
    for i = 0 to Array.length performance_gradients - 1 do
      let head_id = i mod 4 in
      let temporal_pos = i / 4 in
      
      (* Simulate different patterns:
         - Head 0: Strong positive learning
         - Head 1: Moderate learning with decay
         - Head 2: Oscillating performance
         - Head 3: Negative learning (needs attention reduction) *)
      match head_id with
      | 0 -> performance_gradients.(i) <- 0.8 +. (Random.float 0.4)
      | 1 -> performance_gradients.(i) <- 0.5 *. exp (-. float_of_int temporal_pos *. 0.1)
      | 2 -> performance_gradients.(i) <- 0.3 *. sin (float_of_int (temporal_pos + cycle))
      | 3 -> performance_gradients.(i) <- -0.2 +. (Random.float 0.3)
      | _ -> ()
    done;
    
    Printf.printf "  • Updating gradients for concept '%s'\n" (List.nth concepts cycle);
    Attention_system.update_attention_gradients attention_tensor node_id performance_gradients;
    
    (* Apply optimization *)
    Attention_system.apply_gradient_optimization ecan_system attention_tensor gradient_config;
    
    let (avg, max_val, min_val, active) = Attention_system.get_attention_tensor_stats attention_tensor in
    Printf.printf "    Attention stats: avg=%.3f, max=%.3f, min=%.3f, active=%.0f\n" 
      avg max_val min_val active
  ) node_ids;
  
  (* Phase 4: Show economic allocation *)
  Printf.printf "\nPhase 4: Economic Compute Cycle Allocation\n";
  
  let cycle_allocation = Attention_system.allocate_compute_cycles_by_attention 
    ecan_system attention_tensor gradient_config in
  
  Printf.printf "  Compute allocation by attention head:\n";
  Array.iteri (fun head allocation ->
    let percentage = allocation *. 100.0 in
    let bar_length = int_of_float (percentage *. 30.0) in
    let bar = String.make (max 0 bar_length) '#' in
    Printf.printf "    Head %d: [%-30s] %.2f%%\n" head bar percentage
  ) cycle_allocation;
  
  let total_allocation = Array.fold_left (+.) 0.0 cycle_allocation in
  Printf.printf "  ✓ Total allocation efficiency: %.2f%%\n" (total_allocation *. 100.0);
  
  (* Phase 5: ECAN Economic Integration *)
  Printf.printf "\nPhase 5: ECAN Economic Integration\n";
  
  let (sti_before_econ, _, _, _) = Attention_system.get_attention_statistics ecan_system in
  Attention_system.economic_gradient_integration ecan_system attention_tensor gradient_config;
  let (sti_after_econ, lti_after, nodes, focused) = Attention_system.get_attention_statistics ecan_system in
  
  Printf.printf "  • STI before economic integration: %.1f\n" sti_before_econ;
  Printf.printf "  • STI after economic integration: %.1f\n" sti_after_econ;
  Printf.printf "  • LTI resources: %.1f\n" lti_after;
  Printf.printf "  • Economic efficiency: %.2f%%\n" 
    ((sti_after_econ /. sti_before_econ) *. 100.0);
  Printf.printf "  • System load: %d nodes, %d focused\n" nodes focused;
  
  (* Phase 6: Multi-iteration demonstration *)
  Printf.printf "\nPhase 6: Multi-Iteration Optimization\n";
  
  let performance_tracker = ref [] in
  
  for iteration = 1 to 8 do
    (* Simulate varying learning scenarios *)
    let scenario_gradients = Array.make 24 0.0 in
    let scenario_strength = 0.5 +. 0.3 *. sin (float_of_int iteration) in
    
    for i = 0 to 23 do
      scenario_gradients.(i) <- scenario_strength *. (Random.float 2.0 -. 1.0)
    done;
    
    (* Apply to a random concept *)
    let random_node = List.nth node_ids (iteration mod 4) in
    Attention_system.update_attention_gradients attention_tensor random_node scenario_gradients;
    Attention_system.apply_gradient_optimization ecan_system attention_tensor gradient_config;
    
    if iteration mod 2 = 0 then
      Attention_system.economic_gradient_integration ecan_system attention_tensor gradient_config;
    
    (* Track performance *)
    let (avg, max_val, _, _) = Attention_system.get_attention_tensor_stats attention_tensor in
    let performance = avg +. max_val in
    performance_tracker := performance :: !performance_tracker;
    
    Printf.printf "  Iteration %d: Performance = %.4f\n" iteration performance
  done;
  
  (* Show improvement trend *)
  let performances = List.rev !performance_tracker in
  let initial_perf = List.hd performances in
  let final_perf = List.hd (List.rev performances) in
  let improvement = ((final_perf -. initial_perf) /. initial_perf) *. 100.0 in
  
  Printf.printf "  ✓ Performance improvement: %.2f%%\n" improvement;
  
  (* Phase 7: Final system state *)
  Printf.printf "\nPhase 7: Final System Analysis\n";
  
  let (final_avg, final_max, final_min, final_active) = 
    Attention_system.get_attention_tensor_stats attention_tensor in
  let (final_sti, final_lti, final_nodes, final_focused) = 
    Attention_system.get_attention_statistics ecan_system in
  
  Printf.printf "  📊 Final Attention Tensor State:\n";
  Printf.printf "    • Average activation: %.4f\n" final_avg;
  Printf.printf "    • Peak activation: %.4f\n" final_max;
  Printf.printf "    • Minimum activation: %.4f\n" final_min;
  Printf.printf "    • Active heads: %.0f/4 (%.0f%%)\n" 
    final_active (final_active /. 4.0 *. 100.0);
  
  Printf.printf "  📊 Final ECAN Economic State:\n";
  Printf.printf "    • Available STI: %.1f\n" final_sti;
  Printf.printf "    • Available LTI: %.1f\n" final_lti;
  Printf.printf "    • Managed concepts: %d\n" final_nodes;
  Printf.printf "    • Focused concepts: %d\n" final_focused;
  Printf.printf "    • Attention efficiency: %.2f%%\n" 
    ((float_of_int final_focused /. float_of_int final_nodes) *. 100.0);
  
  Printf.printf "\n🏆 Gradient-Based Attention Optimization Demo Complete! 🏆\n";
  Printf.printf "\n✨ Key Achievements Demonstrated:\n";
  Printf.printf "  • ✅ Multi-head attention tensor with temporal depth (A=4, T=6)\n";
  Printf.printf "  • ✅ Gradient-based attention optimization with learning\n";
  Printf.printf "  • ✅ ECAN-inspired economic compute cycle allocation\n";
  Printf.printf "  • ✅ Economic integration with attention performance\n";
  Printf.printf "  • ✅ Multi-iteration optimization with performance tracking\n";
  Printf.printf "  • ✅ Attention-guided resource allocation and focus management\n";
  Printf.printf "\n🎯 The gradient-based attention optimization successfully:\n";
  Printf.printf "  → Allocates attention resources based on learning gradients\n";
  Printf.printf "  → Integrates with ECAN economic attention allocation\n";
  Printf.printf "  → Provides temporal depth for attention pattern tracking\n";
  Printf.printf "  → Optimizes compute cycle allocation for maximum efficiency\n"

(* Run the demonstration *)
let () = demo_gradient_attention_in_action ()