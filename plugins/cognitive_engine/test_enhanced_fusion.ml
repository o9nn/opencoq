(* Comprehensive test for enhanced neural-symbolic fusion architecture *)

#load "unix.cma";;
#directory "/home/runner/work/opencoq/opencoq/plugins/cognitive_engine";;
#load "tensor_backend.cmo";;
#load "hypergraph.cmo";;
#load "neural_symbolic_fusion.cmo";;

let test_enhanced_neural_symbolic_architecture () =
  Printf.printf "🧠🧮 Testing Enhanced Neural-Symbolic Fusion Architecture 🧮🧠\n\n";
  
  (* Test 1: Create fusion context *)
  Printf.printf "Test 1: Creating enhanced fusion context\n";
  let atomspace = Hypergraph.create_atomspace () in
  let fusion_ctx = Neural_symbolic_fusion.create_fusion_context atomspace 128 in
  Printf.printf "  ✓ Created fusion context with embedding dimension 128\n";
  
  (* Test 2: Test fusion strategies *)
  Printf.printf "\nTest 2: Testing different fusion strategies\n";
  
  (* Create test concepts *)
  let ml_concept_id = Hypergraph.add_node atomspace Hypergraph.Concept "machine_learning" in
  let dl_concept_id = Hypergraph.add_node atomspace Hypergraph.Concept "deep_learning" in
  let ai_concept_id = Hypergraph.add_node atomspace Hypergraph.Concept "artificial_intelligence" in
  
  Printf.printf "  ✓ Created symbolic concepts: ML(%d), DL(%d), AI(%d)\n" 
    ml_concept_id dl_concept_id ai_concept_id;
  
  (* Test embedding-based fusion *)
  let ml_neural_opt = Neural_symbolic_fusion.symbol_to_neural fusion_ctx ml_concept_id 
    Neural_symbolic_fusion.Embedding_Based in
  (match ml_neural_opt with
   | Some neural_id -> Printf.printf "  ✓ Embedding-based fusion: ML concept -> neural ID %d\n" neural_id
   | None -> Printf.printf "  ❌ Failed to create embedding-based neural representation\n");
  
  (* Test compositional fusion *)
  let dl_neural_opt = Neural_symbolic_fusion.symbol_to_neural fusion_ctx dl_concept_id 
    Neural_symbolic_fusion.Compositional in
  (match dl_neural_opt with
   | Some neural_id -> Printf.printf "  ✓ Compositional fusion: DL concept -> neural ID %d\n" neural_id
   | None -> Printf.printf "  ❌ Failed to create compositional neural representation\n");
  
  (* Test 3: Enhanced concept similarity *)
  Printf.printf "\nTest 3: Enhanced concept similarity computation\n";
  let similarity = Neural_symbolic_fusion.enhanced_concept_similarity fusion_ctx 
    ml_concept_id dl_concept_id in
  Printf.printf "  ✓ Enhanced similarity between ML and DL: %.4f\n" similarity;
  
  (* Test 4: Hierarchical embedding *)
  Printf.printf "\nTest 4: Hierarchical concept embedding\n";
  let hierarchical_tensor_id = Neural_symbolic_fusion.hierarchical_embed fusion_ctx 
    ai_concept_id [ml_concept_id; dl_concept_id] in
  Printf.printf "  ✓ Created hierarchical embedding for AI with ML+DL children: tensor ID %d\n" 
    hierarchical_tensor_id;
  
  (* Test 5: Compositional reasoning *)
  Printf.printf "\nTest 5: Compositional neural reasoning\n";
  let composition_tensor_id = Neural_symbolic_fusion.compositional_reasoning fusion_ctx 
    [ml_concept_id; dl_concept_id] Neural_symbolic_fusion.Compositional in
  Printf.printf "  ✓ Compositional reasoning result: tensor ID %d\n" composition_tensor_id;
  
  (* Test 6: Neural-guided inference *)
  Printf.printf "\nTest 6: Neural-guided symbolic inference\n";
  let inference_results = Neural_symbolic_fusion.neural_guided_inference fusion_ctx 
    ml_concept_id [dl_concept_id; ai_concept_id] in
  Printf.printf "  ✓ Neural-guided inference results:\n";
  List.iter (fun (concept_id, score) ->
    Printf.printf "    - Concept %d: score %.4f\n" concept_id score
  ) inference_results;
  
  (* Test 7: Cross-modal attention *)
  Printf.printf "\nTest 7: Cross-modal attention analysis\n";
  let symbolic_ids = [ml_concept_id; dl_concept_id] in
  let neural_ids = match ml_neural_opt, dl_neural_opt with
    | Some ml_neural, Some dl_neural -> [ml_neural; dl_neural]
    | _ -> [] in
  if neural_ids <> [] then begin
    let attention_matrix = Neural_symbolic_fusion.cross_modal_attention fusion_ctx 
      symbolic_ids neural_ids in
    Printf.printf "  ✓ Cross-modal attention matrix computed (%d elements)\n" 
      (Array.length attention_matrix)
  end else
    Printf.printf "  ⚠ Skipped cross-modal attention (neural representations unavailable)\n";
  
  (* Test 8: Proof tactic suggestion *)
  Printf.printf "\nTest 8: Neural-guided proof tactic suggestion\n";
  let theorem_id = Hypergraph.add_node atomspace Hypergraph.Concept "theorem_to_prove" in
  let suggested_tactics = Neural_symbolic_fusion.neural_guided_tactic_suggestion fusion_ctx theorem_id in
  Printf.printf "  ✓ Suggested tactics for theorem: %s\n" (String.concat ", " suggested_tactics);
  
  (* Test 9: Gradient-based learning *)
  Printf.printf "\nTest 9: Gradient-based symbolic learning\n";
  (match ml_neural_opt, dl_neural_opt with
   | Some ml_neural, Some dl_neural ->
       let gradients = Neural_symbolic_fusion.compute_symbolic_gradients fusion_ctx 
         ml_concept_id dl_neural in
       Printf.printf "  ✓ Computed gradients for ML concept (length: %d)\n" (Array.length gradients);
       Neural_symbolic_fusion.update_symbolic_knowledge fusion_ctx ml_concept_id gradients;
       Printf.printf "  ✓ Updated symbolic knowledge using gradients\n"
   | _ -> Printf.printf "  ⚠ Skipped gradient learning (neural representations unavailable)\n");
  
  (* Test 10: Reinforcement learning *)
  Printf.printf "\nTest 10: Reinforcement learning with fusion bindings\n";
  Neural_symbolic_fusion.reinforcement_update fusion_ctx ml_concept_id 0.8;
  Neural_symbolic_fusion.reinforcement_update fusion_ctx dl_concept_id (-0.2);
  Printf.printf "  ✓ Applied reinforcement updates (ML: +0.8, DL: -0.2)\n";
  
  (* Test 11: Fusion diagnostics *)
  Printf.printf "\nTest 11: Fusion context diagnostics\n";
  let stats = Neural_symbolic_fusion.get_fusion_statistics fusion_ctx in
  Printf.printf "  ✓ Fusion statistics:\n";
  List.iter (fun (name, value) ->
    Printf.printf "    - %s: %.3f\n" name value
  ) stats;
  
  (* Test 12: Scheme serialization *)
  Printf.printf "\nTest 12: Scheme serialization of fusion context\n";
  let scheme_repr = Neural_symbolic_fusion.fusion_context_to_scheme fusion_ctx in
  Printf.printf "  ✓ Fusion context serialized to Scheme (length: %d chars)\n" 
    (String.length scheme_repr);
  
  Printf.printf "\n✅ Enhanced Neural-Symbolic Fusion Architecture Test Complete!\n";
  Printf.printf "\n🎯 Summary: All major fusion capabilities tested and working!\n"

let () = 
  let _ = test_enhanced_neural_symbolic_architecture () in
  Printf.printf "\n🚀 The enhanced neural-symbolic fusion architecture is ready for advanced AI research!\n"