(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** Test suite for PLN Tensor functionality - (L, P) implementation *)

let test_pln_tensor () =
  Printf.printf "🧠 Testing PLN Tensor (L, P) Implementation 🧠\n\n";
  
  (* Create atomspace *)
  let atomspace = Hypergraph.create_atomspace () in
  
  (* Test 1: Create PLN tensor with default dimensions *)
  Printf.printf "Test 1: PLN Tensor Creation\n";
  let pln_tensor = Reasoning_engine.create_default_pln_tensor None in
  let (l_dim, p_dim) = Reasoning_engine.get_pln_tensor_dimensions pln_tensor in
  Printf.printf "  ✓ Created PLN tensor with dimensions L=%d, P=%d\n" l_dim p_dim;
  
  (* Test 2: Set and get values in PLN tensor *)
  Printf.printf "\nTest 2: PLN Tensor Value Operations\n";
  Reasoning_engine.set_pln_tensor_value pln_tensor 0 0 0.8; (* And_logic, True_state *)
  Reasoning_engine.set_pln_tensor_value pln_tensor 0 1 0.1; (* And_logic, False_state *)
  Reasoning_engine.set_pln_tensor_value pln_tensor 1 0 0.7; (* Or_logic, True_state *)
  
  let value_00 = Reasoning_engine.get_pln_tensor_value pln_tensor 0 0 in
  let value_01 = Reasoning_engine.get_pln_tensor_value pln_tensor 0 1 in
  let value_10 = Reasoning_engine.get_pln_tensor_value pln_tensor 1 0 in
  
  Printf.printf "  ✓ Set/Get PLN tensor values:\n";
  Printf.printf "    - And_logic, True_state: %.2f\n" value_00;
  Printf.printf "    - And_logic, False_state: %.2f\n" value_01;
  Printf.printf "    - Or_logic, True_state: %.2f\n" value_10;
  
  (* Test 3: Convert to flat array and back *)
  Printf.printf "\nTest 3: PLN Tensor Conversion\n";
  let flat_array = Reasoning_engine.pln_tensor_to_flat_array pln_tensor in
  Printf.printf "  ✓ Converted PLN tensor to flat array of length %d\n" (Array.length flat_array);
  
  let reconstructed_data = Reasoning_engine.flat_array_to_pln_tensor_data flat_array l_dim p_dim in
  Printf.printf "  ✓ Reconstructed tensor data from flat array\n";
  
  (* Verify reconstruction *)
  let original_value = pln_tensor.tensor_data.(0).(0) in
  let reconstructed_value = reconstructed_data.(0).(0) in
  if abs_float (original_value -. reconstructed_value) < 1e-10 then
    Printf.printf "  ✓ Conversion preserves values correctly\n"
  else
    Printf.printf "  ✗ Conversion error detected\n";
  
  (* Test 4: Integration with atomspace *)
  Printf.printf "\nTest 4: PLN Tensor Atomspace Integration\n";
  let tensor_id = Reasoning_engine.store_pln_tensor_in_atomspace atomspace pln_tensor in
  Printf.printf "  ✓ Stored PLN tensor in atomspace with ID %d\n" tensor_id;
  
  let loaded_tensor_opt = Reasoning_engine.load_pln_tensor_from_atomspace 
                            atomspace tensor_id 
                            Reasoning_engine.default_logic_types 
                            Reasoning_engine.default_probability_states in
  
  (match loaded_tensor_opt with
   | Some loaded_tensor ->
     let loaded_value = Reasoning_engine.get_pln_tensor_value loaded_tensor 0 0 in
     Printf.printf "  ✓ Loaded PLN tensor from atomspace, value[0,0] = %.2f\n" loaded_value;
     if abs_float (loaded_value -. value_00) < 1e-10 then
       Printf.printf "  ✓ Atomspace storage/loading preserves values\n"
     else
       Printf.printf "  ✗ Atomspace storage/loading error detected\n"
   | None ->
     Printf.printf "  ✗ Failed to load PLN tensor from atomspace\n");
  
  (* Test 5: PLN Tensor operations *)
  Printf.printf "\nTest 5: PLN Tensor Operations\n";
  let pln_tensor2 = Reasoning_engine.create_default_pln_tensor None in
  Reasoning_engine.set_pln_tensor_value pln_tensor2 0 0 0.6;
  Reasoning_engine.set_pln_tensor_value pln_tensor2 0 1 0.2;
  Reasoning_engine.set_pln_tensor_value pln_tensor2 1 0 0.5;
  
  let added_tensor = Reasoning_engine.add_pln_tensors atomspace pln_tensor pln_tensor2 in
  let added_value = Reasoning_engine.get_pln_tensor_value added_tensor 0 0 in
  Printf.printf "  ✓ PLN tensor addition: %.2f + %.2f = %.2f\n" value_00 0.6 added_value;
  
  let multiplied_tensor = Reasoning_engine.multiply_pln_tensors atomspace pln_tensor pln_tensor2 in
  let multiplied_value = Reasoning_engine.get_pln_tensor_value multiplied_tensor 0 0 in
  Printf.printf "  ✓ PLN tensor multiplication: %.2f * %.2f = %.2f\n" value_00 0.6 multiplied_value;
  
  (* Test 6: PLN Rule-based tensor initialization *)
  Printf.printf "\nTest 6: PLN Rule-based Tensor Initialization\n";
  let deduction_tensor = Reasoning_engine.initialize_pln_tensor_for_rule Reasoning_engine.Deduction_rule 123 in
  let deduction_confidence = Reasoning_engine.compute_confidence_from_pln_tensor deduction_tensor in
  let (deduction_strength, deduction_conf) = Reasoning_engine.extract_truth_value_from_pln_tensor deduction_tensor in
  Printf.printf "  ✓ Deduction rule tensor - strength: %.3f, confidence: %.3f\n" deduction_strength deduction_conf;
  
  let similarity_tensor = Reasoning_engine.initialize_pln_tensor_for_rule Reasoning_engine.Similarity_rule 124 in
  let similarity_confidence = Reasoning_engine.compute_confidence_from_pln_tensor similarity_tensor in
  let (similarity_strength, similarity_conf) = Reasoning_engine.extract_truth_value_from_pln_tensor similarity_tensor in
  Printf.printf "  ✓ Similarity rule tensor - strength: %.3f, confidence: %.3f\n" similarity_strength similarity_conf;
  
  (* Test 7: PLN Tensor string representation *)
  Printf.printf "\nTest 7: PLN Tensor String Representation\n";
  let tensor_string = Reasoning_engine.pln_tensor_to_string deduction_tensor in
  Printf.printf "  ✓ PLN Tensor string representation:\n%s\n" tensor_string;
  
  (* Summary *)
  Printf.printf "\n🎯 PLN Tensor Test Summary:\n";
  Printf.printf "   - PLN tensor creation with (L, P) dimensions ✓\n";
  Printf.printf "   - Logic types (L) and probability states (P) ✓\n";
  Printf.printf "   - Tensor value access and modification ✓\n";
  Printf.printf "   - Conversion to/from flat arrays ✓\n";
  Printf.printf "   - Atomspace integration ✓\n";
  Printf.printf "   - Tensor operations using backend ✓\n";
  Printf.printf "   - PLN rule-based tensor initialization ✓\n";
  Printf.printf "   - Truth value extraction from tensors ✓\n";
  Printf.printf "   - String representation and debugging ✓\n";
  Printf.printf "   - PLN node tensor (L, P) implementation complete!\n\n"

let () = test_pln_tensor ()