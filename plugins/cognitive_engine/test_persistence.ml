(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** Test Suite for AtomSpace Persistence Layer *)

open Persistence

(** Test utilities *)
let test_count = ref 0
let pass_count = ref 0
let fail_count = ref 0

let assert_true condition name =
  incr test_count;
  if condition then begin
    incr pass_count;
    Printf.printf "  ✅ %s\n" name
  end else begin
    incr fail_count;
    Printf.printf "  ❌ %s\n" name
  end

let assert_eq expected actual name =
  incr test_count;
  if expected = actual then begin
    incr pass_count;
    Printf.printf "  ✅ %s\n" name
  end else begin
    incr fail_count;
    Printf.printf "  ❌ %s\n" name
  end

let section name =
  Printf.printf "\n=== %s ===\n" name

(** Test cases *)

let test_backend_types () =
  section "Backend Types";
  
  let backends = [
    InMemory;
    FileJSON "/tmp/test.json";
    FileBinary "/tmp/test.bin";
    RocksDB "/tmp/rocksdb";
    SQLite "/tmp/test.db";
  ] in
  
  List.iter (fun backend ->
    let scheme = backend_to_scheme backend in
    Printf.printf "  ℹ️  %s\n" scheme;
    assert_true (String.length scheme > 0) "backend serializes"
  ) backends

let test_store_creation () =
  section "Store Creation";
  
  let store1 = create_store InMemory in
  let scheme1 = store_to_scheme store1 in
  Printf.printf "  ℹ️  In-memory store: %s\n" scheme1;
  assert_true (String.length scheme1 > 0) "in-memory store created";
  
  let store2 = create_store ~auto_save_interval:30.0 (FileJSON "/tmp/test.json") in
  let scheme2 = store_to_scheme store2 in
  Printf.printf "  ℹ️  JSON store: %s\n" scheme2;
  assert_true (String.length scheme2 > 0) "JSON store created"

let test_json_serialization () =
  section "JSON Serialization";
  
  (* Test JSON escape *)
  let test_strings = [
    ("simple", "simple");
    ("with\"quote", "with\\\"quote");
    ("with\nnewline", "with\\nnewline");
    ("with\\backslash", "with\\\\backslash");
  ] in
  
  List.iter (fun (input, expected) ->
    let escaped = JSON.escape_string input in
    if escaped = expected then
      Printf.printf "  ✅ escape \"%s\" -> \"%s\"\n" input escaped
    else
      Printf.printf "  ❌ escape \"%s\": expected \"%s\", got \"%s\"\n" input expected escaped
  ) test_strings;
  
  (* Test node serialization *)
  let node = {
    sn_id = 1;
    sn_node_type = "ConceptNode";
    sn_name = "test";
    sn_strength = 0.8;
    sn_confidence = 0.9;
    sn_sti = 100.0;
    sn_lti = 50.0;
    sn_vlti = false;
  } in
  let json = JSON.node_to_json node in
  Printf.printf "  ℹ️  Node JSON: %s\n" json;
  assert_true (String.length json > 0) "node serializes to JSON"

let test_binary_serialization () =
  section "Binary Serialization";
  
  (* Test int32 write/read *)
  let buf = Buffer.create 16 in
  Binary.write_int32 buf 12345;
  let s = Buffer.contents buf in
  let read_val = Binary.read_int32 s 0 in
  assert_eq 12345 read_val "int32 roundtrip";
  
  (* Test float64 write/read *)
  let buf2 = Buffer.create 16 in
  Binary.write_float64 buf2 3.14159;
  let s2 = Buffer.contents buf2 in
  let read_float = Binary.read_float64 s2 0 in
  let diff = abs_float (read_float -. 3.14159) in
  assert_true (diff < 0.00001) "float64 roundtrip"

let test_wal_operations () =
  section "Write-Ahead Log";
  
  let wal = WAL.create () in
  
  let node = {
    sn_id = 1;
    sn_node_type = "ConceptNode";
    sn_name = "test";
    sn_strength = 0.8;
    sn_confidence = 0.9;
    sn_sti = 100.0;
    sn_lti = 50.0;
    sn_vlti = false;
  } in
  
  WAL.append wal (WAL.AddNode node);
  assert_eq 1 wal.sequence "WAL sequence incremented";
  
  WAL.append wal (WAL.UpdateNode node);
  assert_eq 2 wal.sequence "WAL sequence incremented again";
  
  WAL.checkpoint wal;
  assert_true (List.length wal.operations = 1) "checkpoint clears old ops"

let test_snapshot_creation () =
  section "Snapshot Creation";
  
  let store = create_store InMemory in
  let atomspace = Hypergraph.create () in
  
  (* Add some data *)
  let _ = Hypergraph.add_node atomspace Hypergraph.Concept "TestNode" in
  
  let snapshot = create_snapshot store atomspace "test_snapshot" in
  
  Printf.printf "  ℹ️  Snapshot ID: %s\n" snapshot.id;
  Printf.printf "  ℹ️  Snapshot path: %s\n" snapshot.path;
  Printf.printf "  ℹ️  Timestamp: %.3f\n" snapshot.timestamp;
  
  assert_true (String.length snapshot.id > 0) "snapshot has ID";
  assert_true (snapshot.timestamp > 0.0) "snapshot has timestamp"

let test_snapshot_serialization () =
  section "Snapshot Serialization";
  
  let snapshot = {
    id = "test_123";
    timestamp = 1703000000.0;
    path = "/tmp/snapshot.json";
    node_count = 100;
    link_count = 50;
  } in
  
  let scheme = snapshot_to_scheme snapshot in
  Printf.printf "  ℹ️  Snapshot Scheme: %s\n" scheme;
  assert_true (String.sub scheme 0 9 = "(snapshot") "snapshot serialization starts correctly"

let test_stats_serialization () =
  section "Statistics Serialization";
  
  let scheme = stats_to_scheme () in
  Printf.printf "  ℹ️  Stats Scheme: %s\n" scheme;
  assert_true (String.sub scheme 0 18 = "(persistence-stats") "stats serialization starts correctly"

let test_atomspace_serialization () =
  section "AtomSpace Serialization";
  
  let atomspace = Hypergraph.create () in
  
  (* Add nodes *)
  let n1 = Hypergraph.add_node atomspace Hypergraph.Concept "Node1" in
  let n2 = Hypergraph.add_node atomspace Hypergraph.Concept "Node2" in
  
  (* Add link *)
  let _ = Hypergraph.add_link atomspace Hypergraph.Implication [n1; n2] in
  
  (* Serialize *)
  let serialized = serialize_atomspace atomspace in
  
  Printf.printf "  ℹ️  Version: %s\n" serialized.version;
  Printf.printf "  ℹ️  Node count: %d\n" serialized.node_count;
  Printf.printf "  ℹ️  Link count: %d\n" serialized.link_count;
  
  assert_eq 2 serialized.node_count "correct node count";
  assert_eq 1 serialized.link_count "correct link count"

let test_json_file_operations () =
  section "JSON File Operations";
  
  let atomspace = Hypergraph.create () in
  let _ = Hypergraph.add_node atomspace Hypergraph.Concept "TestNode" in
  
  let path = "/tmp/test_atomspace.json" in
  
  (* Save *)
  save_json path atomspace;
  assert_true (Sys.file_exists path) "JSON file created";
  
  (* Check file content *)
  let ic = open_in path in
  let content = really_input_string ic (in_channel_length ic) in
  close_in ic;
  Printf.printf "  ℹ️  JSON file size: %d bytes\n" (String.length content);
  assert_true (String.length content > 0) "JSON file has content";
  
  (* Cleanup *)
  Sys.remove path

let test_incremental_operations () =
  section "Incremental Operations";
  
  let store = create_store InMemory in
  
  let node : Hypergraph.node = {
    id = 1;
    node_type = Hypergraph.Concept;
    name = "TestNode";
    strength = 0.8;
    confidence = 0.9;
    attention = { sti = 100.0; lti = 50.0; vlti = false };
    incoming = [];
    outgoing = [];
  } in
  
  record_add_node store node;
  assert_eq 1 store.wal.sequence "add node recorded";
  
  record_update_node store node;
  assert_eq 2 store.wal.sequence "update node recorded";
  
  record_delete_node store 1;
  assert_eq 3 store.wal.sequence "delete node recorded"

let () =
  Printf.printf "\n";
  Printf.printf "╔══════════════════════════════════════════════════════════╗\n";
  Printf.printf "║     AtomSpace Persistence - Test Suite                   ║\n";
  Printf.printf "╚══════════════════════════════════════════════════════════╝\n";
  
  test_backend_types ();
  test_store_creation ();
  test_json_serialization ();
  test_binary_serialization ();
  test_wal_operations ();
  test_snapshot_creation ();
  test_snapshot_serialization ();
  test_stats_serialization ();
  test_atomspace_serialization ();
  test_json_file_operations ();
  test_incremental_operations ();
  
  Printf.printf "\n";
  Printf.printf "╔══════════════════════════════════════════════════════════╗\n";
  Printf.printf "║                    Test Summary                          ║\n";
  Printf.printf "╠══════════════════════════════════════════════════════════╣\n";
  Printf.printf "║  Total:  %3d                                             ║\n" !test_count;
  Printf.printf "║  Passed: %3d                                             ║\n" !pass_count;
  Printf.printf "║  Failed: %3d                                             ║\n" !fail_count;
  Printf.printf "╚══════════════════════════════════════════════════════════╝\n";
  
  if !fail_count = 0 then
    Printf.printf "\n💾 All persistence tests passed! 💾\n\n"
  else
    Printf.printf "\n⚠️  Some tests failed. Please review. ⚠️\n\n"
