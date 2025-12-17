(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** Hypergraph Cognition Kernel - Core Data Structures Implementation *)

(** Node identifiers *)
type node_id = int

(** Link identifiers *)
type link_id = int

(** Tensor identifiers *)
type tensor_id = int

(** Attention values for ECAN *)
type attention_value = {
  sti : float;  (** Short-term importance *)
  lti : float;  (** Long-term importance *)
  vlti : float; (** Very long-term importance *)
}

(** Node types for the AtomSpace *)
type node_type =
  | Concept
  | Predicate
  | Variable
  | Number
  | Link_type
  | Schema

(** Hypergraph node *)
type node = {
  id : node_id;
  node_type : node_type;
  name : string;
  attention : attention_value;
  truth_value : float * float; (** (strength, confidence) *)
}

(** Link types *)
type link_type =
  | Inheritance
  | Similarity
  | Implication
  | Evaluation
  | Execution
  | Custom of string

(** Hypergraph link connecting nodes *)
type link = {
  id : link_id;
  link_type : link_type;
  outgoing : node_id list;
  attention : attention_value;
  truth_value : float * float;
}

(** Tensor shapes for neural-symbolic integration *)
type tensor_shape = int list

(** Tensor for storing distributed representations *)
type tensor = {
  id : tensor_id;
  shape : tensor_shape;
  data : float array;
  associated_node : node_id option;
}

(** AtomSpace - the main hypergraph store *)
type atomspace = {
  mutable nodes : (node_id, node) Hashtbl.t;
  mutable links : (link_id, link) Hashtbl.t;
  mutable tensors : (tensor_id, tensor) Hashtbl.t;
  mutable next_node_id : node_id;
  mutable next_link_id : link_id;
  mutable next_tensor_id : tensor_id;
  mutable node_index : (string, node_id list) Hashtbl.t;
}

(** Create empty AtomSpace *)
let create_atomspace () = {
  nodes = Hashtbl.create 1000;
  links = Hashtbl.create 1000;
  tensors = Hashtbl.create 100;
  next_node_id = 1;
  next_link_id = 1;
  next_tensor_id = 1;
  node_index = Hashtbl.create 1000;
}

(** Default attention value *)
let default_attention = { sti = 0.0; lti = 0.0; vlti = 0.0 }

(** Node operations *)
let add_node atomspace node_type name =
  let id = atomspace.next_node_id in
  let node = {
    id = id;
    node_type = node_type;
    name = name;
    attention = default_attention;
    truth_value = (1.0, 1.0);
  } in
  Hashtbl.add atomspace.nodes id node;
  
  (* Update name index *)
  let existing = try Hashtbl.find atomspace.node_index name with Not_found -> [] in
  Hashtbl.replace atomspace.node_index name (id :: existing);
  
  atomspace.next_node_id <- id + 1;
  id

let get_node atomspace id =
  try Some (Hashtbl.find atomspace.nodes id)
  with Not_found -> None

let update_node_attention atomspace id attention =
  try
    let node = Hashtbl.find atomspace.nodes id in
    let updated_node = { node with attention = attention } in
    Hashtbl.replace atomspace.nodes id updated_node
  with Not_found -> ()

let update_node_truth atomspace id truth_value =
  try
    let node = Hashtbl.find atomspace.nodes id in
    let updated_node = { node with truth_value = truth_value } in
    Hashtbl.replace atomspace.nodes id updated_node
  with Not_found -> ()

let remove_node atomspace id =
  try
    let node = Hashtbl.find atomspace.nodes id in
    Hashtbl.remove atomspace.nodes id;
    
    (* Update name index *)
    let existing = try Hashtbl.find atomspace.node_index node.name with Not_found -> [] in
    let filtered = List.filter (fun x -> x <> id) existing in
    if filtered = [] then
      Hashtbl.remove atomspace.node_index node.name
    else
      Hashtbl.replace atomspace.node_index node.name filtered
  with Not_found -> ()

(** Link operations *)
let add_link atomspace link_type outgoing =
  let id = atomspace.next_link_id in
  let link = {
    id = id;
    link_type = link_type;
    outgoing = outgoing;
    attention = default_attention;
    truth_value = (1.0, 1.0);
  } in
  Hashtbl.add atomspace.links id link;
  atomspace.next_link_id <- id + 1;
  id

let get_link atomspace id =
  try Some (Hashtbl.find atomspace.links id)
  with Not_found -> None

let update_link_attention atomspace id attention =
  try
    let link = Hashtbl.find atomspace.links id in
    let updated_link = { link with attention = attention } in
    Hashtbl.replace atomspace.links id updated_link
  with Not_found -> ()

let update_link_truth atomspace id truth_value =
  try
    let link = Hashtbl.find atomspace.links id in
    let updated_link = { link with truth_value = truth_value } in
    Hashtbl.replace atomspace.links id updated_link
  with Not_found -> ()

let remove_link atomspace id =
  Hashtbl.remove atomspace.links id

(** Tensor operations *)
let add_tensor atomspace shape data associated_node =
  let id = atomspace.next_tensor_id in
  let tensor = {
    id = id;
    shape = shape;
    data = data;
    associated_node = associated_node;
  } in
  Hashtbl.add atomspace.tensors id tensor;
  atomspace.next_tensor_id <- id + 1;
  id

let get_tensor atomspace id =
  try Some (Hashtbl.find atomspace.tensors id)
  with Not_found -> None

let update_tensor_data atomspace id data =
  try
    let tensor = Hashtbl.find atomspace.tensors id in
    let updated_tensor = { tensor with data = data } in
    Hashtbl.replace atomspace.tensors id updated_tensor
  with Not_found -> ()

let remove_tensor atomspace id =
  Hashtbl.remove atomspace.tensors id

(** Tensor operations with backend support *)
let tensor_backend = ref Tensor_backend.OCaml_native
let tensor_context = ref (Tensor_backend.create_context Tensor_backend.OCaml_native)

let set_tensor_backend backend =
  tensor_backend := backend;
  tensor_context := Tensor_backend.create_context backend

let get_tensor_backend () = !tensor_backend

let tensor_add_op atomspace id1 id2 =
  match get_tensor atomspace id1, get_tensor atomspace id2 with
  | Some t1, Some t2 ->
      if not (Tensor_backend.validate_shapes t1.shape t2.shape) then
        failwith "Tensor shapes must match for addition"
      else
        let result_data = Tensor_backend.tensor_add !tensor_context t1.shape t1.data t2.data in
        add_tensor atomspace t1.shape result_data None
  | _ -> failwith "One or both tensors not found"

let tensor_multiply_op atomspace id1 id2 =
  match get_tensor atomspace id1, get_tensor atomspace id2 with
  | Some t1, Some t2 ->
      if not (Tensor_backend.validate_shapes t1.shape t2.shape) then
        failwith "Tensor shapes must match for element-wise multiplication"
      else
        let result_data = Tensor_backend.tensor_multiply !tensor_context t1.shape t1.data t2.data in
        add_tensor atomspace t1.shape result_data None
  | _ -> failwith "One or both tensors not found"

let tensor_matmul_op atomspace id1 id2 =
  match get_tensor atomspace id1, get_tensor atomspace id2 with
  | Some t1, Some t2 ->
      let result_data = Tensor_backend.tensor_matmul !tensor_context t1.shape t2.shape t1.data t2.data in
      (* Calculate result shape for matrix multiplication *)
      let result_shape = match t1.shape, t2.shape with
        | [m; _], [_; n] -> [m; n]
        | _ -> failwith "Matrix multiplication requires 2D tensors"
      in
      add_tensor atomspace result_shape result_data None
  | _ -> failwith "One or both tensors not found"

let tensor_scale_op atomspace id scalar =
  match get_tensor atomspace id with
  | Some t ->
      let result_data = Tensor_backend.tensor_scale !tensor_context t.shape scalar t.data in
      add_tensor atomspace t.shape result_data t.associated_node
  | None -> failwith "Tensor not found"

let tensor_transpose_op atomspace id =
  match get_tensor atomspace id with
  | Some t ->
      let result_data, result_shape = Tensor_backend.tensor_transpose !tensor_context t.shape t.data in
      add_tensor atomspace result_shape result_data t.associated_node
  | None -> failwith "Tensor not found"

let tensor_dot_product_op atomspace id1 id2 =
  match get_tensor atomspace id1, get_tensor atomspace id2 with
  | Some t1, Some t2 ->
      Tensor_backend.tensor_dot_product !tensor_context t1.data t2.data
  | _ -> failwith "One or both tensors not found"

let tensor_norm_op atomspace id =
  match get_tensor atomspace id with
  | Some t -> Tensor_backend.tensor_norm !tensor_context t.data
  | None -> failwith "Tensor not found"

let tensor_relu_op atomspace id =
  match get_tensor atomspace id with
  | Some t ->
      let result_data = Tensor_backend.tensor_relu !tensor_context t.shape t.data in
      add_tensor atomspace t.shape result_data t.associated_node
  | None -> failwith "Tensor not found"

let tensor_sigmoid_op atomspace id =
  match get_tensor atomspace id with
  | Some t ->
      let result_data = Tensor_backend.tensor_sigmoid !tensor_context t.shape t.data in
      add_tensor atomspace t.shape result_data t.associated_node
  | None -> failwith "Tensor not found"

let tensor_softmax_op atomspace id =
  match get_tensor atomspace id with
  | Some t ->
      let result_data = Tensor_backend.tensor_softmax !tensor_context t.shape t.data in
      add_tensor atomspace t.shape result_data t.associated_node
  | None -> failwith "Tensor not found"

let tensor_cosine_similarity_op atomspace id1 id2 =
  match get_tensor atomspace id1, get_tensor atomspace id2 with
  | Some t1, Some t2 ->
      if Tensor_backend.validate_shapes t1.shape t2.shape then
        let dot_product = Tensor_backend.tensor_dot_product !tensor_context t1.data t2.data in
        let norm1 = Tensor_backend.tensor_norm !tensor_context t1.data in
        let norm2 = Tensor_backend.tensor_norm !tensor_context t2.data in
        if norm1 > 0.0 && norm2 > 0.0 then
          dot_product /. (norm1 *. norm2)
        else 0.0
      else 0.0
  | _ -> 0.0

(** Query operations *)
let find_nodes_by_name atomspace name =
  try Hashtbl.find atomspace.node_index name
  with Not_found -> []

let find_nodes_by_type atomspace node_type =
  let result = ref [] in
  Hashtbl.iter (fun _ node ->
    if node.node_type = node_type then
      result := node.id :: !result
  ) atomspace.nodes;
  !result

let find_links_by_type atomspace link_type =
  let result = ref [] in
  Hashtbl.iter (fun _ link ->
    if link.link_type = link_type then
      result := link.id :: !result
  ) atomspace.links;
  !result

let get_incoming_links atomspace node_id =
  let result = ref [] in
  Hashtbl.iter (fun _ link ->
    if List.mem node_id link.outgoing then
      result := link.id :: !result
  ) atomspace.links;
  !result

let get_outgoing_links atomspace node_id =
  let result = ref [] in
  Hashtbl.iter (fun _ link ->
    match link.outgoing with
    | [] -> ()
    | hd :: _ when hd = node_id -> result := link.id :: !result
    | _ -> ()
  ) atomspace.links;
  !result

(** Attention allocation primitives (ECAN) *)
let spread_activation atomspace source_id amount =
  let incoming = get_incoming_links atomspace source_id in
  let outgoing = get_outgoing_links atomspace source_id in
  let all_connected = incoming @ outgoing in
  
  if all_connected <> [] then (
    let spread_amount = amount /. (float_of_int (List.length all_connected)) in
    List.iter (fun link_id ->
      match get_link atomspace link_id with
      | Some link ->
          let old_attention = link.attention in
          let new_attention = {
            sti = old_attention.sti +. spread_amount;
            lti = old_attention.lti;
            vlti = old_attention.vlti;
          } in
          update_link_attention atomspace link_id new_attention
      | None -> ()
    ) all_connected
  ) else ()

let decay_attention atomspace decay_factor =
  let decay_node_attention (_ : node_id) (node : node) =
    let old_attention = node.attention in
    let new_attention = {
      sti = old_attention.sti *. decay_factor;
      lti = old_attention.lti *. decay_factor;
      vlti = old_attention.vlti;
    } in
    update_node_attention atomspace node.id new_attention
  in
  Hashtbl.iter decay_node_attention atomspace.nodes;
  
  let decay_link_attention (_ : link_id) (link : link) =
    let old_attention = link.attention in
    let new_attention = {
      sti = old_attention.sti *. decay_factor;
      lti = old_attention.lti *. decay_factor;
      vlti = old_attention.vlti;
    } in
    update_link_attention atomspace link.id new_attention
  in
  Hashtbl.iter decay_link_attention atomspace.links

let get_high_attention_atoms atomspace count =
  let node_list = ref [] in
  let link_list = ref [] in
  
  Hashtbl.iter (fun (_ : node_id) (node : node) ->
    node_list := (node.id, node.attention.sti) :: !node_list
  ) atomspace.nodes;
  
  Hashtbl.iter (fun (_ : link_id) (link : link) ->
    link_list := (link.id, link.attention.sti) :: !link_list
  ) atomspace.links;
  
  let sorted_nodes = List.sort (fun (_, a) (_, b) -> compare b a) !node_list in
  let sorted_links = List.sort (fun (_, a) (_, b) -> compare b a) !link_list in
  
  let take_n lst n =
    let rec aux acc lst n =
      match lst, n with
      | [], _ | _, 0 -> List.rev acc
      | (id, _) :: tl, n -> aux (id :: acc) tl (n - 1)
    in
    aux [] lst n
  in
  
  let top_nodes = take_n sorted_nodes (count / 2) in
  let top_links = take_n sorted_links (count / 2) in
  
  List.combine top_nodes top_links

(** Scheme S-expression conversion *)
let node_type_to_string = function
  | Concept -> "Concept"
  | Predicate -> "Predicate"
  | Variable -> "Variable"
  | Number -> "Number"
  | Link_type -> "LinkType"
  | Schema -> "Schema"

let link_type_to_string = function
  | Inheritance -> "Inheritance"
  | Similarity -> "Similarity" 
  | Implication -> "Implication"
  | Evaluation -> "Evaluation"
  | Execution -> "Execution"
  | Custom s -> s

let attention_to_scheme attention =
  Printf.sprintf "(attention (sti %.3f) (lti %.3f) (vlti %.3f))"
    attention.sti attention.lti attention.vlti

let truth_to_scheme (strength, confidence) =
  Printf.sprintf "(truth %.3f %.3f)" strength confidence

let node_to_scheme (node : node) =
  Printf.sprintf "(node (id %d) (type %s) (name \"%s\") %s %s)"
    node.id
    (node_type_to_string node.node_type)
    node.name
    (attention_to_scheme node.attention)
    (truth_to_scheme node.truth_value)

let link_to_scheme link =
  let outgoing_str = String.concat " " (List.map string_of_int link.outgoing) in
  Printf.sprintf "(link (id %d) (type %s) (outgoing (%s)) %s %s)"
    link.id
    (link_type_to_string link.link_type)
    outgoing_str
    (attention_to_scheme link.attention)
    (truth_to_scheme link.truth_value)

let tensor_to_scheme tensor =
  let shape_str = String.concat " " (List.map string_of_int tensor.shape) in
  let data_str = String.concat " " (Array.to_list (Array.map string_of_float tensor.data)) in
  let assoc_str = match tensor.associated_node with
    | Some id -> Printf.sprintf " (associated %d)" id
    | None -> ""
  in
  Printf.sprintf "(tensor (id %d) (shape (%s)) (data (%s))%s)"
    tensor.id shape_str data_str assoc_str

let atomspace_to_scheme atomspace =
  let nodes = ref [] in
  let links = ref [] in
  let tensors = ref [] in
  
  Hashtbl.iter (fun _ node -> nodes := node_to_scheme node :: !nodes) atomspace.nodes;
  Hashtbl.iter (fun _ link -> links := link_to_scheme link :: !links) atomspace.links;
  Hashtbl.iter (fun _ tensor -> tensors := tensor_to_scheme tensor :: !tensors) atomspace.tensors;
  
  Printf.sprintf "(atomspace\n  (nodes\n    %s)\n  (links\n    %s)\n  (tensors\n    %s))"
    (String.concat "\n    " !nodes)
    (String.concat "\n    " !links)  
    (String.concat "\n    " !tensors)