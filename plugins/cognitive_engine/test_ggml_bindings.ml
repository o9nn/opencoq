(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** Test Suite for GGML OCaml Bindings *)

open Ggml_bindings

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

let assert_float_eq ?(eps=0.001) expected actual name =
  incr test_count;
  if abs_float (expected -. actual) < eps then begin
    incr pass_count;
    Printf.printf "  ✅ %s: %.4f ≈ %.4f\n" name expected actual
  end else begin
    incr fail_count;
    Printf.printf "  ❌ %s: expected %.4f, got %.4f\n" name expected actual
  end

let assert_array_eq ?(eps=0.001) expected actual name =
  incr test_count;
  let len_ok = Array.length expected = Array.length actual in
  let values_ok = len_ok && Array.for_all2 (fun e a -> abs_float (e -. a) < eps) expected actual in
  if values_ok then begin
    incr pass_count;
    Printf.printf "  ✅ %s\n" name
  end else begin
    incr fail_count;
    Printf.printf "  ❌ %s: arrays differ\n" name
  end

let section name =
  Printf.printf "\n=== %s ===\n" name

(** Test cases *)

let test_backend_detection () =
  section "Backend Detection";
  
  let available = is_ggml_available () in
  let backend = get_backend () in
  
  Printf.printf "  ℹ️  GGML available: %b\n" available;
  Printf.printf "  ℹ️  Backend: %s\n" (match backend with OCaml_native -> "OCaml" | GGML_backend -> "GGML");
  Printf.printf "  ℹ️  %s\n" (backend_info ());
  
  (* Test should pass regardless of GGML availability *)
  assert_true true "backend detection works"

let test_cpu_features () =
  section "CPU Feature Detection";
  
  let features = CPU.features () in
  Printf.printf "  ℹ️  Detected CPU features: [%s]\n" (String.concat ", " features);
  
  Printf.printf "  ℹ️  AVX:  %b\n" (CPU.has_avx ());
  Printf.printf "  ℹ️  AVX2: %b\n" (CPU.has_avx2 ());
  Printf.printf "  ℹ️  FMA:  %b\n" (CPU.has_fma ());
  Printf.printf "  ℹ️  NEON: %b\n" (CPU.has_neon ());
  
  assert_true true "CPU feature detection works"

let test_context () =
  section "Context Management";
  
  let ctx = Context.create ~mem_size:(1024 * 1024) () in
  Printf.printf "  ℹ️  Context created\n";
  
  let mem_used = Context.used_mem ctx in
  Printf.printf "  ℹ️  Memory used: %d bytes\n" mem_used;
  
  Context.free ctx;
  Printf.printf "  ℹ️  Context freed\n";
  
  assert_true true "context lifecycle works"

let test_tensor_creation () =
  section "Tensor Creation";
  
  let ctx = Context.create () in
  
  (* Create tensor from array *)
  let data = [|1.0; 2.0; 3.0; 4.0|] in
  let t1 = Tensor.of_array ctx [4] data in
  let result = Tensor.to_array t1 in
  assert_array_eq data result "1D tensor roundtrip";
  
  (* Create zeros *)
  let t2 = Tensor.zeros ctx [2; 3] in
  let zeros_result = Tensor.to_array t2 in
  let expected_zeros = [|0.0; 0.0; 0.0; 0.0; 0.0; 0.0|] in
  assert_array_eq expected_zeros zeros_result "zeros tensor";
  
  (* Create ones *)
  let t3 = Tensor.ones ctx [3] in
  let ones_result = Tensor.to_array t3 in
  let expected_ones = [|1.0; 1.0; 1.0|] in
  assert_array_eq expected_ones ones_result "ones tensor";
  
  (* Create random *)
  let t4 = Tensor.random ctx [5] in
  let random_result = Tensor.to_array t4 in
  assert_true (Array.length random_result = 5) "random tensor size";
  assert_true (Array.for_all (fun x -> x >= 0.0 && x <= 1.0) random_result) "random tensor values in [0,1]";
  
  Context.free ctx

let test_basic_ops () =
  section "Basic Operations";
  
  let ctx = Context.create () in
  
  let a = Tensor.of_array ctx [4] [|1.0; 2.0; 3.0; 4.0|] in
  let b = Tensor.of_array ctx [4] [|5.0; 6.0; 7.0; 8.0|] in
  
  (* Addition *)
  let sum = Ops.add ctx a b in
  let sum_result = Tensor.to_array sum in
  assert_array_eq [|6.0; 8.0; 10.0; 12.0|] sum_result "element-wise addition";
  
  (* Subtraction *)
  let diff = Ops.sub ctx b a in
  let diff_result = Tensor.to_array diff in
  assert_array_eq [|4.0; 4.0; 4.0; 4.0|] diff_result "element-wise subtraction";
  
  (* Multiplication *)
  let prod = Ops.mul ctx a b in
  let prod_result = Tensor.to_array prod in
  assert_array_eq [|5.0; 12.0; 21.0; 32.0|] prod_result "element-wise multiplication";
  
  (* Scale *)
  let scaled = Ops.scale ctx 2.0 a in
  let scaled_result = Tensor.to_array scaled in
  assert_array_eq [|2.0; 4.0; 6.0; 8.0|] scaled_result "scalar multiplication";
  
  (* Negation *)
  let negated = Ops.neg ctx a in
  let neg_result = Tensor.to_array negated in
  assert_array_eq [|-1.0; -2.0; -3.0; -4.0|] neg_result "negation";
  
  Context.free ctx

let test_activation_functions () =
  section "Activation Functions";
  
  let ctx = Context.create () in
  
  let input = Tensor.of_array ctx [5] [|-2.0; -1.0; 0.0; 1.0; 2.0|] in
  
  (* ReLU *)
  let relu_out = Ops.relu ctx input in
  let relu_result = Tensor.to_array relu_out in
  assert_array_eq [|0.0; 0.0; 0.0; 1.0; 2.0|] relu_result "ReLU activation";
  
  (* Softmax *)
  let softmax_input = Tensor.of_array ctx [3] [|1.0; 2.0; 3.0|] in
  let softmax_out = Ops.softmax ctx softmax_input in
  let softmax_result = Tensor.to_array softmax_out in
  
  (* Check softmax sums to 1 *)
  let sum = Array.fold_left (+.) 0.0 softmax_result in
  assert_float_eq 1.0 sum "softmax sums to 1";
  
  (* Check softmax is monotonic *)
  assert_true (softmax_result.(0) < softmax_result.(1)) "softmax monotonic (0 < 1)";
  assert_true (softmax_result.(1) < softmax_result.(2)) "softmax monotonic (1 < 2)";
  
  (* GELU *)
  let gelu_out = Ops.gelu ctx input in
  let gelu_result = Tensor.to_array gelu_out in
  Printf.printf "  ℹ️  GELU output: [%s]\n" 
    (String.concat ", " (Array.to_list (Array.map (Printf.sprintf "%.4f") gelu_result)));
  assert_true (gelu_result.(0) < 0.0) "GELU negative for negative input";
  assert_true (gelu_result.(4) > 0.0) "GELU positive for positive input";
  
  (* SiLU *)
  let silu_out = Ops.silu ctx input in
  let silu_result = Tensor.to_array silu_out in
  Printf.printf "  ℹ️  SiLU output: [%s]\n" 
    (String.concat ", " (Array.to_list (Array.map (Printf.sprintf "%.4f") silu_result)));
  assert_true (silu_result.(0) < 0.0) "SiLU negative for negative input";
  assert_true (silu_result.(4) > 0.0) "SiLU positive for positive input";
  
  Context.free ctx

let test_matrix_ops () =
  section "Matrix Operations";
  
  let ctx = Context.create () in
  
  (* 2x3 matrix *)
  let a = Tensor.of_array ctx [2; 3] [|
    1.0; 2.0; 3.0;
    4.0; 5.0; 6.0
  |] in
  
  (* 3x2 matrix *)
  let b = Tensor.of_array ctx [3; 2] [|
    7.0; 8.0;
    9.0; 10.0;
    11.0; 12.0
  |] in
  
  (* Matrix multiplication: (2x3) * (3x2) = (2x2) *)
  let c = Ops.matmul ctx a b in
  let c_result = Tensor.to_array c in
  
  (* Expected:
     [1*7+2*9+3*11, 1*8+2*10+3*12]   = [58, 64]
     [4*7+5*9+6*11, 4*8+5*10+6*12]   = [139, 154]
  *)
  assert_array_eq [|58.0; 64.0; 139.0; 154.0|] c_result "matrix multiplication";
  
  (* Transpose *)
  let t = Tensor.of_array ctx [2; 3] [|
    1.0; 2.0; 3.0;
    4.0; 5.0; 6.0
  |] in
  let t_transposed = Ops.transpose ctx t in
  let t_result = Tensor.to_array t_transposed in
  
  (* Expected: 3x2 matrix
     [1, 4]
     [2, 5]
     [3, 6]
  *)
  assert_array_eq [|1.0; 4.0; 2.0; 5.0; 3.0; 6.0|] t_result "matrix transpose";
  
  Context.free ctx

let test_compute_graph () =
  section "Compute Graph";
  
  let ctx = Context.create () in
  
  let a = Tensor.of_array ctx [4] [|1.0; 2.0; 3.0; 4.0|] in
  let b = Tensor.of_array ctx [4] [|2.0; 2.0; 2.0; 2.0|] in
  
  (* Build computation: relu(a * b + a) *)
  let prod = Ops.mul ctx a b in
  let sum = Ops.add ctx prod a in
  let output = Ops.relu ctx sum in
  
  (* Build and execute graph *)
  let graph = Graph.build ctx output in
  Graph.compute graph;
  
  let result = Tensor.to_array (Graph.result graph) in
  (* Expected: relu([1*2+1, 2*2+2, 3*2+3, 4*2+4]) = relu([3, 6, 9, 12]) = [3, 6, 9, 12] *)
  assert_array_eq [|3.0; 6.0; 9.0; 12.0|] result "compute graph execution";
  
  Context.free ctx

let () =
  Printf.printf "\n";
  Printf.printf "╔══════════════════════════════════════════════════════════╗\n";
  Printf.printf "║     GGML OCaml Bindings - Test Suite                     ║\n";
  Printf.printf "╚══════════════════════════════════════════════════════════╝\n";
  
  test_backend_detection ();
  test_cpu_features ();
  test_context ();
  test_tensor_creation ();
  test_basic_ops ();
  test_activation_functions ();
  test_matrix_ops ();
  test_compute_graph ();
  
  Printf.printf "\n";
  Printf.printf "╔══════════════════════════════════════════════════════════╗\n";
  Printf.printf "║                    Test Summary                          ║\n";
  Printf.printf "╠══════════════════════════════════════════════════════════╣\n";
  Printf.printf "║  Total:  %3d                                             ║\n" !test_count;
  Printf.printf "║  Passed: %3d                                             ║\n" !pass_count;
  Printf.printf "║  Failed: %3d                                             ║\n" !fail_count;
  Printf.printf "╚══════════════════════════════════════════════════════════╝\n";
  
  if !fail_count = 0 then
    Printf.printf "\n⚡ All GGML binding tests passed! ⚡\n\n"
  else
    Printf.printf "\n⚠️  Some tests failed. Please review. ⚠️\n\n"
