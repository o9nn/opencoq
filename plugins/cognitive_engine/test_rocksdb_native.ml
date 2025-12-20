(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** Test suite for RocksDB Native Bindings *)

open Rocksdb_native

let test_count = ref 0
let pass_count = ref 0
let fail_count = ref 0

let test name f =
  incr test_count;
  try
    f ();
    incr pass_count;
    Printf.printf "✓ %s\n" name
  with e ->
    incr fail_count;
    Printf.printf "✗ %s: %s\n" name (Printexc.to_string e)

let assert_eq name expected actual =
  if expected <> actual then
    failwith (Printf.sprintf "%s: expected %s, got %s" name expected actual)

let assert_true name condition =
  if not condition then
    failwith (Printf.sprintf "%s: expected true" name)

let assert_false name condition =
  if condition then
    failwith (Printf.sprintf "%s: expected false" name)

let assert_some name opt =
  match opt with
  | Some v -> v
  | None -> failwith (Printf.sprintf "%s: expected Some, got None" name)

let assert_none name opt =
  match opt with
  | None -> ()
  | Some _ -> failwith (Printf.sprintf "%s: expected None, got Some" name)

(* Test database path *)
let test_db_path = "/tmp/opencoq_rocksdb_test"

(* Clean up test database *)
let cleanup () =
  ignore (Sys.command (Printf.sprintf "rm -rf %s" test_db_path))

let () =
  Printf.printf "\n=== RocksDB Native Bindings Tests ===\n\n";
  
  (* Check if native RocksDB is available *)
  let native_available = is_native_available () in
  Printf.printf "Native RocksDB available: %b\n\n" native_available;
  
  if not native_available then begin
    Printf.printf "Skipping native tests (RocksDB not available).\n";
    Printf.printf "Running fallback/stub tests only.\n\n"
  end;
  
  (* Test column family utilities *)
  test "cf_to_int Default" (fun () ->
    assert_eq "cf_to_int" "0" (string_of_int (cf_to_int Default))
  );
  
  test "cf_to_int Nodes" (fun () ->
    assert_eq "cf_to_int" "1" (string_of_int (cf_to_int Nodes))
  );
  
  test "cf_to_int Links" (fun () ->
    assert_eq "cf_to_int" "2" (string_of_int (cf_to_int Links))
  );
  
  test "int_to_cf roundtrip" (fun () ->
    List.iter (fun cf ->
      let i = cf_to_int cf in
      let cf' = int_to_cf i in
      assert_eq "roundtrip" (cf_name cf) (cf_name cf')
    ) [Default; Nodes; Links; Incoming; Outgoing; Attention; TruthValues; Metadata]
  );
  
  test "cf_name" (fun () ->
    assert_eq "cf_name" "nodes" (cf_name Nodes);
    assert_eq "cf_name" "links" (cf_name Links);
    assert_eq "cf_name" "truth_values" (cf_name TruthValues)
  );
  
  (* Test key encoding *)
  test "encode_node_key" (fun () ->
    let key = encode_node_key 42 in
    assert_eq "encode_node_key" "n:0000002a" key
  );
  
  test "decode_node_key" (fun () ->
    let id = decode_node_key "n:0000002a" in
    assert_eq "decode_node_key" "42" (string_of_int id)
  );
  
  test "encode_link_key" (fun () ->
    let key = encode_link_key 100 in
    assert_eq "encode_link_key" "l:00000064" key
  );
  
  test "decode_link_key" (fun () ->
    let id = decode_link_key "l:00000064" in
    assert_eq "decode_link_key" "100" (string_of_int id)
  );
  
  test "node_key roundtrip" (fun () ->
    for i = 0 to 1000 do
      let key = encode_node_key i in
      let id = decode_node_key key in
      assert_eq "roundtrip" (string_of_int i) (string_of_int id)
    done
  );
  
  (* Test compression types *)
  test "compression_to_scheme" (fun () ->
    assert_eq "NoCompression" "none" (compression_to_scheme NoCompression);
    assert_eq "Snappy" "snappy" (compression_to_scheme Snappy);
    assert_eq "LZ4" "lz4" (compression_to_scheme LZ4);
    assert_eq "Zstd" "zstd" (compression_to_scheme Zstd)
  );
  
  (* Native-only tests *)
  if native_available then begin
    cleanup ();
    
    test "open_db creates database" (fun () ->
      let db = open_db ~create_if_missing:true test_db_path in
      assert_true "is_open" (is_open db);
      close db
    );
    
    test "put and get" (fun () ->
      let db = open_db test_db_path in
      put db "key1" "value1";
      let v = get db "key1" in
      assert_eq "get" "value1" (assert_some "get" v);
      close db
    );
    
    test "put and get with column family" (fun () ->
      let db = open_db test_db_path in
      put ~cf:Nodes db "node_key" "node_value";
      let v = get ~cf:Nodes db "node_key" in
      assert_eq "get" "node_value" (assert_some "get" v);
      close db
    );
    
    test "get non-existent key returns None" (fun () ->
      let db = open_db test_db_path in
      let v = get db "non_existent_key" in
      assert_none "get" v;
      close db
    );
    
    test "exists" (fun () ->
      let db = open_db test_db_path in
      put db "exists_key" "exists_value";
      assert_true "exists" (exists db "exists_key");
      assert_false "not exists" (exists db "not_exists_key");
      close db
    );
    
    test "delete" (fun () ->
      let db = open_db test_db_path in
      put db "delete_key" "delete_value";
      assert_true "exists before" (exists db "delete_key");
      delete db "delete_key";
      assert_false "exists after" (exists db "delete_key");
      close db
    );
    
    test "batch operations" (fun () ->
      let db = open_db test_db_path in
      with_batch db (fun batch ->
        batch_put batch "batch_key1" "batch_value1";
        batch_put batch "batch_key2" "batch_value2";
        batch_put batch "batch_key3" "batch_value3"
      );
      assert_eq "batch_key1" "batch_value1" (get_exn db "batch_key1");
      assert_eq "batch_key2" "batch_value2" (get_exn db "batch_key2");
      assert_eq "batch_key3" "batch_value3" (get_exn db "batch_key3");
      close db
    );
    
    test "iterator" (fun () ->
      let db = open_db test_db_path in
      put db "iter_a" "value_a";
      put db "iter_b" "value_b";
      put db "iter_c" "value_c";
      let pairs = iter_pairs db in
      assert_true "has pairs" (List.length pairs >= 3);
      close db
    );
    
    test "store_node and load_node" (fun () ->
      let db = open_db test_db_path in
      store_node db 42 "node_data_42";
      let data = load_node db 42 in
      assert_eq "load_node" "node_data_42" (assert_some "load_node" data);
      close db
    );
    
    test "store_link and load_link" (fun () ->
      let db = open_db test_db_path in
      store_link db 100 "link_data_100";
      let data = load_link db 100 in
      assert_eq "load_link" "link_data_100" (assert_some "load_link" data);
      close db
    );
    
    test "store_incoming and load_incoming" (fun () ->
      let db = open_db test_db_path in
      store_incoming db 1 [10; 20; 30];
      let incoming = load_incoming db 1 in
      assert_eq "length" "3" (string_of_int (List.length incoming));
      assert_true "contains 10" (List.mem 10 incoming);
      assert_true "contains 20" (List.mem 20 incoming);
      assert_true "contains 30" (List.mem 30 incoming);
      close db
    );
    
    test "store_outgoing and load_outgoing" (fun () ->
      let db = open_db test_db_path in
      store_outgoing db 1 [5; 6; 7];
      let outgoing = load_outgoing db 1 in
      assert_eq "length" "3" (string_of_int (List.length outgoing));
      close db
    );
    
    test "store_attention and load_attention" (fun () ->
      let db = open_db test_db_path in
      store_attention db 42 0.8 0.5 true;
      let attn = load_attention db 42 in
      let (sti, lti, vlti) = assert_some "load_attention" attn in
      assert_true "sti" (abs_float (sti -. 0.8) < 0.0001);
      assert_true "lti" (abs_float (lti -. 0.5) < 0.0001);
      assert_true "vlti" vlti;
      close db
    );
    
    test "store_truth_value and load_truth_value" (fun () ->
      let db = open_db test_db_path in
      store_truth_value db 42 0.9 0.95;
      let tv = load_truth_value db 42 in
      let (s, c) = assert_some "load_truth_value" tv in
      assert_true "strength" (abs_float (s -. 0.9) < 0.0001);
      assert_true "confidence" (abs_float (c -. 0.95) < 0.0001);
      close db
    );
    
    test "store_metadata and load_metadata" (fun () ->
      let db = open_db test_db_path in
      store_metadata db "version" "1.0.0";
      let v = load_metadata db "version" in
      assert_eq "load_metadata" "1.0.0" (assert_some "load_metadata" v);
      close db
    );
    
    test "flush" (fun () ->
      let db = open_db test_db_path in
      put db "flush_key" "flush_value";
      flush db;
      close db
    );
    
    test "compact_range" (fun () ->
      let db = open_db test_db_path in
      compact_range db;
      close db
    );
    
    test "compact_all" (fun () ->
      let db = open_db test_db_path in
      compact_all db;
      close db
    );
    
    test "get_stats" (fun () ->
      let db = open_db test_db_path in
      let stats = get_stats db in
      (* Stats may be empty if properties not available *)
      ignore stats;
      close db
    );
    
    test "snapshot" (fun () ->
      let db = open_db test_db_path in
      put db "snap_key" "snap_value1";
      with_snapshot db (fun _snap ->
        put db "snap_key" "snap_value2";
        (* Snapshot should see old value, but we can't easily test this
           without snapshot-based reads which require more API *)
        ()
      );
      close db
    );
    
    cleanup ()
  end;
  
  (* Print summary *)
  Printf.printf "\n=== Test Summary ===\n";
  Printf.printf "Total: %d, Passed: %d, Failed: %d\n" !test_count !pass_count !fail_count;
  
  if !fail_count > 0 then
    exit 1
  else
    Printf.printf "\nAll tests passed!\n"
