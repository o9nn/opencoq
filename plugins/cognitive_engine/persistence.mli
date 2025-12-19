(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** AtomSpace Persistence Layer Interface *)

(** {1 Backend Types} *)

type backend_type =
  | InMemory
  | FileJSON of string
  | FileBinary of string
  | RocksDB of string
  | SQLite of string

(** {1 Store Management} *)

(** Abstract store type *)
type store

(** Create a new persistence store *)
val create_store : ?auto_save_interval:float -> backend_type -> store

(** Save atomspace to store *)
val save : store -> Hypergraph.atomspace -> unit

(** Load atomspace from store *)
val load : store -> Hypergraph.atomspace

(** {1 Incremental Operations} *)

(** Record node addition *)
val record_add_node : store -> Hypergraph.node -> unit

(** Record node update *)
val record_update_node : store -> Hypergraph.node -> unit

(** Record node deletion *)
val record_delete_node : store -> int -> unit

(** Record link addition *)
val record_add_link : store -> Hypergraph.link -> unit

(** Record link update *)
val record_update_link : store -> Hypergraph.link -> unit

(** Record link deletion *)
val record_delete_link : store -> int -> unit

(** {1 Snapshots} *)

(** Snapshot metadata *)
type snapshot = {
  id: string;
  timestamp: float;
  path: string;
  node_count: int;
  link_count: int;
}

(** Create a snapshot *)
val create_snapshot : store -> Hypergraph.atomspace -> string -> snapshot

(** Restore from snapshot *)
val restore_snapshot : snapshot -> Hypergraph.atomspace

(** {1 Direct File Operations} *)

(** Save to JSON file *)
val save_json : string -> Hypergraph.atomspace -> unit

(** Save to binary file *)
val save_binary : string -> Hypergraph.atomspace -> unit

(** Load from JSON file *)
val load_json : string -> Hypergraph.atomspace

(** Load from binary file *)
val load_binary : string -> Hypergraph.atomspace

(** {1 Statistics} *)

type persistence_stats = {
  total_saves: int;
  total_loads: int;
  wal_operations: int;
  last_save_time: float;
  last_load_time: float;
  bytes_written: int;
  bytes_read: int;
}

(** {1 Serialization} *)

val backend_to_scheme : backend_type -> string
val store_to_scheme : store -> string
val snapshot_to_scheme : snapshot -> string
val stats_to_scheme : unit -> string
