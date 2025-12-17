(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** Task System for Distributed Cognitive Operations Implementation *)

(** Task identifiers *)
type task_id = int

(** Task priorities *)
type priority = High | Medium | Low

(** Task status *)
type task_status = 
  | Pending
  | Running
  | Completed
  | Failed of string

(** Cognitive task types *)
type task_type =
  | Reasoning_task
  | Pattern_matching
  | Attention_allocation
  | Memory_consolidation
  | Meta_cognition

(** Cognitive task *)
type cognitive_task = {
  id : task_id;
  task_type : task_type;
  priority : priority;
  mutable status : task_status;
  description : string;
  target_atomspace : Hypergraph.atomspace;
  dependencies : task_id list;
  execution_function : unit -> unit;
  created_time : float;
  mutable start_time : float option;
  mutable end_time : float option;
}

(** Task queue *)
type task_queue = {
  mutable tasks : (task_id, cognitive_task) Hashtbl.t;
  mutable pending_queue : task_id Queue.t;
  mutable running_tasks : task_id list;
  mutable completed_tasks : task_id list;
  mutable next_task_id : task_id;
  mutable max_concurrent : int;
}

(** Create a new task queue *)
let create_task_queue max_concurrent = {
  tasks = Hashtbl.create 100;
  pending_queue = Queue.create ();
  running_tasks = [];
  completed_tasks = [];
  next_task_id = 1;
  max_concurrent = max_concurrent;
}

(** Get current time *)
let get_current_time () = Unix.time ()

(** Task management operations *)
let add_task queue task_type priority description atomspace dependencies execution_function =
  let id = queue.next_task_id in
  let task = {
    id = id;
    task_type = task_type;
    priority = priority;
    status = Pending;
    description = description;
    target_atomspace = atomspace;
    dependencies = dependencies;
    execution_function = execution_function;
    created_time = get_current_time ();
    start_time = None;
    end_time = None;
  } in
  Hashtbl.add queue.tasks id task;
  Queue.add id queue.pending_queue;
  queue.next_task_id <- id + 1;
  id

let get_task queue id =
  try Some (Hashtbl.find queue.tasks id)
  with Not_found -> None

let remove_task queue id =
  Hashtbl.remove queue.tasks id;
  (* Note: removing from queues is more complex in practice *)
  queue.running_tasks <- List.filter (fun x -> x <> id) queue.running_tasks;
  queue.completed_tasks <- List.filter (fun x -> x <> id) queue.completed_tasks

let update_task_status queue id status =
  try
    let task = Hashtbl.find queue.tasks id in
    task.status <- status;
    (match status with
     | Running ->
         task.start_time <- Some (get_current_time ());
         queue.running_tasks <- id :: queue.running_tasks
     | Completed | Failed _ ->
         task.end_time <- Some (get_current_time ());
         queue.running_tasks <- List.filter (fun x -> x <> id) queue.running_tasks;
         queue.completed_tasks <- id :: queue.completed_tasks
     | Pending -> ())
  with Not_found -> ()

(** Priority comparison *)
let priority_to_int = function
  | High -> 3
  | Medium -> 2
  | Low -> 1

let compare_priority p1 p2 = 
  compare (priority_to_int p2) (priority_to_int p1) (* Higher priority first *)

(** Task dependency management *)
let check_dependencies queue task_id =
  match get_task queue task_id with
  | None -> false
  | Some task ->
      List.for_all (fun dep_id ->
        match get_task queue dep_id with
        | None -> false
        | Some dep_task -> 
            match dep_task.status with
            | Completed -> true
            | _ -> false
      ) task.dependencies

let get_ready_tasks queue =
  let ready = ref [] in
  Queue.iter (fun task_id ->
    if check_dependencies queue task_id then
      ready := task_id :: !ready
  ) queue.pending_queue;
  !ready

(** Task scheduling operations *)
let schedule_next_tasks queue =
  let ready_tasks = get_ready_tasks queue in
  let available_slots = queue.max_concurrent - List.length queue.running_tasks in
  let to_schedule = ref [] in
  let count = ref 0 in
  
  (* Sort by priority *)
  let sorted_ready = List.sort (fun id1 id2 ->
    match get_task queue id1, get_task queue id2 with
    | Some t1, Some t2 -> compare_priority t1.priority t2.priority
    | _ -> 0
  ) ready_tasks in
  
  List.iter (fun task_id ->
    if !count < available_slots then (
      to_schedule := task_id :: !to_schedule;
      incr count
    )
  ) sorted_ready;
  
  !to_schedule

let execute_task queue task_id =
  match get_task queue task_id with
  | None -> ()
  | Some task ->
      update_task_status queue task_id Running;
      try
        task.execution_function ();
        update_task_status queue task_id Completed
      with
      | e -> update_task_status queue task_id (Failed (Printexc.to_string e))

let process_queue queue max_iterations =
  let iterations = ref 0 in
  while !iterations < max_iterations && not (Queue.is_empty queue.pending_queue) do
    let to_schedule = schedule_next_tasks queue in
    List.iter (execute_task queue) to_schedule;
    (* Remove completed tasks from pending queue *)
    let new_pending = Queue.create () in
    Queue.iter (fun task_id ->
      match get_task queue task_id with
      | Some task when task.status = Pending -> Queue.add task_id new_pending
      | _ -> ()
    ) queue.pending_queue;
    queue.pending_queue <- new_pending;
    incr iterations
  done

(** Query operations *)
let get_tasks_by_status queue status =
  let result = ref [] in
  Hashtbl.iter (fun _ task ->
    if task.status = status then
      result := task :: !result
  ) queue.tasks;
  !result

let get_pending_tasks queue = get_tasks_by_status queue Pending

let get_running_tasks queue = get_tasks_by_status queue Running

let get_completed_tasks queue = get_tasks_by_status queue Completed

let get_tasks_by_type queue task_type =
  let result = ref [] in
  Hashtbl.iter (fun _ task ->
    if task.task_type = task_type then
      result := task :: !result
  ) queue.tasks;
  !result

let get_tasks_by_priority queue priority =
  let result = ref [] in
  Hashtbl.iter (fun _ task ->
    if task.priority = priority then
      result := task :: !result
  ) queue.tasks;
  !result

(** Performance monitoring *)
let get_task_statistics queue =
  let pending = List.length (get_pending_tasks queue) in
  let running = List.length (get_running_tasks queue) in
  let completed = List.length (get_completed_tasks queue) in
  let failed = List.length (List.filter (function
    | {status = Failed _; _} -> true
    | _ -> false
  ) (get_completed_tasks queue)) in
  (pending, running, completed, failed)

let get_average_execution_time queue task_type =
  let tasks = get_tasks_by_type queue task_type in
  let completed_tasks = List.filter (fun task ->
    match task.status, task.start_time, task.end_time with
    | Completed, Some start, Some end_ -> true
    | _ -> false
  ) tasks in
  
  if completed_tasks = [] then None
  else
    let total_time = List.fold_left (fun acc task ->
      match task.start_time, task.end_time with
      | Some start, Some end_ -> acc +. (end_ -. start)
      | _ -> acc
    ) 0.0 completed_tasks in
    Some (total_time /. float_of_int (List.length completed_tasks))

(** Scheme representation *)
let priority_to_string = function
  | High -> "high"
  | Medium -> "medium"
  | Low -> "low"

let status_to_string = function
  | Pending -> "pending"
  | Running -> "running"
  | Completed -> "completed"
  | Failed s -> Printf.sprintf "failed \"%s\"" s

let task_type_to_string = function
  | Reasoning_task -> "reasoning"
  | Pattern_matching -> "pattern-matching"
  | Attention_allocation -> "attention-allocation"
  | Memory_consolidation -> "memory-consolidation"
  | Meta_cognition -> "meta-cognition"

let task_to_scheme task =
  let deps_str = String.concat " " (List.map string_of_int task.dependencies) in
  let start_str = match task.start_time with
    | Some t -> Printf.sprintf " (start-time %.3f)" t
    | None -> ""
  in
  let end_str = match task.end_time with
    | Some t -> Printf.sprintf " (end-time %.3f)" t
    | None -> ""
  in
  Printf.sprintf "(task (id %d) (type %s) (priority %s) (status %s) (description \"%s\") (dependencies (%s)) (created %.3f)%s%s)"
    task.id
    (task_type_to_string task.task_type)
    (priority_to_string task.priority)
    (status_to_string task.status)
    task.description
    deps_str
    task.created_time
    start_str
    end_str

let task_queue_to_scheme queue =
  let tasks = ref [] in
  Hashtbl.iter (fun _ task -> tasks := task_to_scheme task :: !tasks) queue.tasks;
  let (pending, running, completed, failed) = get_task_statistics queue in
  Printf.sprintf "(task-queue\n  (max-concurrent %d)\n  (statistics (pending %d) (running %d) (completed %d) (failed %d))\n  (tasks\n    %s))"
    queue.max_concurrent
    pending running completed failed
    (String.concat "\n    " !tasks)