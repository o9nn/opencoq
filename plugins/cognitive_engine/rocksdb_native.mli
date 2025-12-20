(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** RocksDB Native Bindings Interface *)

(** {1 Types} *)

(** Compression types *)
type compression =
  | NoCompression
  | Snappy
  | LZ4
  | Zstd

(** Column families for AtomSpace storage *)
type column_family =
  | Default
  | Nodes
  | Links
  | Incoming
  | Outgoing
  | Attention
  | TruthValues
  | Metadata

(** Opaque database handle *)
type db

(** Opaque batch handle *)
type batch

(** Opaque iterator handle *)
type iterator

(** Opaque snapshot handle *)
type snapshot

(** {1 Backend Detection} *)

(** Check if native RocksDB is available *)
val is_native_available : unit -> bool

(** {1 Column Family Utilities} *)

val cf_to_int : column_family -> int
val int_to_cf : int -> column_family
val cf_name : column_family -> string

(** {1 Database Management} *)

(** Open a database *)
val open_db : ?create_if_missing:bool -> ?compression:compression -> string -> db

(** Close a database *)
val close : db -> unit

(** Check if database is open *)
val is_open : db -> bool

(** {1 Basic Operations} *)

(** Put a key-value pair *)
val put : ?cf:column_family -> db -> string -> string -> unit

(** Get a value by key *)
val get : ?cf:column_family -> db -> string -> string option

(** Get a value by key, raising exception if not found *)
val get_exn : ?cf:column_family -> db -> string -> string

(** Delete a key *)
val delete : ?cf:column_family -> db -> string -> unit

(** Check if a key exists *)
val exists : ?cf:column_family -> db -> string -> bool

(** {1 Batch Operations} *)

(** Create a new batch *)
val batch_create : unit -> batch

(** Add a put operation to batch *)
val batch_put : batch -> string -> string -> unit

(** Add a delete operation to batch *)
val batch_delete : batch -> string -> unit

(** Clear all operations from batch *)
val batch_clear : batch -> unit

(** Get number of operations in batch *)
val batch_count : batch -> int

(** Write batch to database *)
val batch_write : db -> batch -> unit

(** Destroy batch *)
val batch_destroy : batch -> unit

(** Execute function with batch, auto-write and cleanup *)
val with_batch : db -> (batch -> unit) -> unit

(** {1 Iterator Operations} *)

(** Create an iterator *)
val iter_create : ?cf:column_family -> db -> iterator

(** Seek to first key *)
val iter_seek_to_first : iterator -> unit

(** Seek to last key *)
val iter_seek_to_last : iterator -> unit

(** Seek to specific key *)
val iter_seek : iterator -> string -> unit

(** Move to next key *)
val iter_next : iterator -> unit

(** Move to previous key *)
val iter_prev : iterator -> unit

(** Check if iterator is valid *)
val iter_valid : iterator -> bool

(** Get current key *)
val iter_key : iterator -> string

(** Get current value *)
val iter_value : iterator -> string

(** Destroy iterator *)
val iter_destroy : iterator -> unit

(** Fold over all key-value pairs *)
val iter_fold : ?cf:column_family -> db -> init:'a -> f:('a -> string -> string -> 'a) -> 'a

(** Get all keys *)
val iter_keys : ?cf:column_family -> db -> string list

(** Get all values *)
val iter_values : ?cf:column_family -> db -> string list

(** Get all key-value pairs *)
val iter_pairs : ?cf:column_family -> db -> (string * string) list

(** Get key-value pairs in range *)
val iter_range : ?cf:column_family -> db -> start_key:string -> end_key:string -> (string * string) list

(** {1 Snapshot Operations} *)

(** Create a snapshot *)
val snapshot_create : db -> snapshot

(** Release a snapshot *)
val snapshot_release : snapshot -> unit

(** Execute function with snapshot, auto-release *)
val with_snapshot : db -> (snapshot -> 'a) -> 'a

(** {1 Statistics and Utilities} *)

(** Get a database property *)
val get_property : db -> string -> string option

(** Compact a column family *)
val compact_range : ?cf:column_family -> db -> unit

(** Compact all column families *)
val compact_all : db -> unit

(** Flush database to disk *)
val flush : db -> unit

(** Get database statistics *)
val get_stats : db -> (string * string) list

(** {1 AtomSpace-Specific Operations} *)

(** Encode node ID as key *)
val encode_node_key : int -> string

(** Decode node ID from key *)
val decode_node_key : string -> int

(** Encode link ID as key *)
val encode_link_key : int -> string

(** Decode link ID from key *)
val decode_link_key : string -> int

(** Store a node *)
val store_node : db -> int -> string -> unit

(** Load a node *)
val load_node : db -> int -> string option

(** Store a link *)
val store_link : db -> int -> string -> unit

(** Load a link *)
val load_link : db -> int -> string option

(** Store incoming set for a node *)
val store_incoming : db -> int -> int list -> unit

(** Load incoming set for a node *)
val load_incoming : db -> int -> int list

(** Store outgoing set for a link *)
val store_outgoing : db -> int -> int list -> unit

(** Load outgoing set for a link *)
val load_outgoing : db -> int -> int list

(** Store attention value *)
val store_attention : db -> int -> float -> float -> bool -> unit

(** Load attention value *)
val load_attention : db -> int -> (float * float * bool) option

(** Store truth value *)
val store_truth_value : db -> int -> float -> float -> unit

(** Load truth value *)
val load_truth_value : db -> int -> (float * float) option

(** Store metadata *)
val store_metadata : db -> string -> string -> unit

(** Load metadata *)
val load_metadata : db -> string -> string option

(** {1 Scheme Serialization} *)

val compression_to_scheme : compression -> string
val cf_to_scheme : column_family -> string
val db_to_scheme : db -> string
val stats_to_scheme : (string * string) list -> string
