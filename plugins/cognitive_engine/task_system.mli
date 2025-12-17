(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** Task System for Distributed Cognitive Operations *)

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
val create_task_queue : int -> task_queue

(** Task management operations *)
val add_task : task_queue -> task_type -> priority -> string -> 
               Hypergraph.atomspace -> task_id list -> (unit -> unit) -> task_id

val get_task : task_queue -> task_id -> cognitive_task option

val remove_task : task_queue -> task_id -> unit

val update_task_status : task_queue -> task_id -> task_status -> unit

(** Task scheduling operations *)
val schedule_next_tasks : task_queue -> task_id list

val execute_task : task_queue -> task_id -> unit

val process_queue : task_queue -> int -> unit

(** Query operations *)
val get_pending_tasks : task_queue -> cognitive_task list

val get_running_tasks : task_queue -> cognitive_task list

val get_completed_tasks : task_queue -> cognitive_task list

val get_tasks_by_type : task_queue -> task_type -> cognitive_task list

val get_tasks_by_priority : task_queue -> priority -> cognitive_task list

(** Task dependency management *)
val check_dependencies : task_queue -> task_id -> bool

val get_ready_tasks : task_queue -> task_id list

(** Performance monitoring *)
val get_task_statistics : task_queue -> (int * int * int * int) (** pending, running, completed, failed *)

val get_average_execution_time : task_queue -> task_type -> float option

(** Scheme representation *)
val task_to_scheme : cognitive_task -> string

val task_queue_to_scheme : task_queue -> string