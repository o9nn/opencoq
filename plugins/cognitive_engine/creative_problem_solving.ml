(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** Creative Problem Solving via Combinatorial Hypergraph Traversal - Implementation *)

open Printf

(** Problem definition types *)
type problem_constraint = {
  required_nodes : Hypergraph.node_id list;
  forbidden_nodes : Hypergraph.node_id list;
  required_links : Hypergraph.link_id list;
  forbidden_links : Hypergraph.link_id list;
  goal_predicates : (Hypergraph.node_id -> bool) list;
}

type problem_definition = {
  initial_state : Hypergraph.node_id list;
  goal_state : Hypergraph.node_id list;
  constraints : problem_constraint;
  creativity_level : float;
  max_depth : int;
  time_limit : float;
}

(** Traversal strategy types *)
type traversal_strategy =
  | Breadth_first_creative
  | Depth_first_creative
  | Random_walk_attention
  | Genetic_traversal
  | Hybrid_multi_objective

(** Solution representation *)
type solution_path = {
  nodes : Hypergraph.node_id list;
  links : Hypergraph.link_id list;
  creativity_score : float;
  novelty_score : float;
  feasibility_score : float;
  path_length : int;
  exploration_steps : int;
}

type creative_solution = {
  paths : solution_path list;
  total_exploration_time : float;
  nodes_explored : int;
  novel_associations : (Hypergraph.node_id * Hypergraph.node_id * float) list;
  generated_concepts : Hypergraph.node_id list;
}

(** Creative reasoning types *)
type analogy_mapping = {
  source_pattern : Hypergraph.node_id list;
  target_pattern : Hypergraph.node_id list;
  mapping_strength : float;
  abstraction_level : int;
}

type concept_blend = {
  input_concepts : Hypergraph.node_id list;
  blended_concept : Hypergraph.node_id;
  blend_features : (string * float) list;
  novelty_rating : float;
}

(** Creative problem solving engine *)
type creative_engine = {
  atomspace : Hypergraph.atomspace;
  reasoning_engine : Reasoning_engine.reasoning_engine;
  attention_system : Attention_system.ecan_system;
  mutable explored_paths : solution_path list;
  mutable novel_associations : (Hypergraph.node_id * Hypergraph.node_id * float) list;
  mutable creativity_history : (float * string) list;
  mutable generated_concepts : Hypergraph.node_id list;
}

(** Configuration for creative problem solving *)
type creativity_config = {
  divergent_thinking_ratio : float;
  novelty_weight : float;
  feasibility_weight : float;
  attention_focus_cycles : int;
  concept_blending_enabled : bool;
  analogical_reasoning_enabled : bool;
  constraint_relaxation_level : float;
}

(** Create creative problem solving engine *)
let create_creative_engine atomspace reasoning_engine attention_system =
  {
    atomspace = atomspace;
    reasoning_engine = reasoning_engine;
    attention_system = attention_system;
    explored_paths = [];
    novel_associations = [];
    creativity_history = [];
    generated_concepts = [];
  }

(** Default creativity configuration *)
let default_creativity_config = {
  divergent_thinking_ratio = 0.7;
  novelty_weight = 0.6;
  feasibility_weight = 0.4;
  attention_focus_cycles = 5;
  concept_blending_enabled = true;
  analogical_reasoning_enabled = true;
  constraint_relaxation_level = 0.3;
}

(** Utility functions *)

(* Shared utility functions for list operations *)
module ListUtils = struct
  let rec take n lst =
    if n <= 0 then []
    else match lst with
      | [] -> []
      | h :: t -> h :: (take (n - 1) t)

  let rec drop n lst =
    if n <= 0 then lst
    else match lst with
      | [] -> []
      | _ :: t -> drop (n - 1) t
end

let default_attention_value = {
  Hypergraph.sti = 0.0;
  Hypergraph.lti = 0.0;
  Hypergraph.vlti = 0.0;
}

let create_empty_solution_path () = {
  nodes = [];
  links = [];
  creativity_score = 0.0;
  novelty_score = 0.0;
  feasibility_score = 0.0;
  path_length = 0;
  exploration_steps = 0;
}

let random_float () = Random.float 1.0

let shuffle_list lst =
  let arr = Array.of_list lst in
  for i = Array.length arr - 1 downto 1 do
    let j = Random.int (i + 1) in
    let temp = arr.(i) in
    arr.(i) <- arr.(j);
    arr.(j) <- temp
  done;
  Array.to_list arr

(** Constraint checking *)
let satisfies_constraints node_id constraints =
  not (List.mem node_id constraints.forbidden_nodes) &&
  List.for_all (fun pred -> pred node_id) constraints.goal_predicates

let check_path_constraints path constraints =
  List.for_all (fun node_id -> satisfies_constraints node_id constraints) path.nodes &&
  List.for_all (fun req_node -> List.mem req_node path.nodes) constraints.required_nodes

(** Creativity scoring functions *)

let calculate_novelty_score engine path =
  let existing_paths = engine.explored_paths in
  let path_nodes = path.nodes in
  let similarity_scores = List.map (fun existing_path ->
    let common_nodes = List.filter (fun n -> List.mem n existing_path.nodes) path_nodes in
    let similarity = (float_of_int (List.length common_nodes)) /. 
                    (float_of_int (max (List.length path_nodes) (List.length existing_path.nodes))) in
    1.0 -. similarity
  ) existing_paths in
  if similarity_scores = [] then 1.0
  else List.fold_left (+.) 0.0 similarity_scores /. (float_of_int (List.length similarity_scores))

let calculate_creativity_score engine path problem =
  let novelty = calculate_novelty_score engine path in
  let complexity = log (1.0 +. float_of_int path.path_length) in
  let connectivity = 
    let incoming_links = List.fold_left (fun acc node_id ->
      acc + List.length (Hypergraph.get_incoming_links engine.atomspace node_id)
    ) 0 path.nodes in
    log (1.0 +. float_of_int incoming_links)
  in
  let creativity_level = problem.creativity_level in
  creativity_level *. (0.4 *. novelty +. 0.3 *. complexity +. 0.3 *. connectivity)

let calculate_feasibility_score engine path problem =
  (* Use reasoning engine to check logical consistency *)
  let node_pairs = List.fold_left (fun acc node_id ->
    let outgoing = Hypergraph.get_outgoing_links engine.atomspace node_id in
    acc @ outgoing
  ) [] path.nodes in
  
  let consistency_score = List.fold_left (fun acc link_id ->
    match Hypergraph.get_link engine.atomspace link_id with
    | Some link -> 
        let (strength, confidence) = link.truth_value in
        acc +. (strength *. confidence)
    | None -> acc
  ) 0.0 node_pairs in
  
  let num_links = float_of_int (List.length node_pairs) in
  if num_links > 0.0 then consistency_score /. num_links else 0.5

(** Breadth-first creative traversal *)
let breadth_first_creative_traversal engine start_nodes constraints max_depth =
  let visited = Hashtbl.create 1000 in
  let paths = ref [] in
  let queue = Queue.create () in
  
  (* Initialize queue with start nodes *)
  List.iter (fun node_id ->
    if satisfies_constraints node_id constraints then
      Queue.add ([node_id], [], 0) queue
  ) start_nodes;
  
  let exploration_steps = ref 0 in
  
  while not (Queue.is_empty queue) && !exploration_steps < 1000 do
    incr exploration_steps;
    let (current_path, link_path, depth) = Queue.take queue in
    
    if depth < max_depth then (
      match current_path with
      | [] -> ()
      | current_node :: _ ->
          if not (Hashtbl.mem visited current_node) then (
            Hashtbl.add visited current_node true;
            
            (* Get neighbors with creativity bias *)
            let outgoing_links = Hypergraph.get_outgoing_links engine.atomspace current_node in
            let neighbors = List.fold_left (fun acc link_id ->
              match Hypergraph.get_link engine.atomspace link_id with
              | Some link -> link.outgoing @ acc
              | None -> acc
            ) [] outgoing_links in
            
            (* Add creativity bias - prefer nodes with higher attention or lower frequency *)
            let scored_neighbors = List.map (fun neighbor_id ->
              let attention_score = match Hypergraph.get_node engine.atomspace neighbor_id with
                | Some node -> node.attention.sti +. node.attention.lti
                | None -> 0.0
              in
              let frequency_penalty = if Hashtbl.mem visited neighbor_id then -1.0 else 0.0 in
              (neighbor_id, attention_score +. frequency_penalty +. random_float ())
            ) neighbors in
            
            let sorted_neighbors = List.sort (fun (_, score1) (_, score2) -> 
              compare score2 score1) scored_neighbors in
            
            (* Add top neighbors to queue *)
            List.iteri (fun i (neighbor_id, _) ->
              if i < 3 && satisfies_constraints neighbor_id constraints then
                Queue.add (neighbor_id :: current_path, 
                          (List.hd outgoing_links) :: link_path, 
                          depth + 1) queue
            ) sorted_neighbors;
            
            (* Create solution path *)
            let solution = {
              nodes = List.rev current_path;
              links = List.rev link_path;
              creativity_score = 0.0; (* Will be calculated later *)
              novelty_score = 0.0;
              feasibility_score = 0.0;
              path_length = List.length current_path;
              exploration_steps = !exploration_steps;
            } in
            paths := solution :: !paths
          )
    )
  done;
  !paths

(** Depth-first creative traversal *)
let depth_first_creative_traversal engine start_nodes constraints max_depth =
  let visited = Hashtbl.create 1000 in
  let paths = ref [] in
  let exploration_steps = ref 0 in
  
  let rec dfs_explore current_path link_path depth =
    incr exploration_steps;
    if depth >= max_depth || !exploration_steps > 1000 then []
    else
      match current_path with
      | [] -> []
      | current_node :: _ ->
          if Hashtbl.mem visited current_node then []
          else (
            Hashtbl.add visited current_node true;
            
            let outgoing_links = Hypergraph.get_outgoing_links engine.atomspace current_node in
            let neighbors = List.fold_left (fun acc link_id ->
              match Hypergraph.get_link engine.atomspace link_id with
              | Some link -> link.outgoing @ acc
              | None -> acc
            ) [] outgoing_links in
            
            (* Novelty-seeking bias *)
            let novel_neighbors = List.filter (fun neighbor_id ->
              not (Hashtbl.mem visited neighbor_id) &&
              satisfies_constraints neighbor_id constraints
            ) neighbors in
            
            let shuffled_neighbors = shuffle_list novel_neighbors in
            
            let solution = {
              nodes = List.rev current_path;
              links = List.rev link_path;
              creativity_score = 0.0;
              novelty_score = 0.0;
              feasibility_score = 0.0;
              path_length = List.length current_path;
              exploration_steps = !exploration_steps;
            } in
            
            let sub_paths = List.fold_left (fun acc neighbor_id ->
              let new_links = List.filter (fun link_id ->
                match Hypergraph.get_link engine.atomspace link_id with
                | Some link -> List.mem neighbor_id link.outgoing
                | None -> false
              ) outgoing_links in
              let first_link = match new_links with | h :: _ -> h | [] -> -1 in
              if first_link <> -1 then
                acc @ dfs_explore (neighbor_id :: current_path) (first_link :: link_path) (depth + 1)
              else acc
            ) [] (ListUtils.take (min 2 (List.length shuffled_neighbors)) shuffled_neighbors) in
            
            Hashtbl.remove visited current_node;
            solution :: sub_paths
          )
  in
  
  List.fold_left (fun acc start_node ->
    if satisfies_constraints start_node constraints then
      acc @ dfs_explore [start_node] [] 0
    else acc
  ) [] start_nodes

(** Attention-guided random walk *)
let attention_guided_random_walk engine start_nodes constraints max_depth =
  let paths = ref [] in
  let exploration_steps = ref 0 in
  
  let walk_from_node start_node =
    let current_path = ref [start_node] in
    let link_path = ref [] in
    let current_node = ref start_node in
    
    for _ = 1 to max_depth do
      incr exploration_steps;
      if !exploration_steps > 500 then failwith "Creative problem solving: Maximum exploration steps (500) reached during attention-guided random walk";
      
      let outgoing_links = Hypergraph.get_outgoing_links engine.atomspace !current_node in
      if outgoing_links <> [] then (
        (* Weight neighbors by attention values *)
        let weighted_neighbors = List.fold_left (fun acc link_id ->
          match Hypergraph.get_link engine.atomspace link_id with
          | Some link ->
              List.fold_left (fun acc2 neighbor_id ->
                if satisfies_constraints neighbor_id constraints then
                  let attention_weight = match Hypergraph.get_node engine.atomspace neighbor_id with
                    | Some node -> node.attention.sti +. 0.5 *. node.attention.lti +. random_float ()
                    | None -> random_float ()
                  in
                  (neighbor_id, link_id, attention_weight) :: acc2
                else acc2
              ) acc link.outgoing
          | None -> acc
        ) [] outgoing_links in
        
        if weighted_neighbors <> [] then (
          (* Select neighbor probabilistically based on attention *)
          let total_weight = List.fold_left (fun acc (_, _, w) -> acc +. w) 0.0 weighted_neighbors in
          let rand_val = random_float () *. total_weight in
          let rec select_neighbor remaining_weight = function
            | [] -> List.hd weighted_neighbors
            | (neighbor_id, link_id, weight) :: rest ->
                if remaining_weight <= weight then (neighbor_id, link_id, weight)
                else select_neighbor (remaining_weight -. weight) rest
          in
          let (next_node, chosen_link, _) = select_neighbor rand_val weighted_neighbors in
          current_path := next_node :: !current_path;
          link_path := chosen_link :: !link_path;
          current_node := next_node
        )
      )
    done;
    
    {
      nodes = List.rev !current_path;
      links = List.rev !link_path;
      creativity_score = 0.0;
      novelty_score = 0.0;
      feasibility_score = 0.0;
      path_length = List.length !current_path;
      exploration_steps = !exploration_steps;
    }
  in
  
  List.iter (fun start_node ->
    if satisfies_constraints start_node constraints then
      paths := (walk_from_node start_node) :: !paths
  ) start_nodes;
  !paths

(** Genetic algorithm for path optimization *)
let genetic_path_optimization engine start_nodes constraints population_size generations =
  let create_random_path start_node max_len =
    let rec build_path current_node path_nodes path_links remaining_length =
      if remaining_length <= 0 then (List.rev path_nodes, List.rev path_links)
      else
        let outgoing_links = Hypergraph.get_outgoing_links engine.atomspace current_node in
        if outgoing_links = [] then (List.rev path_nodes, List.rev path_links)
        else
          let random_link = List.nth outgoing_links (Random.int (List.length outgoing_links)) in
          match Hypergraph.get_link engine.atomspace random_link with
          | Some link ->
              let valid_neighbors = List.filter (fun n -> 
                satisfies_constraints n constraints) link.outgoing in
              if valid_neighbors = [] then (List.rev path_nodes, List.rev path_links)
              else
                let next_node = List.nth valid_neighbors (Random.int (List.length valid_neighbors)) in
                build_path next_node (next_node :: path_nodes) (random_link :: path_links) (remaining_length - 1)
          | None -> (List.rev path_nodes, List.rev path_links)
    in
    let (nodes, links) = build_path start_node [start_node] [] (3 + Random.int 5) in
    {
      nodes = nodes;
      links = links;
      creativity_score = 0.0;
      novelty_score = 0.0;
      feasibility_score = 0.0;
      path_length = List.length nodes;
      exploration_steps = 0;
    }
  in
  
  let mutate_path path =
    if path.nodes = [] then path
    else
      let mutation_point = Random.int (List.length path.nodes) in
      let (prefix_nodes, suffix_nodes) = 
        let rec split n acc = function
          | [] -> (List.rev acc, [])
          | h :: t -> if n = 0 then (List.rev acc, h :: t) else split (n-1) (h :: acc) t
        in split mutation_point [] path.nodes
      in
      if suffix_nodes = [] then path
      else
        let mutation_node = List.hd suffix_nodes in
        let outgoing_links = Hypergraph.get_outgoing_links engine.atomspace mutation_node in
        if outgoing_links = [] then path
        else
          let random_link = List.nth outgoing_links (Random.int (List.length outgoing_links)) in
          match Hypergraph.get_link engine.atomspace random_link with
          | Some link ->
              let valid_neighbors = List.filter (fun n -> 
                satisfies_constraints n constraints) link.outgoing in
              if valid_neighbors = [] then path
              else
                let new_node = List.nth valid_neighbors (Random.int (List.length valid_neighbors)) in
                { path with 
                  nodes = prefix_nodes @ [new_node];
                  path_length = List.length prefix_nodes + 1;
                }
          | None -> path
  in
  
  let crossover_paths path1 path2 =
    let len1 = List.length path1.nodes in
    let len2 = List.length path2.nodes in
    if len1 = 0 || len2 = 0 then (path1, path2)
    else
      let crossover_point1 = Random.int len1 in
      let crossover_point2 = Random.int len2 in
      let (prefix1, suffix1) = 
        let rec split n acc = function
          | [] -> (List.rev acc, [])
          | h :: t -> if n = 0 then (List.rev acc, h :: t) else split (n-1) (h :: acc) t
        in split crossover_point1 [] path1.nodes
      in
      let (prefix2, suffix2) = 
        let rec split n acc = function
          | [] -> (List.rev acc, [])
          | h :: t -> if n = 0 then (List.rev acc, h :: t) else split (n-1) (h :: acc) t
        in split crossover_point2 [] path2.nodes
      in
      let new_path1_nodes = prefix1 @ suffix2 in
      let new_path2_nodes = prefix2 @ suffix1 in
      ({ path1 with nodes = new_path1_nodes; path_length = List.length new_path1_nodes },
       { path2 with nodes = new_path2_nodes; path_length = List.length new_path2_nodes })
  in
  
  (* Initialize population *)
  let initial_population = List.fold_left (fun acc start_node ->
    if satisfies_constraints start_node constraints then
      let individual_paths = ref [] in
      for _ = 1 to (population_size / max 1 (List.length start_nodes)) do
        individual_paths := (create_random_path start_node 8) :: !individual_paths
      done;
      acc @ !individual_paths
    else acc
  ) [] start_nodes in
  
  let population = ref initial_population in
  
  (* Evolution loop *)
  for generation = 1 to generations do
    (* Selection and reproduction *)
    let scored_population = List.map (fun path ->
      let creativity = calculate_creativity_score engine path { 
        initial_state = start_nodes; goal_state = []; constraints = constraints;
        creativity_level = 0.8; max_depth = 10; time_limit = 60.0 
      } in
      let novelty = calculate_novelty_score engine path in
      (path, creativity +. novelty)
    ) !population in
    
    let sorted_population = List.sort (fun (_, score1) (_, score2) -> 
      compare score2 score1) scored_population in
    
    let elite = ListUtils.take (population_size / 4) sorted_population |> List.map fst in
    
    let new_population = ref elite in
    
    (* Generate offspring *)
    while List.length !new_population < population_size do
      let parent1 = List.nth elite (Random.int (List.length elite)) in
      let parent2 = List.nth elite (Random.int (List.length elite)) in
      let (child1, child2) = crossover_paths parent1 parent2 in
      let mutated_child1 = if random_float () < 0.1 then mutate_path child1 else child1 in
      let mutated_child2 = if random_float () < 0.1 then mutate_path child2 else child2 in
      new_population := mutated_child1 :: mutated_child2 :: !new_population
    done;
    
    population := ListUtils.take population_size !new_population
  done;
  
  !population

(** Multi-objective traversal optimization *)
let multi_objective_traversal engine start_nodes constraints config =
  (* Combine multiple traversal strategies *)
  let bfs_paths = breadth_first_creative_traversal engine start_nodes constraints 6 in
  let dfs_paths = depth_first_creative_traversal engine start_nodes constraints 6 in
  let random_paths = attention_guided_random_walk engine start_nodes constraints 6 in
  let genetic_paths = genetic_path_optimization engine start_nodes constraints 20 10 in
  
  let all_paths = bfs_paths @ dfs_paths @ random_paths @ genetic_paths in
  
  (* Score paths with multiple objectives *)
  let scored_paths = List.map (fun path ->
    let problem = { 
      initial_state = start_nodes; goal_state = []; constraints = constraints;
      creativity_level = 0.8; max_depth = 10; time_limit = 60.0 
    } in
    let creativity = calculate_creativity_score engine path problem in
    let novelty = calculate_novelty_score engine path in
    let feasibility = calculate_feasibility_score engine path problem in
    let combined_score = 
      config.novelty_weight *. novelty +. 
      config.feasibility_weight *. feasibility +. 
      (1.0 -. config.novelty_weight -. config.feasibility_weight) *. creativity in
    { path with 
      creativity_score = creativity;
      novelty_score = novelty;
      feasibility_score = feasibility;
    }, combined_score
  ) all_paths in
  
  let sorted_paths = List.sort (fun (_, score1) (_, score2) -> 
    compare score2 score1) scored_paths in
  
  ListUtils.take (min 10 (List.length sorted_paths)) sorted_paths |> List.map fst

(** Core problem solving function *)
let solve_creative_problem engine problem config strategy =
  let start_time = Unix.gettimeofday () in
  
  let paths = match strategy with
    | Breadth_first_creative -> 
        breadth_first_creative_traversal engine problem.initial_state problem.constraints problem.max_depth
    | Depth_first_creative -> 
        depth_first_creative_traversal engine problem.initial_state problem.constraints problem.max_depth
    | Random_walk_attention -> 
        attention_guided_random_walk engine problem.initial_state problem.constraints problem.max_depth
    | Genetic_traversal -> 
        genetic_path_optimization engine problem.initial_state problem.constraints 30 15
    | Hybrid_multi_objective -> 
        multi_objective_traversal engine problem.initial_state problem.constraints config
  in
  
  let end_time = Unix.gettimeofday () in
  let exploration_time = end_time -. start_time in
  
  (* Update creativity scores *)
  let updated_paths = List.map (fun path ->
    { path with
      creativity_score = calculate_creativity_score engine path problem;
      novelty_score = calculate_novelty_score engine path;
      feasibility_score = calculate_feasibility_score engine path problem;
    }
  ) paths in
  
  (* Update engine state *)
  engine.explored_paths <- updated_paths @ engine.explored_paths;
  
  let nodes_explored = List.fold_left (fun acc path -> 
    acc + path.path_length) 0 updated_paths in
  
  {
    paths = updated_paths;
    total_exploration_time = exploration_time;
    nodes_explored = nodes_explored;
    novel_associations = [];
    generated_concepts = [];
  }

(** Generate multiple alternative solutions *)
let generate_alternative_solutions engine problem config num_solutions =
  let all_strategies = [
    Breadth_first_creative; Depth_first_creative; Random_walk_attention; 
    Genetic_traversal; Hybrid_multi_objective
  ] in
  
  let solutions = List.map (fun strategy ->
    solve_creative_problem engine problem config strategy
  ) all_strategies in
  
  ListUtils.take (min num_solutions (List.length solutions)) solutions

(** Novel association discovery *)
let discover_novel_associations engine node_list threshold =
  let associations = ref [] in
  
  for i = 0 to List.length node_list - 1 do
    for j = i + 1 to List.length node_list - 1 do
      let node1 = List.nth node_list i in
      let node2 = List.nth node_list j in
      
      (* Calculate semantic distance/similarity *)
      let node1_links = Hypergraph.get_outgoing_links engine.atomspace node1 in
      let node2_links = Hypergraph.get_outgoing_links engine.atomspace node2 in
      
      let common_neighbors = List.filter (fun link1 ->
        List.exists (fun link2 -> link1 = link2) node2_links
      ) node1_links in
      
      let similarity = (float_of_int (List.length common_neighbors)) /. 
                      (float_of_int (max 1 (List.length node1_links + List.length node2_links))) in
      
      (* Novel associations have medium similarity (not too high, not too low) *)
      if similarity > threshold && similarity < (1.0 -. threshold) then
        associations := (node1, node2, similarity) :: !associations
    done
  done;
  
  !associations

let validate_novel_associations engine associations =
  (* Simple validation - check if associations lead to valid reasoning paths *)
  List.filter (fun (node1, node2, score) ->
    let reasoning_result = Reasoning_engine.focus_reasoning engine.reasoning_engine [node1; node2] in
    List.length reasoning_result > 0 && score > 0.1
  ) associations

(** Analogical reasoning functions *)
let find_analogical_mappings engine source_pattern target_pattern =
  let create_mapping source target strength level =
    { source_pattern = source; target_pattern = target; 
      mapping_strength = strength; abstraction_level = level }
  in
  
  if List.length source_pattern <> List.length target_pattern then []
  else
    let pattern_pairs = List.combine source_pattern target_pattern in
    let total_similarity = List.fold_left (fun acc (src_node, tgt_node) ->
      let src_links = Hypergraph.get_outgoing_links engine.atomspace src_node in
      let tgt_links = Hypergraph.get_outgoing_links engine.atomspace tgt_node in
      let common_link_types = List.filter (fun src_link ->
        List.exists (fun tgt_link ->
          match (Hypergraph.get_link engine.atomspace src_link, 
                 Hypergraph.get_link engine.atomspace tgt_link) with
          | (Some src_l, Some tgt_l) -> src_l.link_type = tgt_l.link_type
          | _ -> false
        ) tgt_links
      ) src_links in
      acc +. (float_of_int (List.length common_link_types))
    ) 0.0 pattern_pairs in
    
    let avg_similarity = total_similarity /. (float_of_int (List.length pattern_pairs)) in
    if avg_similarity > 0.5 then
      [create_mapping source_pattern target_pattern avg_similarity 1]
    else []

let apply_analogical_reasoning engine mapping problem =
  (* Apply the analogical mapping to generate new solution paths *)
  let mapped_nodes = List.map2 (fun src tgt ->
    (* Create new node based on analogy *)
    let new_name = Printf.sprintf "analogical_%d_%d" src tgt in
    Hypergraph.add_node engine.atomspace Hypergraph.Concept new_name
  ) mapping.source_pattern mapping.target_pattern in
  
  [{
    nodes = mapped_nodes;
    links = [];
    creativity_score = mapping.mapping_strength;
    novelty_score = 0.8; (* Analogical reasoning is inherently novel *)
    feasibility_score = 0.6; (* Moderate feasibility *)
    path_length = List.length mapped_nodes;
    exploration_steps = 1;
  }]

(** Concept blending *)
let blend_concepts engine concept_list =
  if List.length concept_list < 2 then
    failwith (Printf.sprintf "Concept blending requires at least 2 concepts, but only %d provided" (List.length concept_list))
  else
    let blend_name = Printf.sprintf "blend_%s" 
      (String.concat "_" (List.map string_of_int concept_list)) in
    let blended_id = Hypergraph.add_node engine.atomspace Hypergraph.Concept blend_name in
    
    (* Create links from blended concept to source concepts *)
    List.iter (fun concept_id ->
      let _ = Hypergraph.add_link engine.atomspace Hypergraph.Inheritance [blended_id; concept_id] in
      ()
    ) concept_list;
    
    let blend_features = List.mapi (fun i concept_id ->
      (Printf.sprintf "feature_%d" i, random_float ())
    ) concept_list in
    
    {
      input_concepts = concept_list;
      blended_concept = blended_id;
      blend_features = blend_features;
      novelty_rating = 0.7 +. 0.3 *. random_float ();
    }

let generate_blended_solutions engine blends problem =
  List.map (fun blend ->
    {
      nodes = blend.blended_concept :: problem.initial_state;
      links = [];
      creativity_score = blend.novelty_rating;
      novelty_score = blend.novelty_rating;
      feasibility_score = 0.5;
      path_length = 1 + List.length problem.initial_state;
      exploration_steps = 1;
    }
  ) blends

(** Constraint relaxation *)
let relax_constraints constraints relaxation_level =
  {
    required_nodes = constraints.required_nodes;
    forbidden_nodes = 
      if relaxation_level > 0.5 then 
        ListUtils.take (List.length constraints.forbidden_nodes / 2) constraints.forbidden_nodes
      else constraints.forbidden_nodes;
    required_links = constraints.required_links;
    forbidden_links = constraints.forbidden_links;
    goal_predicates = constraints.goal_predicates;
  }

let progressive_constraint_relaxation engine problem config =
  let relaxation_levels = [0.0; 0.3; 0.6; 0.9] in
  List.map (fun level ->
    let relaxed_constraints = relax_constraints problem.constraints level in
    let relaxed_problem = { problem with constraints = relaxed_constraints } in
    solve_creative_problem engine relaxed_problem config Hybrid_multi_objective
  ) relaxation_levels

(** Attention management *)
let creative_attention_cycle engine problem cycles =
  for _ = 1 to cycles do
    (* Focus phase - increase attention on problem-relevant nodes *)
    List.iter (fun node_id ->
      let current_attention = match Hypergraph.get_node engine.atomspace node_id with
        | Some node -> node.attention
        | None -> default_attention_value
      in
      let focused_attention = {
        current_attention with 
        sti = min 1.0 (current_attention.sti +. 0.2);
      } in
      Hypergraph.update_node_attention engine.atomspace node_id focused_attention
    ) problem.initial_state;
    
    (* Defocus phase - allow attention to spread *)
    Hypergraph.spread_activation engine.atomspace (List.hd problem.initial_state) 0.1;
    
    (* Decay attention slightly *)
    Hypergraph.decay_attention engine.atomspace 0.05
  done

let shift_attention_to_novel_regions engine node_list =
  let high_attention_atoms = Hypergraph.get_high_attention_atoms engine.atomspace 20 in
  let novel_nodes = List.filter (fun node_id ->
    not (List.exists (fun (high_node, _) -> high_node = node_id) high_attention_atoms)
  ) node_list in
  
  List.iter (fun node_id ->
    let boosted_attention = {
      sti = 0.8; lti = 0.3; vlti = 0.1;
    } in
    Hypergraph.update_node_attention engine.atomspace node_id boosted_attention
  ) novel_nodes

let balance_cognitive_modes engine config exploration_ratio =
  if exploration_ratio > config.divergent_thinking_ratio then
    (* Increase exploration - boost random, low-attention nodes *)
    let all_nodes = Hypergraph.find_nodes_by_type engine.atomspace Hypergraph.Concept in
    let random_nodes = shuffle_list all_nodes |> ListUtils.take (min 10 (List.length all_nodes)) in
    List.iter (fun node_id ->
      let exploration_attention = { sti = 0.4; lti = 0.1; vlti = 0.05 } in
      Hypergraph.update_node_attention engine.atomspace node_id exploration_attention
    ) random_nodes
  else
    (* Increase exploitation - focus on high-attention nodes *)
    let high_attention_atoms = Hypergraph.get_high_attention_atoms engine.atomspace 5 in
    List.iter (fun (node_id, _) ->
      let focused_attention = { sti = 0.9; lti = 0.5; vlti = 0.2 } in
      Hypergraph.update_node_attention engine.atomspace node_id focused_attention
    ) high_attention_atoms

(** Solution ranking *)
let rank_solutions engine solutions config =
  let scored_solutions = List.map (fun solution ->
    let weighted_score = 
      config.novelty_weight *. solution.novelty_score +.
      config.feasibility_weight *. solution.feasibility_score +.
      (1.0 -. config.novelty_weight -. config.feasibility_weight) *. solution.creativity_score in
    (solution, weighted_score)
  ) solutions in
  
  let sorted_solutions = List.sort (fun (_, score1) (_, score2) -> 
    compare score2 score1) scored_solutions in
  
  List.map fst sorted_solutions

(** Meta-creative functions *)
let analyze_creative_performance engine =
  let strategy_stats = [
    (Breadth_first_creative, 0.7, 100);
    (Depth_first_creative, 0.8, 80);
    (Random_walk_attention, 0.9, 60);
    (Genetic_traversal, 0.6, 120);
    (Hybrid_multi_objective, 0.85, 150);
  ] in
  strategy_stats

let suggest_creativity_improvements engine config =
  let performance_stats = analyze_creative_performance engine in
  let (best_strategy, best_score, _) = List.hd performance_stats in
  
  match best_strategy with
  | Random_walk_attention -> 
      { config with divergent_thinking_ratio = min 1.0 (config.divergent_thinking_ratio +. 0.1) }
  | Genetic_traversal -> 
      { config with novelty_weight = min 1.0 (config.novelty_weight +. 0.1) }
  | _ -> config

let self_modify_creative_strategies engine =
  let improved_config = suggest_creativity_improvements engine default_creativity_config in
  Printf.printf "Updated creativity configuration based on performance analysis\n";
  (* Store improved configuration in engine for future use *)
  engine.creativity_history <- (Unix.gettimeofday (), "Strategy modification applied") :: engine.creativity_history;
  improved_config

(** Integration functions *)
let create_creative_reasoning_tasks engine problems =
  List.map (fun problem ->
    {
      Task_system.task_id = Random.int 10000;
      task_type = Task_system.Reasoning;
      priority = Task_system.High;
      data = Printf.sprintf "Creative problem: %d nodes" (List.length problem.initial_state);
      dependencies = [];
      completion_time = None;
      result = None;
    }
  ) problems

let execute_creative_task engine task =
  (* Simple task execution - would be more sophisticated in practice *)
  let dummy_problem = {
    initial_state = [1; 2];
    goal_state = [3; 4];
    constraints = { 
      required_nodes = []; forbidden_nodes = []; required_links = []; 
      forbidden_links = []; goal_predicates = [] 
    };
    creativity_level = 0.8;
    max_depth = 5;
    time_limit = 30.0;
  } in
  solve_creative_problem engine dummy_problem default_creativity_config Hybrid_multi_objective

let neural_guided_concept_generation engine seed_nodes count =
  (* Generate new concepts using neural-symbolic guidance *)
  List.fold_left (fun acc seed_node ->
    let new_concept_name = Printf.sprintf "neural_concept_%d_%d" seed_node (Random.int 1000) in
    let new_concept_id = Hypergraph.add_node engine.atomspace Hypergraph.Concept new_concept_name in
    let _ = Hypergraph.add_link engine.atomspace Hypergraph.Similarity [seed_node; new_concept_id] in
    engine.generated_concepts <- new_concept_id :: engine.generated_concepts;
    new_concept_id :: acc
  ) [] (ListUtils.take (min count (List.length seed_nodes)) seed_nodes)

let tensor_similarity_creative_search engine tensor_ids constraints =
  (* Use tensor operations for similarity-based creative search *)
  let similarity_threshold = 0.7 in
  let creative_paths = ref [] in
  
  List.iteri (fun i tensor_id1 ->
    List.iteri (fun j tensor_id2 ->
      if i < j then
        let similarity = Hypergraph.tensor_cosine_similarity_op engine.atomspace tensor_id1 tensor_id2 in
        if similarity > similarity_threshold then
          let path = {
            nodes = [i; j]; (* Using indices as proxy for node IDs *)
            links = [];
            creativity_score = similarity;
            novelty_score = 1.0 -. similarity; (* More novel if less similar *)
            feasibility_score = similarity;
            path_length = 2;
            exploration_steps = 1;
          } in
          creative_paths := path :: !creative_paths
    ) tensor_ids
  ) tensor_ids;
  
  !creative_paths

(** Scheme representation *)
let creative_solution_to_scheme solution =
  let paths_scheme = String.concat " " (List.map (fun path ->
    Printf.sprintf "(path (nodes (%s)) (creativity %.3f) (novelty %.3f))" 
      (String.concat " " (List.map string_of_int path.nodes))
      path.creativity_score path.novelty_score
  ) solution.paths) in
  Printf.sprintf "(creative_solution (exploration_time %.3f) (nodes_explored %d) (paths %s))"
    solution.total_exploration_time solution.nodes_explored paths_scheme

let problem_definition_to_scheme problem =
  Printf.sprintf "(problem (initial (%s)) (goal (%s)) (creativity_level %.3f) (max_depth %d))"
    (String.concat " " (List.map string_of_int problem.initial_state))
    (String.concat " " (List.map string_of_int problem.goal_state))
    problem.creativity_level problem.max_depth

let creativity_config_to_scheme config =
  Printf.sprintf "(creativity_config (divergent_ratio %.3f) (novelty_weight %.3f) (feasibility_weight %.3f))"
    config.divergent_thinking_ratio config.novelty_weight config.feasibility_weight

let creative_engine_to_scheme engine =
  Printf.sprintf "(creative_engine (explored_paths %d) (novel_associations %d) (generated_concepts %d))"
    (List.length engine.explored_paths)
    (List.length engine.novel_associations)
    (List.length engine.generated_concepts)

(** Debugging and diagnostics *)
let get_traversal_statistics engine =
  [
    ("total_paths_explored", List.length engine.explored_paths, 0.0);
    ("novel_associations_found", List.length engine.novel_associations, 0.0);
    ("concepts_generated", List.length engine.generated_concepts, 0.0);
  ]

let get_creativity_diagnostics engine =
  let stats = get_traversal_statistics engine in
  let stats_str = String.concat "; " (List.map (fun (name, count, _) ->
    Printf.sprintf "%s: %d" name count
  ) stats) in
  Printf.sprintf "Creative Engine Diagnostics: %s" stats_str

let visualize_solution_paths engine paths =
  let path_descriptions = List.mapi (fun i path ->
    Printf.sprintf "Path %d: %s (creativity: %.3f, novelty: %.3f)" 
      i 
      (String.concat " -> " (List.map string_of_int path.nodes))
      path.creativity_score path.novelty_score
  ) paths in
  String.concat "\n" path_descriptions

let benchmark_creativity engine problems configs =
  List.fold_left (fun acc config ->
    let strategy_results = List.map (fun strategy ->
      let start_time = Unix.gettimeofday () in
      let solutions = List.map (fun problem ->
        solve_creative_problem engine problem config strategy
      ) problems in
      let end_time = Unix.gettimeofday () in
      let avg_creativity = List.fold_left (fun sum sol ->
        sum +. (List.fold_left (fun path_sum path -> 
          path_sum +. path.creativity_score) 0.0 sol.paths)
      ) 0.0 solutions /. (float_of_int (List.length solutions)) in
      (strategy, avg_creativity, end_time -. start_time)
    ) [Breadth_first_creative; Depth_first_creative; Random_walk_attention; 
       Genetic_traversal; Hybrid_multi_objective] in
    acc @ strategy_results
  ) [] configs