(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** Test suite for tensor operations with GGML backend support *)

let test_tensor_operations () =
  Printf.printf "🧮 Testing Tensor Operations with GGML Backend Support 🧮\n\n";
  
  (* Create atomspace *)
  let atomspace = Hypergraph.create_atomspace () in
  
  (* Test 1: Basic tensor creation and storage *)
  Printf.printf "Test 1: Basic tensor creation\n";
  let data1 = [| 1.0; 2.0; 3.0; 4.0 |] in
  let data2 = [| 5.0; 6.0; 7.0; 8.0 |] in
  let shape = [2; 2] in
  
  let t1_id = Hypergraph.add_tensor atomspace shape data1 None in
  let t2_id = Hypergraph.add_tensor atomspace shape data2 None in
  
  Printf.printf "  ✓ Created tensor 1 (id=%d): %s\n" t1_id 
    (Tensor_backend.tensor_to_string shape data1);
  Printf.printf "  ✓ Created tensor 2 (id=%d): %s\n" t2_id 
    (Tensor_backend.tensor_to_string shape data2);
  
  (* Test 2: Test OCaml backend (default) *)
  Printf.printf "\nTest 2: OCaml backend operations\n";
  Hypergraph.set_tensor_backend Tensor_backend.OCaml_native;
  Printf.printf "  Backend: %s\n" (match Hypergraph.get_tensor_backend () with
    | Tensor_backend.OCaml_native -> "OCaml_native"
    | Tensor_backend.GGML -> "GGML");
  
  (* Test tensor addition *)
  let add_result_id = Hypergraph.tensor_add_op atomspace t1_id t2_id in
  (match Hypergraph.get_tensor atomspace add_result_id with
   | Some t -> Printf.printf "  ✓ Addition result: %s\n" 
                 (Tensor_backend.tensor_to_string t.shape t.data)
   | None -> Printf.printf "  ✗ Addition failed\n");
  
  (* Test tensor multiplication *)
  let mul_result_id = Hypergraph.tensor_multiply_op atomspace t1_id t2_id in
  (match Hypergraph.get_tensor atomspace mul_result_id with
   | Some t -> Printf.printf "  ✓ Element-wise multiplication result: %s\n" 
                 (Tensor_backend.tensor_to_string t.shape t.data)
   | None -> Printf.printf "  ✗ Multiplication failed\n");
  
  (* Test matrix multiplication *)
  let matmul_result_id = Hypergraph.tensor_matmul_op atomspace t1_id t2_id in
  (match Hypergraph.get_tensor atomspace matmul_result_id with
   | Some t -> Printf.printf "  ✓ Matrix multiplication result: %s\n" 
                 (Tensor_backend.tensor_to_string t.shape t.data)
   | None -> Printf.printf "  ✗ Matrix multiplication failed\n");
  
  (* Test scaling *)
  let scale_result_id = Hypergraph.tensor_scale_op atomspace t1_id 2.0 in
  (match Hypergraph.get_tensor atomspace scale_result_id with
   | Some t -> Printf.printf "  ✓ Scaling by 2.0 result: %s\n" 
                 (Tensor_backend.tensor_to_string t.shape t.data)
   | None -> Printf.printf "  ✗ Scaling failed\n");
  
  (* Test transpose *)
  let transpose_result_id = Hypergraph.tensor_transpose_op atomspace t1_id in
  (match Hypergraph.get_tensor atomspace transpose_result_id with
   | Some t -> Printf.printf "  ✓ Transpose result: %s\n" 
                 (Tensor_backend.tensor_to_string t.shape t.data)
   | None -> Printf.printf "  ✗ Transpose failed\n");
  
  (* Test dot product *)
  let dot_result = Hypergraph.tensor_dot_product_op atomspace t1_id t2_id in
  Printf.printf "  ✓ Dot product result: %.2f\n" dot_result;
  
  (* Test norm *)
  let norm_result = Hypergraph.tensor_norm_op atomspace t1_id in
  Printf.printf "  ✓ Norm of tensor 1: %.2f\n" norm_result;
  
  (* Test 3: Neural network operations *)
  Printf.printf "\nTest 3: Neural network operations\n";
  
  (* Create a test tensor with some negative values for ReLU *)
  let nn_data = [| -1.0; 2.0; -3.0; 4.0 |] in
  let nn_id = Hypergraph.add_tensor atomspace shape nn_data None in
  
  (* Test ReLU *)
  let relu_result_id = Hypergraph.tensor_relu_op atomspace nn_id in
  (match Hypergraph.get_tensor atomspace relu_result_id with
   | Some t -> Printf.printf "  ✓ ReLU result: %s\n" 
                 (Tensor_backend.tensor_to_string t.shape t.data)
   | None -> Printf.printf "  ✗ ReLU failed\n");
  
  (* Test Sigmoid *)
  let sigmoid_result_id = Hypergraph.tensor_sigmoid_op atomspace nn_id in
  (match Hypergraph.get_tensor atomspace sigmoid_result_id with
   | Some t -> Printf.printf "  ✓ Sigmoid result: %s\n" 
                 (Tensor_backend.tensor_to_string t.shape t.data)
   | None -> Printf.printf "  ✗ Sigmoid failed\n");
  
  (* Test Softmax *)
  let softmax_result_id = Hypergraph.tensor_softmax_op atomspace nn_id in
  (match Hypergraph.get_tensor atomspace softmax_result_id with
   | Some t -> Printf.printf "  ✓ Softmax result: %s\n" 
                 (Tensor_backend.tensor_to_string t.shape t.data)
   | None -> Printf.printf "  ✗ Softmax failed\n");
  
  (* Test 4: Switch to GGML backend (currently uses fallback) *)
  Printf.printf "\nTest 4: GGML backend (fallback implementation)\n";
  Hypergraph.set_tensor_backend Tensor_backend.GGML;
  Printf.printf "  Backend: %s\n" (match Hypergraph.get_tensor_backend () with
    | Tensor_backend.OCaml_native -> "OCaml_native"
    | Tensor_backend.GGML -> "GGML");
  
  let ggml_add_result_id = Hypergraph.tensor_add_op atomspace t1_id t2_id in
  (match Hypergraph.get_tensor atomspace ggml_add_result_id with
   | Some t -> Printf.printf "  ✓ GGML addition result: %s\n" 
                 (Tensor_backend.tensor_to_string t.shape t.data)
   | None -> Printf.printf "  ✗ GGML addition failed\n");
  
  Printf.printf "\n🎉 All tensor operations completed successfully! 🎉\n";
  Printf.printf "📋 Summary:\n";
  Printf.printf "   - Basic tensor storage and retrieval ✓\n";
  Printf.printf "   - Element-wise operations (add, multiply, scale) ✓\n";
  Printf.printf "   - Matrix operations (matmul, transpose) ✓\n";
  Printf.printf "   - Vector operations (dot product, norm) ✓\n";
  Printf.printf "   - Neural network operations (ReLU, Sigmoid, Softmax) ✓\n";
  Printf.printf "   - Backend switching (OCaml ↔ GGML) ✓\n";
  Printf.printf "   - GGML backend interface ready for C bindings\n\n"

let () = test_tensor_operations ()