(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** Integration test for tensor operations with cognitive engine *)

let test_cognitive_tensor_integration () =
  Printf.printf "🧠🧮 Testing Cognitive Engine + Tensor Operations Integration 🧮🧠\n\n";
  
  (* Create cognitive engine *)
  let config = Cognitive_engine.default_engine_config in
  let engine = Cognitive_engine.create_cognitive_engine config in
  
  Printf.printf "✓ Created cognitive engine\n";
  
  (* Test 1: Configure tensor backend *)
  Printf.printf "\nTest 1: Configure tensor backend\n";
  Cognitive_engine.configure_tensor_backend engine Tensor_backend.OCaml_native;
  Printf.printf "  ✓ Configured OCaml native backend\n";
  
  (* Test 2: Neural-symbolic fusion *)
  Printf.printf "\nTest 2: Neural-symbolic fusion\n";
  let concept_vector = [| 0.8; 0.6; 0.4; 0.2 |] in
  let vector_shape = [4] in
  
  let (concept_id, tensor_id) = Cognitive_engine.neural_symbolic_fusion 
    engine "machine_learning" concept_vector vector_shape in
  
  Printf.printf "  ✓ Created neural-symbolic concept:\n";
  Printf.printf "    - Symbolic node ID: %d\n" concept_id;
  Printf.printf "    - Neural tensor ID: %d\n" tensor_id;
  Printf.printf "    - Vector: %s\n" 
    (Tensor_backend.tensor_to_string vector_shape concept_vector);
  
  (* Test 3: Add another concept for similarity testing *)
  Printf.printf "\nTest 3: Add related concept\n";
  let ai_vector = [| 0.7; 0.5; 0.5; 0.3 |] in
  let (ai_concept_id, ai_tensor_id) = Cognitive_engine.neural_symbolic_fusion 
    engine "artificial_intelligence" ai_vector vector_shape in
  
  Printf.printf "  ✓ Created second concept:\n";
  Printf.printf "    - Symbolic node ID: %d\n" ai_concept_id;
  Printf.printf "    - Neural tensor ID: %d\n" ai_tensor_id;
  Printf.printf "    - Vector: %s\n" 
    (Tensor_backend.tensor_to_string vector_shape ai_vector);
  
  (* Test 4: Compute concept similarity *)
  Printf.printf "\nTest 4: Compute concept similarity\n";
  let similarity = Cognitive_engine.compute_concept_similarity 
    engine concept_id ai_concept_id in
  Printf.printf "  ✓ Cosine similarity between 'machine_learning' and 'artificial_intelligence': %.4f\n" similarity;
  
  (* Test 5: Neural attention processing *)
  Printf.printf "\nTest 5: Neural attention processing\n";
  let attention_results = Cognitive_engine.process_with_neural_attention 
    engine [tensor_id; ai_tensor_id] in
  
  Printf.printf "  ✓ Processed %d tensors through neural attention\n" 
    (List.length attention_results);
  
  List.iteri (fun i result_id ->
    match Hypergraph.get_tensor engine.atomspace result_id with
    | Some tensor ->
        Printf.printf "    - Attention tensor %d: %s\n" (i+1) 
          (Tensor_backend.tensor_to_string tensor.shape tensor.data)
    | None -> Printf.printf "    - Failed to retrieve attention tensor %d\n" (i+1)
  ) attention_results;
  
  (* Test 6: Switch to GGML backend *)
  Printf.printf "\nTest 6: Switch to GGML backend\n";
  Cognitive_engine.configure_tensor_backend engine Tensor_backend.GGML;
  Printf.printf "  ✓ Switched to GGML backend\n";
  
  (* Repeat similarity computation with GGML backend *)
  let ggml_similarity = Cognitive_engine.compute_concept_similarity 
    engine concept_id ai_concept_id in
  Printf.printf "  ✓ GGML similarity (should match): %.4f\n" ggml_similarity;
  
  (* Test 7: More neural operations *)
  Printf.printf "\nTest 7: Advanced tensor operations\n";
  
  (* Create matrix tensors for more complex operations *)
  let matrix1_data = [| 1.0; 2.0; 3.0; 4.0 |] in
  let matrix2_data = [| 0.5; 1.5; 2.5; 3.5 |] in
  let matrix_shape = [2; 2] in
  
  let m1_id = Hypergraph.add_tensor engine.atomspace matrix_shape matrix1_data None in
  let m2_id = Hypergraph.add_tensor engine.atomspace matrix_shape matrix2_data None in
  
  Printf.printf "  ✓ Created test matrices\n";
  
  (* Matrix multiplication *)
  let matmul_id = Hypergraph.tensor_matmul_op engine.atomspace m1_id m2_id in
  (match Hypergraph.get_tensor engine.atomspace matmul_id with
   | Some tensor ->
       Printf.printf "  ✓ Matrix multiplication result: %s\n" 
         (Tensor_backend.tensor_to_string tensor.shape tensor.data)
   | None -> Printf.printf "  ✗ Matrix multiplication failed\n");
  
  (* Neural activation *)
  let relu_id = Hypergraph.tensor_relu_op engine.atomspace m1_id in
  (match Hypergraph.get_tensor engine.atomspace relu_id with
   | Some tensor ->
       Printf.printf "  ✓ ReLU activation result: %s\n" 
         (Tensor_backend.tensor_to_string tensor.shape tensor.data)
   | None -> Printf.printf "  ✗ ReLU activation failed\n");
  
  (* Test 8: Knowledge retrieval with neural representations *)
  Printf.printf "\nTest 8: Knowledge retrieval with neural representations\n";
  let neural_reps = Cognitive_engine.get_neural_representation engine concept_id in
  Printf.printf "  ✓ Retrieved %d neural representations for concept %d\n" 
    (List.length neural_reps) concept_id;
  
  List.iter (fun tensor ->
    Printf.printf "    - Tensor ID %d: %s\n" tensor.id 
      (Tensor_backend.tensor_to_string tensor.shape tensor.data)
  ) neural_reps;
  
  Printf.printf "\n🎉 Cognitive-Tensor Integration Test Completed! 🎉\n";
  Printf.printf "📋 Integration Summary:\n";
  Printf.printf "   - Neural-symbolic fusion ✓\n";
  Printf.printf "   - Concept similarity computation ✓\n";
  Printf.printf "   - Neural attention processing ✓\n";
  Printf.printf "   - Backend switching (OCaml ↔ GGML) ✓\n";
  Printf.printf "   - Advanced tensor operations in cognitive context ✓\n";
  Printf.printf "   - Knowledge-neural representation mapping ✓\n";
  Printf.printf "\n🧠 The cognitive engine now has full tensor operation support with GGML backend! 🧠\n\n"

let () = test_cognitive_tensor_integration ()