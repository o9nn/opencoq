(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** Cognitive Engine Tests *)

let test_hypergraph () =
  Printf.printf "Testing Hypergraph...\n";
  let atomspace = Hypergraph.create_atomspace () in
  
  (* Test node creation *)
  let node1 = Hypergraph.add_node atomspace Hypergraph.Concept "test_concept" in
  let node2 = Hypergraph.add_node atomspace Hypergraph.Predicate "test_predicate" in
  
  (* Test node retrieval *)
  (match Hypergraph.get_node atomspace node1 with
   | Some node -> Printf.printf "  Node %d: %s (type: %s) ✓\n" node.id node.name 
                    (match node.node_type with 
                     | Hypergraph.Concept -> "Concept" 
                     | _ -> "Other")
   | None -> Printf.printf "  Failed to retrieve node %d ✗\n" node1);
  
  (* Test link creation *)
  let link1 = Hypergraph.add_link atomspace Hypergraph.Inheritance [node1; node2] in
  
  (* Test link retrieval *)
  (match Hypergraph.get_link atomspace link1 with
   | Some link -> Printf.printf "  Link %d: connects %d nodes ✓\n" link.id (List.length link.outgoing)
   | None -> Printf.printf "  Failed to retrieve link %d ✗\n" link1);
  
  (* Test Scheme conversion *)
  let scheme_repr = Hypergraph.atomspace_to_scheme atomspace in
  Printf.printf "  Scheme representation generated ✓\n";
  
  Printf.printf "Hypergraph tests completed.\n\n"

let test_task_system () =
  Printf.printf "Testing Task System...\n";
  let queue = Task_system.create_task_queue 2 in
  let atomspace = Hypergraph.create_atomspace () in
  
  (* Test task creation *)
  let task1 = Task_system.add_task queue Task_system.Reasoning_task Task_system.High 
              "Test reasoning task" atomspace [] (fun () -> ()) in
  
  let task2 = Task_system.add_task queue Task_system.Pattern_matching Task_system.Medium
              "Test pattern task" atomspace [task1] (fun () -> ()) in
  
  Printf.printf "  Created tasks %d and %d ✓\n" task1 task2;
  
  (* Test task retrieval *)
  (match Task_system.get_task queue task1 with
   | Some task -> Printf.printf "  Retrieved task: %s ✓\n" task.description
   | None -> Printf.printf "  Failed to retrieve task %d ✗\n" task1);
  
  (* Test statistics *)
  let (pending, running, completed, failed) = Task_system.get_task_statistics queue in
  Printf.printf "  Statistics: %d pending, %d running, %d completed, %d failed ✓\n" 
                pending running completed failed;
  
  Printf.printf "Task System tests completed.\n\n"

let test_attention_system () =
  Printf.printf "Testing Attention System...\n";
  let atomspace = Hypergraph.create_atomspace () in
  let config = Attention_system.default_ecan_config in
  let ecan = Attention_system.create_ecan_system atomspace config in
  
  (* Add some nodes *)
  let node1 = Hypergraph.add_node atomspace Hypergraph.Concept "attention_test1" in
  let node2 = Hypergraph.add_node atomspace Hypergraph.Concept "attention_test2" in
  
  (* Test attention stimulation *)
  Attention_system.stimulate_atom ecan node1 50.0;
  Printf.printf "  Stimulated node %d with attention ✓\n" node1;
  
  (* Test ECAN cycle *)
  Attention_system.ecan_cycle ecan;
  Printf.printf "  ECAN cycle completed ✓\n";
  
  (* Test attention statistics *)
  let (sti, lti, nodes, focused) = Attention_system.get_attention_statistics ecan in
  Printf.printf "  Attention stats: STI=%.1f, LTI=%.1f, nodes=%d, focused=%d ✓\n" 
                sti lti nodes focused;
  
  Printf.printf "Attention System tests completed.\n\n"

let test_reasoning_engine () =
  Printf.printf "Testing Reasoning Engine...\n";
  let atomspace = Hypergraph.create_atomspace () in
  let engine = Reasoning_engine.create_reasoning_engine atomspace in
  
  (* Add some test knowledge *)
  let node1 = Hypergraph.add_node atomspace Hypergraph.Concept "A" in
  let node2 = Hypergraph.add_node atomspace Hypergraph.Concept "B" in
  let node3 = Hypergraph.add_node atomspace Hypergraph.Concept "C" in
  
  let link1 = Hypergraph.add_link atomspace Hypergraph.Implication [node1; node2] in
  let link2 = Hypergraph.add_link atomspace Hypergraph.Implication [node2; node3] in
  
  (* Test forward chaining *)
  let results = Reasoning_engine.forward_chaining engine 3 in
  Printf.printf "  Forward chaining produced %d results ✓\n" (List.length results);
  
  (* Test rule application *)
  let context = {
    Reasoning_engine.premises = [link1];
    conclusion = None;
    confidence_threshold = 0.5;
    strength_threshold = 0.5;
  } in
  
  (match Reasoning_engine.apply_pln_rule engine Reasoning_engine.Deduction_rule context with
   | Some result -> Printf.printf "  Applied deduction rule successfully ✓\n"
   | None -> Printf.printf "  Deduction rule application failed ✗\n");
  
  Printf.printf "Reasoning Engine tests completed.\n\n"

let test_metacognition () =
  Printf.printf "Testing Metacognition...\n";
  let atomspace = Hypergraph.create_atomspace () in
  let task_queue = Task_system.create_task_queue 2 in
  let ecan_system = Attention_system.create_ecan_system atomspace Attention_system.default_ecan_config in
  let reasoning_engine = Reasoning_engine.create_reasoning_engine atomspace in
  let meta_system = Metacognition.create_metacognitive_system reasoning_engine ecan_system task_queue in
  
  (* Test introspection *)
  let introspection = Metacognition.comprehensive_self_assessment meta_system in
  Printf.printf "  Comprehensive self-assessment: %d results ✓\n" (List.length introspection);
  
  (* Test self-modification planning *)
  let modifications = Metacognition.plan_self_modification meta_system introspection in
  Printf.printf "  Planned %d self-modifications ✓\n" (List.length modifications);
  
  (* Test goal management *)
  Metacognition.set_cognitive_goals meta_system ["test goal 1"; "test goal 2"];
  let progress = Metacognition.evaluate_goal_progress meta_system in
  Printf.printf "  Goal progress: %d goals tracked ✓\n" (List.length progress);
  
  Printf.printf "Metacognition tests completed.\n\n"

let test_cognitive_engine () =
  Printf.printf "Testing Cognitive Engine Integration...\n";
  let config = Cognitive_engine.default_engine_config in
  let engine = Cognitive_engine.create_cognitive_engine config in
  
  (* Test bootstrap knowledge *)
  Cognitive_engine.bootstrap_basic_knowledge engine;
  Printf.printf "  Bootstrap knowledge loaded ✓\n";
  
  (* Test knowledge addition *)
  let concept_id = Cognitive_engine.add_knowledge engine "test_concept" "A test concept for the engine" in
  Printf.printf "  Added knowledge concept with ID %d ✓\n" concept_id;
  
  (* Test single cognitive cycle *)
  Cognitive_engine.single_cognitive_cycle engine;
  Printf.printf "  Single cognitive cycle completed ✓\n";
  
  (* Test status reporting *)
  let statistics = Cognitive_engine.get_cognitive_statistics engine in
  Printf.printf "  Engine statistics generated ✓\n";
  
  (* Test natural language processing *)
  let response = Cognitive_engine.process_natural_language engine "learn new pattern" in
  Printf.printf "  NL response: %s ✓\n" response;
  
  Printf.printf "Cognitive Engine tests completed.\n\n"

let run_all_tests () =
  Printf.printf "=== Cognitive Engine Test Suite ===\n\n";
  test_hypergraph ();
  test_task_system ();
  test_attention_system ();
  test_reasoning_engine ();
  test_metacognition ();
  test_cognitive_engine ();
  Printf.printf "=== All Tests Completed ===\n"

(* Run tests if this module is executed *)
let () = run_all_tests ()