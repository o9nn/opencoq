(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** Main Cognitive Engine - Integration Module Implementation *)

(** Cognitive engine state *)
type cognitive_engine = {
  atomspace : Hypergraph.atomspace;
  task_queue : Task_system.task_queue;
  ecan_system : Attention_system.ecan_system;
  reasoning_engine : Reasoning_engine.reasoning_engine;
  metacognitive_system : Metacognition.metacognitive_system;
  mutable cycle_count : int;
  mutable running : bool;
}

(** Cognitive engine configuration *)
type engine_config = {
  max_concurrent_tasks : int;
  ecan_config : Attention_system.ecan_config;
  reasoning_enabled : bool;
  metacognition_enabled : bool;
  cycle_frequency : float;
}

(** Default engine configuration *)
let default_engine_config = {
  max_concurrent_tasks = 4;
  ecan_config = Attention_system.default_ecan_config;
  reasoning_enabled = true;
  metacognition_enabled = true;
  cycle_frequency = 1.0;
}

(** Create cognitive engine *)
let create_cognitive_engine config =
  let atomspace = Hypergraph.create_atomspace () in
  let task_queue = Task_system.create_task_queue config.max_concurrent_tasks in
  let ecan_system = Attention_system.create_ecan_system atomspace config.ecan_config in
  let reasoning_engine = Reasoning_engine.create_reasoning_engine atomspace in
  let metacognitive_system = Metacognition.create_metacognitive_system reasoning_engine ecan_system task_queue in
  
  {
    atomspace = atomspace;
    task_queue = task_queue;
    ecan_system = ecan_system;
    reasoning_engine = reasoning_engine;
    metacognitive_system = metacognitive_system;
    cycle_count = 0;
    running = false;
  }

(** Core engine operations *)
let single_cognitive_cycle engine =
  (* 1. Process attention allocation *)
  Attention_system.ecan_cycle engine.ecan_system;
  
  (* 2. Execute pending tasks *)
  Task_system.process_queue engine.task_queue 1;
  
  (* 3. Perform reasoning if enabled *)
  let _ = Reasoning_engine.forward_chaining engine.reasoning_engine 5 in
  
  (* 4. Meta-cognitive introspection *)
  let introspection = Metacognition.comprehensive_self_assessment engine.metacognitive_system in
  engine.metacognitive_system.introspection_history <- 
    introspection @ engine.metacognitive_system.introspection_history;
  
  (* 5. Self-modification based on introspection *)
  let modifications = Metacognition.plan_self_modification engine.metacognitive_system introspection in
  List.iter (fun mod_ -> 
    Metacognition.execute_self_modification engine.metacognitive_system mod_ |> ignore
  ) modifications;
  
  engine.cycle_count <- engine.cycle_count + 1

let start_engine engine =
  engine.running <- true

let stop_engine engine =
  engine.running <- false

let run_for_cycles engine max_cycles =
  start_engine engine;
  for i = 1 to max_cycles do
    if engine.running then
      single_cognitive_cycle engine
  done

(** High-level cognitive operations *)
let learn_pattern engine pattern_name node_ids =
  (* Create a pattern node and link it to constituent nodes *)
  let pattern_node_id = Hypergraph.add_node engine.atomspace Hypergraph.Concept pattern_name in
  
  List.iter (fun node_id ->
    let link_id = Hypergraph.add_link engine.atomspace Hypergraph.Inheritance [node_id; pattern_node_id] in
    (* Stimulate attention for pattern discovery *)
    Attention_system.stimulate_atom engine.ecan_system pattern_node_id 10.0
  ) node_ids

let reason_about engine target_node =
  let connected_links = 
    Hypergraph.get_incoming_links engine.atomspace target_node @
    Hypergraph.get_outgoing_links engine.atomspace target_node in
  
  if connected_links <> [] then
    Reasoning_engine.focus_reasoning engine.reasoning_engine [target_node]
  else
    []

let focus_attention_on engine node_ids =
  List.iter (fun node_id ->
    Attention_system.stimulate_atom engine.ecan_system node_id 20.0
  ) node_ids

let set_cognitive_goal engine goal =
  let current_goals = engine.metacognitive_system.self_model.current_goals in
  Metacognition.set_cognitive_goals engine.metacognitive_system (goal :: current_goals)

(** Knowledge integration *)
let add_knowledge engine concept_name description =
  let concept_id = Hypergraph.add_node engine.atomspace Hypergraph.Concept concept_name in
  let desc_id = Hypergraph.add_node engine.atomspace Hypergraph.Concept description in
  let link_id = Hypergraph.add_link engine.atomspace Hypergraph.Evaluation [concept_id; desc_id] in
  concept_id

let create_association engine node1_id node2_id link_type =
  Hypergraph.add_link engine.atomspace link_type [node1_id; node2_id]

let query_knowledge engine query =
  Hypergraph.find_nodes_by_name engine.atomspace query

(** Cognitive development *)
let bootstrap_basic_knowledge engine =
  (* Add fundamental concepts *)
  let self_id = add_knowledge engine "self" "cognitive system" in
  let knowledge_id = add_knowledge engine "knowledge" "information representation" in
  let learning_id = add_knowledge engine "learning" "knowledge acquisition" in
  let reasoning_id = add_knowledge engine "reasoning" "logical inference" in
  
  (* Create basic associations *)
  let _ = create_association engine self_id knowledge_id Hypergraph.Inheritance in
  let _ = create_association engine self_id learning_id Hypergraph.Execution in
  let _ = create_association engine self_id reasoning_id Hypergraph.Execution in
  
  (* Set initial attention *)
  focus_attention_on engine [self_id; knowledge_id; learning_id; reasoning_id]

let self_improve engine iterations =
  Metacognition.recursive_self_improvement engine.metacognitive_system iterations

let adapt_to_feedback engine feedback_text sentiment =
  (* Simple feedback adaptation - in practice would be more sophisticated *)
  if sentiment > 0.5 then
    (* Positive feedback - reinforce current strategies *)
    Metacognition.learn_from_experience engine.metacognitive_system
  else
    (* Negative feedback - trigger adaptation *)
    Metacognition.adapt_to_environment engine.metacognitive_system

(** Monitoring and diagnostics *)
let get_engine_status engine =
  let (available_sti, available_lti, num_nodes, num_focused) = 
    Attention_system.get_attention_statistics engine.ecan_system in
  (engine.running, engine.cycle_count, available_sti, available_lti, num_nodes)

let get_cognitive_statistics engine =
  let (running, cycles, sti, lti, nodes) = get_engine_status engine in
  let (pending, running_tasks, completed, failed) = Task_system.get_task_statistics engine.task_queue in
  let (introspections, modifications, confidence, learning_rate) = 
    Metacognition.get_metacognitive_statistics engine.metacognitive_system in
  
  Printf.sprintf "Cognitive Engine Statistics:\n" ^
  Printf.sprintf "  Running: %b, Cycles: %d\n" running cycles ^
  Printf.sprintf "  Attention: STI=%.1f, LTI=%.1f, Nodes=%d\n" sti lti nodes ^
  Printf.sprintf "  Tasks: Pending=%d, Running=%d, Completed=%d, Failed=%d\n" pending running_tasks completed failed ^
  Printf.sprintf "  Meta-cognition: Introspections=%d, Modifications=%d\n" introspections modifications ^
  Printf.sprintf "  Self-model: Confidence=%.2f, Learning=%.3f\n" confidence learning_rate

let export_cognitive_state engine =
  Printf.sprintf "(cognitive-state\n  %s\n  %s\n  %s\n  %s\n  %s)"
    (Hypergraph.atomspace_to_scheme engine.atomspace)
    (Task_system.task_queue_to_scheme engine.task_queue)
    (Attention_system.ecan_system_to_scheme engine.ecan_system)
    (Reasoning_engine.reasoning_engine_to_scheme engine.reasoning_engine)
    (Metacognition.metacognitive_system_to_scheme engine.metacognitive_system)

let import_cognitive_state engine state_str =
  (* Stub: Would parse Scheme representation and restore state *)
  true

(** Scheme integration *)
let execute_scheme_command engine command =
  (* Stub: Would parse and execute Scheme commands *)
  match command with
  | "status" -> get_cognitive_statistics engine
  | "export" -> export_cognitive_state engine
  | _ -> Printf.sprintf "Unknown command: %s" command

let cognitive_engine_to_scheme engine =
  Printf.sprintf "(cognitive-engine (cycles %d) (running %b) %s)"
    engine.cycle_count
    engine.running
    (export_cognitive_state engine)

(** Interactive interface *)
let process_natural_language engine input =
  (* Stub: Would parse natural language and convert to cognitive operations *)
  let words = String.split_on_char ' ' input in
  match words with
  | "learn" :: rest ->
      let pattern_name = String.concat " " rest in
      let pattern_id = add_knowledge engine pattern_name "learned pattern" in
      Printf.sprintf "Learned pattern '%s' with ID %d" pattern_name pattern_id
  | "reason" :: "about" :: rest ->
      let concept = String.concat " " rest in
      let node_ids = query_knowledge engine concept in
      let results = List.fold_left (fun acc node_id ->
        (reason_about engine node_id) @ acc
      ) [] node_ids in
      Printf.sprintf "Found %d reasoning results about '%s'" (List.length results) concept
  | "focus" :: "on" :: rest ->
      let concept = String.concat " " rest in
      let node_ids = query_knowledge engine concept in
      focus_attention_on engine node_ids;
      Printf.sprintf "Focused attention on '%s'" concept
  | _ ->
      Printf.sprintf "Processed: %s" input

let answer_question engine question =
  (* Stub: Would use reasoning to answer questions *)
  let words = String.split_on_char ' ' question in
  match words with
  | "what" :: "is" :: rest ->
      let concept = String.concat " " rest in
      let node_ids = query_knowledge engine concept in
      if node_ids <> [] then
        Printf.sprintf "'%s' is a concept in the knowledge base with %d associations" 
          concept (List.length node_ids)
      else
        Printf.sprintf "I don't know about '%s'" concept
  | "how" :: "many" :: rest ->
      let concept = String.concat " " rest in
      let node_ids = query_knowledge engine concept in
      Printf.sprintf "There are %d instances of '%s'" (List.length node_ids) concept
  | _ ->
      Printf.sprintf "I need more context to answer: %s" question

let explain_reasoning engine node_id =
  let results = reason_about engine node_id in
  let explanations = List.map (fun result ->
    Printf.sprintf "Applied %s rule to conclude link %d with confidence %.2f"
      (Reasoning_engine.pln_rule_to_scheme result.applied_rule)
      result.conclusion_link
      result.confidence
  ) results in
  
  if explanations = [] then
    "No reasoning paths found for this node"
  else
    "Reasoning explanation:\n" ^ String.concat "\n" explanations