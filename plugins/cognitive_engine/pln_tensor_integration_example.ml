(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** PLN Tensor Integration Example - Shows how PLN tensors work with the cognitive engine *)

let pln_tensor_integration_example () =
  Printf.printf "🧠 PLN Tensor Integration with Cognitive Engine 🧠\n\n";
  
  (* Step 1: Create cognitive infrastructure *)
  Printf.printf "1. Setting up cognitive infrastructure...\n";
  let atomspace = Hypergraph.create_atomspace () in
  let engine = Reasoning_engine.create_reasoning_engine atomspace in
  Printf.printf "   ✓ Created atomspace and reasoning engine\n";
  
  (* Step 2: Create concepts and their PLN tensors *)
  Printf.printf "\n2. Creating concepts with PLN tensors...\n";
  
  let animal_id = Hypergraph.add_node atomspace Hypergraph.Concept "Animal" in
  let mammal_id = Hypergraph.add_node atomspace Hypergraph.Concept "Mammal" in
  let dog_id = Hypergraph.add_node atomspace Hypergraph.Concept "Dog" in
  
  Printf.printf "   ✓ Created concepts: Animal (%d), Mammal (%d), Dog (%d)\n" animal_id mammal_id dog_id;
  
  (* Step 3: Initialize PLN tensors for different reasoning patterns *)
  Printf.printf "\n3. Initializing PLN tensors for reasoning patterns...\n";
  
  (* Inheritance: Dog inherits from Mammal *)
  let inheritance_tensor = Reasoning_engine.initialize_pln_tensor_for_rule 
                             Reasoning_engine.Inheritance_rule dog_id in
  (* Set high inheritance probability from Dog to Mammal *)
  Reasoning_engine.set_pln_tensor_value inheritance_tensor 5 0 0.95; (* Inheritance_logic, True_state *)
  Reasoning_engine.set_pln_tensor_value inheritance_tensor 5 1 0.02; (* Inheritance_logic, False_state *)
  
  let inheritance_tensor_id = Reasoning_engine.store_pln_tensor_in_atomspace atomspace inheritance_tensor in
  Printf.printf "   ✓ Dog→Mammal inheritance tensor (ID: %d)\n" inheritance_tensor_id;
  
  (* Deduction: If Dog→Mammal and Mammal→Animal, then Dog→Animal *)
  let deduction_tensor = Reasoning_engine.initialize_pln_tensor_for_rule 
                           Reasoning_engine.Deduction_rule mammal_id in
  (* Set implication probabilities *)
  Reasoning_engine.set_pln_tensor_value deduction_tensor 3 0 0.90; (* Implication_logic, True_state *)
  Reasoning_engine.set_pln_tensor_value deduction_tensor 3 1 0.05; (* Implication_logic, False_state *)
  
  let deduction_tensor_id = Reasoning_engine.store_pln_tensor_in_atomspace atomspace deduction_tensor in
  Printf.printf "   ✓ Mammal→Animal deduction tensor (ID: %d)\n" deduction_tensor_id;
  
  (* Step 4: Perform tensor operations *)
  Printf.printf "\n4. Performing PLN tensor operations...\n";
  
  (* Combine inheritance and deduction tensors *)
  let combined_tensor = Reasoning_engine.multiply_pln_tensors atomspace inheritance_tensor deduction_tensor in
  let (combined_strength, combined_confidence) = Reasoning_engine.extract_truth_value_from_pln_tensor combined_tensor in
  Printf.printf "   ✓ Combined reasoning: strength=%.3f, confidence=%.3f\n" combined_strength combined_confidence;
  
  (* Step 5: Extract reasoning results *)
  Printf.printf "\n5. Extracting reasoning results...\n";
  
  let inheritance_strength, inheritance_conf = Reasoning_engine.extract_truth_value_from_pln_tensor inheritance_tensor in
  let deduction_strength, deduction_conf = Reasoning_engine.extract_truth_value_from_pln_tensor deduction_tensor in
  
  Printf.printf "   ✓ Inheritance reasoning: strength=%.3f, confidence=%.3f\n" inheritance_strength inheritance_conf;
  Printf.printf "   ✓ Deduction reasoning: strength=%.3f, confidence=%.3f\n" deduction_strength deduction_conf;
  
  (* Step 6: Create logical links in atomspace *)
  Printf.printf "\n6. Creating logical links based on PLN tensor results...\n";
  
  let inheritance_link = Hypergraph.add_link atomspace Hypergraph.Inheritance [dog_id; mammal_id] in
  let implication_link = Hypergraph.add_link atomspace Hypergraph.Implication [mammal_id; animal_id] in
  
  (* Update truth values based on PLN tensor analysis *)
  Hypergraph.update_link_truth atomspace inheritance_link (inheritance_strength, inheritance_conf);
  Hypergraph.update_link_truth atomspace implication_link (deduction_strength, deduction_conf);
  
  Printf.printf "   ✓ Created inheritance link %d with truth value (%.3f, %.3f)\n" 
    inheritance_link inheritance_strength inheritance_conf;
  Printf.printf "   ✓ Created implication link %d with truth value (%.3f, %.3f)\n" 
    implication_link deduction_strength deduction_conf;
  
  (* Step 7: Demonstrate tensor-based reasoning query *)
  Printf.printf "\n7. Demonstrating tensor-based reasoning query...\n";
  
  (* Question: What's the probability that Dog is an Animal? *)
  (* This would combine the inheritance and implication chains *)
  let query_tensor = Reasoning_engine.multiply_pln_tensors atomspace inheritance_tensor deduction_tensor in
  let (final_strength, final_confidence) = Reasoning_engine.extract_truth_value_from_pln_tensor query_tensor in
  
  Printf.printf "   ✓ Query: 'Is Dog an Animal?'\n";
  Printf.printf "     Answer: strength=%.3f, confidence=%.3f\n" final_strength final_confidence;
  Printf.printf "     Interpretation: %.1f%% probability with %.1f%% confidence\n" 
    (final_strength *. 100.0) (final_confidence *. 100.0);
  
  (* Step 8: Show tensor details *)
  Printf.printf "\n8. PLN Tensor Details:\n";
  let tensor_details = Reasoning_engine.pln_tensor_to_string inheritance_tensor in
  Printf.printf "%s\n" tensor_details;
  
  (* Summary *)
  Printf.printf "🎯 PLN Tensor Integration Summary:\n";
  Printf.printf "   - Created concepts and associated PLN tensors ✓\n";
  Printf.printf "   - Used rule-specific tensor initialization ✓\n";
  Printf.printf "   - Performed tensor operations (multiplication) ✓\n";
  Printf.printf "   - Extracted truth values for logical reasoning ✓\n";
  Printf.printf "   - Integrated with atomspace for knowledge storage ✓\n";
  Printf.printf "   - Demonstrated multi-step reasoning with tensors ✓\n";
  Printf.printf "   - PLN (L, P) tensor reasoning pipeline complete!\n\n"

let () = pln_tensor_integration_example ()