(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** RocksDB Native Bindings for OCaml
    
    This module provides complete native bindings to RocksDB for
    high-performance persistent storage of the AtomSpace hypergraph.
    
    Features:
    - Key-value storage with column families
    - Batch writes for atomic operations
    - Snapshots for consistent reads
    - Compression support (LZ4, Snappy, Zstd)
    - Iterator support for range scans
*)

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

external backend_available : unit -> bool = "caml_rocksdb_backend_available"

let is_native_available () = backend_available ()

(** {1 Column Family Utilities} *)

let cf_to_int = function
  | Default -> 0
  | Nodes -> 1
  | Links -> 2
  | Incoming -> 3
  | Outgoing -> 4
  | Attention -> 5
  | TruthValues -> 6
  | Metadata -> 7

let int_to_cf = function
  | 0 -> Default
  | 1 -> Nodes
  | 2 -> Links
  | 3 -> Incoming
  | 4 -> Outgoing
  | 5 -> Attention
  | 6 -> TruthValues
  | 7 -> Metadata
  | _ -> Default

let cf_name = function
  | Default -> "default"
  | Nodes -> "nodes"
  | Links -> "links"
  | Incoming -> "incoming"
  | Outgoing -> "outgoing"
  | Attention -> "attention"
  | TruthValues -> "truth_values"
  | Metadata -> "metadata"

let compression_to_int = function
  | NoCompression -> 0
  | Snappy -> 1
  | LZ4 -> 2
  | Zstd -> 3

(** {1 Database Management} *)

external open_db_raw : string -> bool -> int -> db = "caml_rocksdb_open"
external close : db -> unit = "caml_rocksdb_close"
external is_open : db -> bool = "caml_rocksdb_is_open"

let open_db ?(create_if_missing=true) ?(compression=LZ4) path =
  open_db_raw path create_if_missing (compression_to_int compression)

(** {1 Basic Operations} *)

external put_raw : db -> int -> string -> string -> unit = "caml_rocksdb_put"
external get_raw : db -> int -> string -> string option = "caml_rocksdb_get"
external delete_raw : db -> int -> string -> unit = "caml_rocksdb_delete"
external exists_raw : db -> int -> string -> bool = "caml_rocksdb_exists"

let put ?(cf=Default) db key value =
  put_raw db (cf_to_int cf) key value

let get ?(cf=Default) db key =
  get_raw db (cf_to_int cf) key

let delete ?(cf=Default) db key =
  delete_raw db (cf_to_int cf) key

let exists ?(cf=Default) db key =
  exists_raw db (cf_to_int cf) key

let get_exn ?(cf=Default) db key =
  match get ~cf db key with
  | Some v -> v
  | None -> failwith "Key not found"

(** {1 Batch Operations} *)

external batch_create : unit -> batch = "caml_rocksdb_batch_create"
external batch_put : batch -> string -> string -> unit = "caml_rocksdb_batch_put"
external batch_delete : batch -> string -> unit = "caml_rocksdb_batch_delete"
external batch_clear : batch -> unit = "caml_rocksdb_batch_clear"
external batch_count : batch -> int = "caml_rocksdb_batch_count"
external batch_write : db -> batch -> unit = "caml_rocksdb_batch_write"
external batch_destroy : batch -> unit = "caml_rocksdb_batch_destroy"

let with_batch db f =
  let batch = batch_create () in
  try
    f batch;
    batch_write db batch;
    batch_destroy batch
  with e ->
    batch_destroy batch;
    raise e

(** {1 Iterator Operations} *)

external iter_create_raw : db -> int -> iterator = "caml_rocksdb_iter_create"
external iter_seek_to_first : iterator -> unit = "caml_rocksdb_iter_seek_to_first"
external iter_seek_to_last : iterator -> unit = "caml_rocksdb_iter_seek_to_last"
external iter_seek : iterator -> string -> unit = "caml_rocksdb_iter_seek"
external iter_next : iterator -> unit = "caml_rocksdb_iter_next"
external iter_prev : iterator -> unit = "caml_rocksdb_iter_prev"
external iter_valid : iterator -> bool = "caml_rocksdb_iter_valid"
external iter_key : iterator -> string = "caml_rocksdb_iter_key"
external iter_value : iterator -> string = "caml_rocksdb_iter_value"
external iter_destroy : iterator -> unit = "caml_rocksdb_iter_destroy"

let iter_create ?(cf=Default) db =
  iter_create_raw db (cf_to_int cf)

let iter_fold ?(cf=Default) db ~init ~f =
  let iter = iter_create ~cf db in
  iter_seek_to_first iter;
  let rec loop acc =
    if iter_valid iter then begin
      let key = iter_key iter in
      let value = iter_value iter in
      iter_next iter;
      loop (f acc key value)
    end else
      acc
  in
  let result = loop init in
  iter_destroy iter;
  result

let iter_keys ?(cf=Default) db =
  iter_fold ~cf db ~init:[] ~f:(fun acc key _ -> key :: acc)
  |> List.rev

let iter_values ?(cf=Default) db =
  iter_fold ~cf db ~init:[] ~f:(fun acc _ value -> value :: acc)
  |> List.rev

let iter_pairs ?(cf=Default) db =
  iter_fold ~cf db ~init:[] ~f:(fun acc key value -> (key, value) :: acc)
  |> List.rev

let iter_range ?(cf=Default) db ~start_key ~end_key =
  let iter = iter_create ~cf db in
  iter_seek iter start_key;
  let rec loop acc =
    if iter_valid iter then begin
      let key = iter_key iter in
      if key <= end_key then begin
        let value = iter_value iter in
        iter_next iter;
        loop ((key, value) :: acc)
      end else
        acc
    end else
      acc
  in
  let result = loop [] |> List.rev in
  iter_destroy iter;
  result

(** {1 Snapshot Operations} *)

external snapshot_create : db -> snapshot = "caml_rocksdb_snapshot_create"
external snapshot_release : snapshot -> unit = "caml_rocksdb_snapshot_release"

let with_snapshot db f =
  let snap = snapshot_create db in
  try
    let result = f snap in
    snapshot_release snap;
    result
  with e ->
    snapshot_release snap;
    raise e

(** {1 Statistics and Utilities} *)

external get_property : db -> string -> string option = "caml_rocksdb_get_property"
external compact_range_raw : db -> int -> unit = "caml_rocksdb_compact_range"
external flush : db -> unit = "caml_rocksdb_flush"

let compact_range ?(cf=Default) db =
  compact_range_raw db (cf_to_int cf)

let compact_all db =
  List.iter (fun cf -> compact_range ~cf db) 
    [Default; Nodes; Links; Incoming; Outgoing; Attention; TruthValues; Metadata]

(** Get database statistics *)
let get_stats db =
  let props = [
    "rocksdb.stats";
    "rocksdb.sstables";
    "rocksdb.num-files-at-level0";
    "rocksdb.num-files-at-level1";
    "rocksdb.num-files-at-level2";
    "rocksdb.estimate-num-keys";
    "rocksdb.estimate-live-data-size";
    "rocksdb.total-sst-files-size";
  ] in
  List.filter_map (fun prop ->
    match get_property db prop with
    | Some v -> Some (prop, v)
    | None -> None
  ) props

(** {1 AtomSpace-Specific Operations} *)

(** Encode node ID as key *)
let encode_node_key id =
  Printf.sprintf "n:%08x" id

(** Decode node ID from key *)
let decode_node_key key =
  Scanf.sscanf key "n:%x" (fun id -> id)

(** Encode link ID as key *)
let encode_link_key id =
  Printf.sprintf "l:%08x" id

(** Decode link ID from key *)
let decode_link_key key =
  Scanf.sscanf key "l:%x" (fun id -> id)

(** Store a node *)
let store_node db id data =
  put ~cf:Nodes db (encode_node_key id) data

(** Load a node *)
let load_node db id =
  get ~cf:Nodes db (encode_node_key id)

(** Store a link *)
let store_link db id data =
  put ~cf:Links db (encode_link_key id) data

(** Load a link *)
let load_link db id =
  get ~cf:Links db (encode_link_key id)

(** Store incoming set for a node *)
let store_incoming db node_id incoming_ids =
  let key = encode_node_key node_id in
  let value = String.concat "," (List.map string_of_int incoming_ids) in
  put ~cf:Incoming db key value

(** Load incoming set for a node *)
let load_incoming db node_id =
  let key = encode_node_key node_id in
  match get ~cf:Incoming db key with
  | Some v when v <> "" -> 
    String.split_on_char ',' v |> List.map int_of_string
  | _ -> []

(** Store outgoing set for a link *)
let store_outgoing db link_id outgoing_ids =
  let key = encode_link_key link_id in
  let value = String.concat "," (List.map string_of_int outgoing_ids) in
  put ~cf:Outgoing db key value

(** Load outgoing set for a link *)
let load_outgoing db link_id =
  let key = encode_link_key link_id in
  match get ~cf:Outgoing db key with
  | Some v when v <> "" -> 
    String.split_on_char ',' v |> List.map int_of_string
  | _ -> []

(** Store attention value *)
let store_attention db atom_id sti lti vlti =
  let key = Printf.sprintf "a:%08x" atom_id in
  let value = Printf.sprintf "%.6f,%.6f,%b" sti lti vlti in
  put ~cf:Attention db key value

(** Load attention value *)
let load_attention db atom_id =
  let key = Printf.sprintf "a:%08x" atom_id in
  match get ~cf:Attention db key with
  | Some v ->
    (try
      Scanf.sscanf v "%f,%f,%b" (fun sti lti vlti -> Some (sti, lti, vlti))
    with _ -> None)
  | None -> None

(** Store truth value *)
let store_truth_value db atom_id strength confidence =
  let key = Printf.sprintf "t:%08x" atom_id in
  let value = Printf.sprintf "%.6f,%.6f" strength confidence in
  put ~cf:TruthValues db key value

(** Load truth value *)
let load_truth_value db atom_id =
  let key = Printf.sprintf "t:%08x" atom_id in
  match get ~cf:TruthValues db key with
  | Some v ->
    (try
      Scanf.sscanf v "%f,%f" (fun s c -> Some (s, c))
    with _ -> None)
  | None -> None

(** Store metadata *)
let store_metadata db key value =
  put ~cf:Metadata db key value

(** Load metadata *)
let load_metadata db key =
  get ~cf:Metadata db key

(** {1 Scheme Serialization} *)

let compression_to_scheme = function
  | NoCompression -> "none"
  | Snappy -> "snappy"
  | LZ4 -> "lz4"
  | Zstd -> "zstd"

let cf_to_scheme cf =
  Printf.sprintf "(column-family %s)" (cf_name cf)

let db_to_scheme db =
  Printf.sprintf "(rocksdb (open %b))" (is_open db)

let stats_to_scheme stats =
  let items = List.map (fun (k, v) ->
    Printf.sprintf "(%s \"%s\")" k v
  ) stats in
  Printf.sprintf "(rocksdb-stats %s)" (String.concat " " items)
