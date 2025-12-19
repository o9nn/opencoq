(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** Test Suite for PLN Inference Caching *)

open Pln_formulas
open Pln_cache

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
    Printf.printf "  ❌ %s: expected %d, got %d\n" name expected actual
  end

let assert_float_eq ?(eps=0.001) expected actual name =
  incr test_count;
  if abs_float (expected -. actual) < eps then begin
    incr pass_count;
    Printf.printf "  ✅ %s: %.4f ≈ %.4f\n" name expected actual
  end else begin
    incr fail_count;
    Printf.printf "  ❌ %s: expected %.4f, got %.4f\n" name expected actual
  end

let section name =
  Printf.printf "\n=== %s ===\n" name

(** Mock atomspace for testing *)
let mock_atomspace = ()

(** Mock compute functions *)
let mock_deduction _ p1 p2 =
  Some (p1 + p2, { strength = 0.8; confidence = 0.7 })

let mock_conjunction _ n1 n2 =
  { strength = 0.6; confidence = 0.5 }

(** Test cases *)

let test_cache_creation () =
  section "Cache Creation";
  
  let cache = create () in
  assert_eq 0 (size cache) "empty cache has size 0";
  
  let stats = get_stats cache in
  assert_eq 0 stats.hits "initial hits = 0";
  assert_eq 0 stats.misses "initial misses = 0";
  
  let cache2 = create ~max_size:100 ~ttl:60.0 () in
  assert_eq 0 (size cache2) "custom cache has size 0"

let test_cache_hit_miss () =
  section "Cache Hit/Miss";
  
  let cache = create () in
  
  (* First call should be a miss *)
  let _ = cached_deduction cache mock_atomspace 1 2 mock_deduction in
  let stats = get_stats cache in
  assert_eq 1 stats.misses "first call is miss";
  assert_eq 0 stats.hits "no hits yet";
  
  (* Second call with same args should be a hit *)
  let _ = cached_deduction cache mock_atomspace 1 2 mock_deduction in
  let stats = get_stats cache in
  assert_eq 1 stats.hits "second call is hit";
  assert_eq 1 stats.misses "still one miss";
  
  (* Different args should be a miss *)
  let _ = cached_deduction cache mock_atomspace 3 4 mock_deduction in
  let stats = get_stats cache in
  assert_eq 1 stats.hits "still one hit";
  assert_eq 2 stats.misses "now two misses"

let test_hit_rate () =
  section "Hit Rate Calculation";
  
  let cache = create () in
  
  (* No queries yet *)
  assert_float_eq 0.0 (hit_rate cache) "initial hit rate is 0";
  
  (* Add some queries *)
  let _ = cached_deduction cache mock_atomspace 1 2 mock_deduction in
  let _ = cached_deduction cache mock_atomspace 1 2 mock_deduction in
  let _ = cached_deduction cache mock_atomspace 1 2 mock_deduction in
  
  (* 2 hits out of 3 queries *)
  assert_float_eq 0.666 (hit_rate cache) "hit rate after 3 queries"

let test_invalidation () =
  section "Cache Invalidation";
  
  let cache = create () in
  
  (* Populate cache *)
  let _ = cached_deduction cache mock_atomspace 1 2 mock_deduction in
  let _ = cached_deduction cache mock_atomspace 1 3 mock_deduction in
  let _ = cached_deduction cache mock_atomspace 2 3 mock_deduction in
  
  assert_eq 3 (size cache) "cache has 3 entries";
  
  (* Invalidate entries depending on atom 1 *)
  invalidate cache 1;
  
  (* Entries (1,2) and (1,3) should be removed *)
  assert_eq 1 (size cache) "cache has 1 entry after invalidation";
  
  let stats = get_stats cache in
  assert_eq 2 stats.invalidations "2 invalidations recorded"

let test_invalidate_all () =
  section "Invalidate All";
  
  let cache = create () in
  
  (* Populate cache *)
  let _ = cached_deduction cache mock_atomspace 1 2 mock_deduction in
  let _ = cached_deduction cache mock_atomspace 3 4 mock_deduction in
  let _ = cached_deduction cache mock_atomspace 5 6 mock_deduction in
  
  assert_eq 3 (size cache) "cache has 3 entries";
  
  invalidate_all cache;
  
  assert_eq 0 (size cache) "cache is empty after invalidate_all";
  
  let stats = get_stats cache in
  assert_eq 3 stats.invalidations "3 invalidations recorded"

let test_different_operations () =
  section "Different Operation Types";
  
  let cache = create () in
  
  (* Test different cached operations *)
  let _ = cached_deduction cache mock_atomspace 1 2 mock_deduction in
  let _ = cached_conjunction cache mock_atomspace 1 2 mock_conjunction in
  
  (* Same args but different operations should be separate entries *)
  assert_eq 2 (size cache) "different ops create separate entries";
  
  (* Verify both can be retrieved *)
  let _ = cached_deduction cache mock_atomspace 1 2 mock_deduction in
  let _ = cached_conjunction cache mock_atomspace 1 2 mock_conjunction in
  
  let stats = get_stats cache in
  assert_eq 2 stats.hits "both operations hit"

let test_key_to_string () =
  section "Key Serialization";
  
  let key1 = DeductionKey (1, 2) in
  let str1 = key_to_string key1 in
  assert_true (String.length str1 > 0) "deduction key to string";
  Printf.printf "  ℹ️  DeductionKey(1,2) = %s\n" str1;
  
  let key2 = ChainKey [1; 2; 3; 4] in
  let str2 = key_to_string key2 in
  assert_true (String.length str2 > 0) "chain key to string";
  Printf.printf "  ℹ️  ChainKey[1,2,3,4] = %s\n" str2

let test_stats_serialization () =
  section "Statistics Serialization";
  
  let cache = create () in
  
  (* Generate some activity *)
  let _ = cached_deduction cache mock_atomspace 1 2 mock_deduction in
  let _ = cached_deduction cache mock_atomspace 1 2 mock_deduction in
  invalidate cache 1;
  
  let stats = get_stats cache in
  let stats_str = stats_to_string stats in
  Printf.printf "  ℹ️  Stats: %s\n" stats_str;
  assert_true (String.length stats_str > 0) "stats to string";
  
  let scheme_str = stats_to_scheme stats in
  Printf.printf "  ℹ️  Scheme: %s\n" scheme_str;
  assert_true (String.sub scheme_str 0 16 = "(pln-cache-stats") "stats to scheme"

let test_memory_estimate () =
  section "Memory Estimation";
  
  let cache = create () in
  
  let initial_mem = memory_estimate cache in
  assert_eq 0 initial_mem "empty cache memory is 0";
  
  (* Add entries *)
  for i = 1 to 100 do
    let _ = cached_deduction cache mock_atomspace i (i + 1) mock_deduction in
    ()
  done;
  
  let mem = memory_estimate cache in
  Printf.printf "  ℹ️  Memory estimate for 100 entries: %d bytes\n" mem;
  assert_true (mem > 0) "non-zero memory estimate"

let test_reset_stats () =
  section "Reset Statistics";
  
  let cache = create () in
  
  (* Generate activity *)
  let _ = cached_deduction cache mock_atomspace 1 2 mock_deduction in
  let _ = cached_deduction cache mock_atomspace 1 2 mock_deduction in
  
  let stats = get_stats cache in
  assert_true (stats.total_queries > 0) "stats have queries";
  
  reset_stats cache;
  
  let stats2 = get_stats cache in
  assert_eq 0 stats2.total_queries "stats reset to 0";
  assert_eq 0 stats2.hits "hits reset to 0";
  assert_eq 0 stats2.misses "misses reset to 0"

let () =
  Printf.printf "\n";
  Printf.printf "╔══════════════════════════════════════════════════════════╗\n";
  Printf.printf "║     PLN Inference Cache - Test Suite                     ║\n";
  Printf.printf "╚══════════════════════════════════════════════════════════╝\n";
  
  test_cache_creation ();
  test_cache_hit_miss ();
  test_hit_rate ();
  test_invalidation ();
  test_invalidate_all ();
  test_different_operations ();
  test_key_to_string ();
  test_stats_serialization ();
  test_memory_estimate ();
  test_reset_stats ();
  
  Printf.printf "\n";
  Printf.printf "╔══════════════════════════════════════════════════════════╗\n";
  Printf.printf "║                    Test Summary                          ║\n";
  Printf.printf "╠══════════════════════════════════════════════════════════╣\n";
  Printf.printf "║  Total:  %3d                                             ║\n" !test_count;
  Printf.printf "║  Passed: %3d                                             ║\n" !pass_count;
  Printf.printf "║  Failed: %3d                                             ║\n" !fail_count;
  Printf.printf "╚══════════════════════════════════════════════════════════╝\n";
  
  if !fail_count = 0 then
    Printf.printf "\n🚀 All PLN cache tests passed! 🚀\n\n"
  else
    Printf.printf "\n⚠️  Some tests failed. Please review. ⚠️\n\n"
