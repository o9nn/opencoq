(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** ECAN (Economic Attention Networks) - Attention Allocation System Implementation *)

(** Helper function for List.take *)
let rec take n lst =
  match lst, n with
  | [], _ | _, 0 -> []
  | hd :: tl, n when n > 0 -> hd :: take (n - 1) tl
  | _ -> []

(** Attention events *)
type attention_event =
  | Stimulus of Hypergraph.node_id * float
  | Decay of float
  | Rent_collection of float
  | Spread_activation of Hypergraph.node_id * float
  | Gradient_update of Hypergraph.node_id * float array

(** Multi-head attention tensor structure (A, T) *)
type attention_tensor = {
  attention_heads : int;        (** A - number of attention heads *)
  temporal_depth : int;         (** T - temporal depth for attention patterns *)
  mutable tensor_data : float array array; (** [A][T] tensor data *)
  mutable gradients : float array array;   (** Gradient information for optimization *)
  mutable head_weights : float array;      (** Importance weights for each head *)
  mutable temporal_weights : float array;  (** Weights for temporal positions *)
}

(** Gradient-based attention optimization configuration *)
type gradient_attention_config = {
  learning_rate : float;
  momentum_factor : float;
  gradient_clipping : float;
  update_frequency : int;
  economic_weight : float;  (** Weight for ECAN economic considerations *)
}

(** Attention bank for economic attention allocation *)
type attention_bank = {
  mutable total_sti : float;
  mutable available_sti : float;
  mutable total_lti : float;
  mutable available_lti : float;
  mutable minimum_sti : float;
  mutable minimum_lti : float;
}

(** Attention allocation configuration *)
type ecan_config = {
  sti_funds : float;
  lti_funds : float;
  decay_factor : float;
  rent_rate : float;
  spread_threshold : float;
  forgetting_threshold : float;
}

(** Attentional focus - high attention atoms *)
type attentional_focus = {
  mutable focus_size : int;
  mutable focused_atoms : (Hypergraph.node_id * Hypergraph.link_id) list;
  mutable update_frequency : int;
}

(** ECAN system state *)
type ecan_system = {
  atomspace : Hypergraph.atomspace;
  attention_bank : attention_bank;
  config : ecan_config;
  attentional_focus : attentional_focus;
  mutable event_history : attention_event list;
}

(** Default ECAN configuration *)
let default_ecan_config = {
  sti_funds = 10000.0;
  lti_funds = 10000.0;
  decay_factor = 0.99;
  rent_rate = 0.01;
  spread_threshold = 10.0;
  forgetting_threshold = 1.0;
}

(** Attention bank operations *)
let initialize_attention_bank sti_total lti_total = {
  total_sti = sti_total;
  available_sti = sti_total;
  total_lti = lti_total;
  available_lti = lti_total;
  minimum_sti = 0.0;
  minimum_lti = 0.0;
}

let allocate_sti bank amount =
  if bank.available_sti >= amount then (
    bank.available_sti <- bank.available_sti -. amount;
    true
  ) else false

let allocate_lti bank amount =
  if bank.available_lti >= amount then (
    bank.available_lti <- bank.available_lti -. amount;
    true
  ) else false

let return_sti bank amount =
  bank.available_sti <- min bank.total_sti (bank.available_sti +. amount)

let return_lti bank amount =
  bank.available_lti <- min bank.total_lti (bank.available_lti +. amount)

let get_bank_status bank =
  (bank.total_sti, bank.available_sti, bank.total_lti, bank.available_lti)

(** Create ECAN system *)
let create_ecan_system atomspace config =
  let bank = initialize_attention_bank config.sti_funds config.lti_funds in
  let focus = {
    focus_size = 20;
    focused_atoms = [];
    update_frequency = 10;
  } in
  {
    atomspace = atomspace;
    attention_bank = bank;
    config = config;
    attentional_focus = focus;
    event_history = [];
  }

(** Core ECAN operations *)
let stimulate_atom system node_id amount =
  match Hypergraph.get_node system.atomspace node_id with
  | None -> ()
  | Some node ->
      if allocate_sti system.attention_bank amount then (
        let new_attention = {
          node.attention with
          sti = node.attention.sti +. amount
        } in
        Hypergraph.update_node_attention system.atomspace node_id new_attention;
        system.event_history <- Stimulus (node_id, amount) :: system.event_history
      )

let spread_activation system source_id =
  match Hypergraph.get_node system.atomspace source_id with
  | None -> ()
  | Some source ->
      if source.attention.sti > system.config.spread_threshold then (
        let spread_amount = source.attention.sti *. 0.1 in
        let incoming = Hypergraph.get_incoming_links system.atomspace source_id in
        let outgoing = Hypergraph.get_outgoing_links system.atomspace source_id in
        let all_links = incoming @ outgoing in
        
        if all_links <> [] then (
          let amount_per_link = spread_amount /. float_of_int (List.length all_links) in
          List.iter (fun link_id ->
            match Hypergraph.get_link system.atomspace link_id with
            | Some link ->
                let new_attention = {
                  link.attention with
                  sti = link.attention.sti +. amount_per_link
                } in
                Hypergraph.update_link_attention system.atomspace link_id new_attention
            | None -> ()
          ) all_links;
          
          (* Reduce source attention *)
          let new_source_attention = {
            source.attention with
            sti = source.attention.sti -. spread_amount
          } in
          Hypergraph.update_node_attention system.atomspace source_id new_source_attention;
          system.event_history <- Spread_activation (source_id, spread_amount) :: system.event_history
        )
      )

let apply_decay system =
  let decay_factor = system.config.decay_factor in
  Hypergraph.decay_attention system.atomspace decay_factor;
  system.event_history <- Decay decay_factor :: system.event_history

let collect_rent system =
  let rent_rate = system.config.rent_rate in
  let total_rent_collected = ref 0.0 in
  
  (* Collect rent from nodes *)
  Hashtbl.iter (fun _ (node : Hypergraph.node) ->
    let rent = node.attention.sti *. rent_rate in
    let new_attention = {
      node.attention with
      sti = max 0.0 (node.attention.sti -. rent)
    } in
    Hypergraph.update_node_attention system.atomspace node.id new_attention;
    total_rent_collected := !total_rent_collected +. rent
  ) system.atomspace.nodes;
  
  (* Collect rent from links *)
  Hashtbl.iter (fun _ (link : Hypergraph.link) ->
    let rent = link.attention.sti *. rent_rate in
    let new_attention = {
      link.attention with
      sti = max 0.0 (link.attention.sti -. rent)
    } in
    Hypergraph.update_link_attention system.atomspace link.id new_attention;
    total_rent_collected := !total_rent_collected +. rent
  ) system.atomspace.links;
  
  return_sti system.attention_bank !total_rent_collected;
  system.event_history <- Rent_collection !total_rent_collected :: system.event_history

let forget_low_attention_atoms system =
  let threshold = system.config.forgetting_threshold in
  let to_remove = ref [] in
  
  Hashtbl.iter (fun _ (node : Hypergraph.node) ->
    if node.attention.sti < threshold && node.attention.lti < threshold then
      to_remove := node.id :: !to_remove
  ) system.atomspace.nodes;
  
  List.iter (Hypergraph.remove_node system.atomspace) !to_remove

(** Attentional focus management *)
let update_attentional_focus system =
  let high_attention = Hypergraph.get_high_attention_atoms system.atomspace system.attentional_focus.focus_size in
  system.attentional_focus.focused_atoms <- high_attention

let get_focused_atoms system = system.attentional_focus.focused_atoms

let is_in_focus system node_id =
  List.exists (fun (nid, _) -> nid = node_id) system.attentional_focus.focused_atoms

(** Attention-guided processing *)
let get_attention_guided_tasks system =
  let focused = get_focused_atoms system in
  if List.length focused > 15 then
    [Task_system.Attention_allocation; Task_system.Memory_consolidation]
  else if List.length focused > 5 then
    [Task_system.Reasoning_task; Task_system.Pattern_matching]
  else
    [Task_system.Meta_cognition]

let prioritize_by_attention system node_ids =
  let with_attention = List.map (fun id ->
    match Hypergraph.get_node system.atomspace id with
    | Some node -> (id, node.attention.sti)
    | None -> (id, 0.0)
  ) node_ids in
  let sorted = List.sort (fun (_, a1) (_, a2) -> compare a2 a1) with_attention in
  List.map fst sorted

(** Economic dynamics *)
let calculate_importance system node_id =
  match Hypergraph.get_node system.atomspace node_id with
  | None -> 0.0
  | Some node ->
      let incoming_count = float_of_int (List.length (Hypergraph.get_incoming_links system.atomspace node_id)) in
      let outgoing_count = float_of_int (List.length (Hypergraph.get_outgoing_links system.atomspace node_id)) in
      node.attention.sti +. node.attention.lti +. (incoming_count *. 0.1) +. (outgoing_count *. 0.1)

let wage_attention system node_id amount =
  match Hypergraph.get_node system.atomspace node_id with
  | None -> ()
  | Some node ->
      if allocate_sti system.attention_bank amount then (
        let importance = calculate_importance system node_id in
        let adjusted_amount = amount *. (importance /. 100.0) in
        let new_attention = {
          node.attention with
          sti = node.attention.sti +. adjusted_amount
        } in
        Hypergraph.update_node_attention system.atomspace node_id new_attention
      )

let attention_competition system node_ids =
  let sorted = prioritize_by_attention system node_ids in
  let winners = take (min 5 (List.length sorted)) sorted in
  winners

(** ECAN cycle - main processing loop *)
let ecan_cycle system =
  apply_decay system;
  collect_rent system;
  
  (* Spread activation for high attention atoms *)
  let focused = get_focused_atoms system in
  List.iter (fun (node_id, _) -> spread_activation system node_id) focused;
  
  update_attentional_focus system;
  forget_low_attention_atoms system;
  
  (* Limit event history size *)
  if List.length system.event_history > 1000 then
    system.event_history <- take 1000 system.event_history

(** Monitoring and diagnostics *)
let get_attention_statistics system =
  let (total_sti, available_sti, total_lti, available_lti) = get_bank_status system.attention_bank in
  let num_nodes = Hashtbl.length system.atomspace.nodes in
  let num_focused = List.length system.attentional_focus.focused_atoms in
  (available_sti, available_lti, num_nodes, num_focused)

let get_most_important_atoms system count =
  let node_list = ref [] in
  Hashtbl.iter (fun _ (node : Hypergraph.node) ->
    let importance = calculate_importance system node.id in
    node_list := (node.id, importance) :: !node_list
  ) system.atomspace.nodes;
  let sorted = List.sort (fun (_, i1) (_, i2) -> compare i2 i1) !node_list in
  List.map fst (take (min count (List.length sorted)) sorted)

let get_attention_distribution system =
  let buckets = Array.make 10 0 in
  Hashtbl.iter (fun _ (node : Hypergraph.node) ->
    let bucket = min 9 (int_of_float (node.attention.sti /. 10.0)) in
    buckets.(bucket) <- buckets.(bucket) + 1
  ) system.atomspace.nodes;
  Array.to_list (Array.mapi (fun i count -> (float_of_int (i * 10), count)) buckets)

(** Scheme representation *)
let attention_event_to_scheme = function
  | Stimulus (node_id, amount) -> Printf.sprintf "(stimulus %d %.3f)" node_id amount
  | Decay factor -> Printf.sprintf "(decay %.3f)" factor
  | Rent_collection amount -> Printf.sprintf "(rent-collection %.3f)" amount
  | Spread_activation (node_id, amount) -> Printf.sprintf "(spread-activation %d %.3f)" node_id amount
  | Gradient_update (head_id, gradients) -> 
      let grad_str = String.concat " " (Array.to_list (Array.map (Printf.sprintf "%.3f") gradients)) in
      Printf.sprintf "(gradient-update %d (%s))" head_id grad_str

let attention_bank_to_scheme bank =
  Printf.sprintf "(attention-bank (sti-total %.3f) (sti-available %.3f) (lti-total %.3f) (lti-available %.3f))"
    bank.total_sti bank.available_sti bank.total_lti bank.available_lti

let ecan_config_to_scheme config =
  Printf.sprintf "(ecan-config (sti-funds %.3f) (lti-funds %.3f) (decay-factor %.3f) (rent-rate %.3f) (spread-threshold %.3f) (forgetting-threshold %.3f))"
    config.sti_funds config.lti_funds config.decay_factor config.rent_rate config.spread_threshold config.forgetting_threshold

let ecan_system_to_scheme system =
  let events_str = String.concat " " (List.map attention_event_to_scheme (take 10 system.event_history)) in
  let focused_str = String.concat " " (List.map (fun (nid, lid) -> Printf.sprintf "(%d %d)" nid lid) system.attentional_focus.focused_atoms) in
  Printf.sprintf "(ecan-system\n  %s\n  %s\n  (focus-size %d)\n  (focused-atoms (%s))\n  (recent-events (%s)))"
    (attention_bank_to_scheme system.attention_bank)
    (ecan_config_to_scheme system.config)
    system.attentional_focus.focus_size
    focused_str
    events_str

(** Gradient-based attention optimization implementation *)

(** Default gradient attention configuration *)
let default_gradient_attention_config = {
  learning_rate = 0.01;
  momentum_factor = 0.9;
  gradient_clipping = 1.0;
  update_frequency = 10;
  economic_weight = 0.5;
}

(** Create attention tensor with A heads and T temporal depth *)
let create_attention_tensor attention_heads temporal_depth =
  let tensor_data = Array.make_matrix attention_heads temporal_depth 0.0 in
  let gradients = Array.make_matrix attention_heads temporal_depth 0.0 in
  let head_weights = Array.make attention_heads (1.0 /. float_of_int attention_heads) in
  let temporal_weights = Array.make temporal_depth (1.0 /. float_of_int temporal_depth) in
  {
    attention_heads;
    temporal_depth;
    tensor_data;
    gradients;
    head_weights;
    temporal_weights;
  }

(** Update attention gradients for a specific node *)
let update_attention_gradients attention_tensor node_id gradient_values =
  let num_heads = attention_tensor.attention_heads in
  let gradient_len = Array.length gradient_values in
  
  (* Distribute gradients across attention heads *)
  for head = 0 to num_heads - 1 do
    for t = 0 to attention_tensor.temporal_depth - 1 do
      let grad_idx = (head * attention_tensor.temporal_depth + t) mod gradient_len in
      attention_tensor.gradients.(head).(t) <- gradient_values.(grad_idx)
    done
  done

(** Apply gradient-based optimization to attention allocation *)
let apply_gradient_optimization system attention_tensor config =
  let learning_rate = config.learning_rate in
  let momentum = config.momentum_factor in
  let clip_threshold = config.gradient_clipping in
  
  (* Apply gradient updates with momentum and clipping *)
  for head = 0 to attention_tensor.attention_heads - 1 do
    for t = 0 to attention_tensor.temporal_depth - 1 do
      let grad = attention_tensor.gradients.(head).(t) in
      
      (* Gradient clipping *)
      let clipped_grad = max (-. clip_threshold) (min clip_threshold grad) in
      
      (* Apply momentum and learning rate *)
      let old_value = attention_tensor.tensor_data.(head).(t) in
      let new_value = old_value +. (learning_rate *. clipped_grad) in
      attention_tensor.tensor_data.(head).(t) <- new_value;
      
      (* Update head weight based on performance *)
      let performance = abs_float new_value in
      attention_tensor.head_weights.(head) <- 
        momentum *. attention_tensor.head_weights.(head) +. 
        (1.0 -. momentum) *. performance
    done
  done;
  
  (* Normalize head weights *)
  let total_weight = Array.fold_left (+.) 0.0 attention_tensor.head_weights in
  if total_weight > 0.0 then
    Array.iteri (fun i w -> 
      attention_tensor.head_weights.(i) <- w /. total_weight
    ) attention_tensor.head_weights

(** Compute importance of each attention head for a node *)
let compute_attention_head_importance attention_tensor node_id =
  let head_importance = Array.make attention_tensor.attention_heads 0.0 in
  
  for head = 0 to attention_tensor.attention_heads - 1 do
    let head_value = ref 0.0 in
    for t = 0 to attention_tensor.temporal_depth - 1 do
      head_value := !head_value +. attention_tensor.tensor_data.(head).(t)
    done;
    head_importance.(head) <- !head_value *. attention_tensor.head_weights.(head)
  done;
  
  head_importance

(** Allocate compute cycles based on attention gradients and ECAN economics *)
let allocate_compute_cycles_by_attention system attention_tensor config =
  let cycle_allocation = Array.make attention_tensor.attention_heads 0.0 in
  let economic_weight = config.economic_weight in
  let available_sti = system.attention_bank.available_sti in
  
  (* Calculate total attention across all heads *)
  let total_attention = ref 0.0 in
  for head = 0 to attention_tensor.attention_heads - 1 do
    let head_sum = ref 0.0 in
    for t = 0 to attention_tensor.temporal_depth - 1 do
      head_sum := !head_sum +. abs_float attention_tensor.tensor_data.(head).(t)
    done;
    total_attention := !total_attention +. !head_sum
  done;
  
  (* Allocate cycles proportionally to attention and available STI *)
  if !total_attention > 0.0 then (
    for head = 0 to attention_tensor.attention_heads - 1 do
      let head_sum = ref 0.0 in
      for t = 0 to attention_tensor.temporal_depth - 1 do
        head_sum := !head_sum +. abs_float attention_tensor.tensor_data.(head).(t)
      done;
      
      let attention_ratio = !head_sum /. !total_attention in
      let economic_factor = economic_weight *. (available_sti /. system.attention_bank.total_sti) in
      cycle_allocation.(head) <- attention_ratio *. economic_factor *. attention_tensor.head_weights.(head)
    done
  );
  
  cycle_allocation

(** Apply temporal decay to attention tensor *)
let temporal_attention_decay attention_tensor decay_factor =
  for head = 0 to attention_tensor.attention_heads - 1 do
    for t = 0 to attention_tensor.temporal_depth - 1 do
      attention_tensor.tensor_data.(head).(t) <- 
        attention_tensor.tensor_data.(head).(t) *. decay_factor;
      attention_tensor.gradients.(head).(t) <- 
        attention_tensor.gradients.(head).(t) *. decay_factor
    done
  done;
  
  (* Update temporal weights with decay *)
  for t = 0 to attention_tensor.temporal_depth - 1 do
    attention_tensor.temporal_weights.(t) <- 
      attention_tensor.temporal_weights.(t) *. decay_factor
  done

(** Integrate gradient optimization with ECAN economic system *)
let economic_gradient_integration system attention_tensor config =
  let cycle_allocation = allocate_compute_cycles_by_attention system attention_tensor config in
  
  (* Update ECAN based on attention head performance *)
  Array.iteri (fun head allocation ->
    if allocation > 0.0 then (
      let sti_cost = allocation *. 10.0 in (* Convert allocation to STI cost *)
      if allocate_sti system.attention_bank sti_cost then (
        (* Record economic gradient update *)
        let gradient_event = Gradient_update (head, cycle_allocation) in
        system.event_history <- gradient_event :: system.event_history
      )
    )
  ) cycle_allocation;
  
  (* Apply temporal decay based on ECAN decay factor *)
  temporal_attention_decay attention_tensor system.config.decay_factor

(** Get statistics for attention tensor *)
let get_attention_tensor_stats attention_tensor =
  let total_attention = ref 0.0 in
  let max_attention = ref neg_infinity in
  let min_attention = ref infinity in
  let active_heads = ref 0 in
  
  for head = 0 to attention_tensor.attention_heads - 1 do
    let head_sum = ref 0.0 in
    let head_active = ref false in
    
    for t = 0 to attention_tensor.temporal_depth - 1 do
      let value = attention_tensor.tensor_data.(head).(t) in
      head_sum := !head_sum +. abs_float value;
      if abs_float value > 0.001 then head_active := true;
      max_attention := max !max_attention value;
      min_attention := min !min_attention value
    done;
    
    total_attention := !total_attention +. !head_sum;
    if !head_active then incr active_heads
  done;
  
  let avg_attention = !total_attention /. float_of_int (attention_tensor.attention_heads * attention_tensor.temporal_depth) in
  (avg_attention, !max_attention, !min_attention, float_of_int !active_heads)