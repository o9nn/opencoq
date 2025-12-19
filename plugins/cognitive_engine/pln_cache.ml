(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** PLN Inference Caching System
    
    This module provides a caching layer for PLN inference results,
    optimizing repeated queries and supporting incremental updates.
    
    Features:
    - LRU cache with configurable size
    - Cache invalidation on truth value updates
    - Dependency tracking for inference chains
    - Statistics and monitoring
*)

open Pln_formulas

(** {1 Cache Key Types} *)

(** Unique identifier for a cached inference *)
type cache_key =
  | DeductionKey of int * int       (** premise1_id, premise2_id *)
  | InductionKey of int * int       (** premise1_id, premise2_id *)
  | AbductionKey of int * int       (** premise1_id, premise2_id *)
  | RevisionKey of int * int        (** link_id1, link_id2 *)
  | ModusPonensKey of int * int     (** node_id, impl_link_id *)
  | ConjunctionKey of int * int     (** node1_id, node2_id *)
  | DisjunctionKey of int * int     (** node1_id, node2_id *)
  | NegationKey of int              (** node_id *)
  | ChainKey of int list            (** sequence of link_ids *)

(** Cache entry with metadata *)
type cache_entry = {
  result: (int * truth_value) option;  (** Inference result *)
  timestamp: float;                     (** When cached *)
  access_count: int;                    (** Number of accesses *)
  last_access: float;                   (** Last access time *)
  dependencies: int list;               (** Atom IDs this depends on *)
}

(** {1 Cache Statistics} *)

type cache_stats = {
  mutable hits: int;
  mutable misses: int;
  mutable evictions: int;
  mutable invalidations: int;
  mutable total_queries: int;
}

let create_stats () = {
  hits = 0;
  misses = 0;
  evictions = 0;
  invalidations = 0;
  total_queries = 0;
}

(** {1 LRU Cache Implementation} *)

module CacheKeyMap = Map.Make(struct
  type t = cache_key
  let compare = compare
end)

module IntSet = Set.Make(Int)

type cache = {
  mutable entries: cache_entry CacheKeyMap.t;
  mutable dependency_index: cache_key list IntSet.t;  (** atom_id -> keys that depend on it *)
  max_size: int;
  ttl: float;  (** Time-to-live in seconds *)
  stats: cache_stats;
}

(** Create a new cache *)
let create ?(max_size=10000) ?(ttl=300.0) () = {
  entries = CacheKeyMap.empty;
  dependency_index = IntSet.empty;
  max_size;
  ttl;
  stats = create_stats ();
}

(** Get current time *)
let now () = Unix.gettimeofday ()

(** Convert cache key to string for debugging *)
let key_to_string = function
  | DeductionKey (a, b) -> Printf.sprintf "deduction(%d,%d)" a b
  | InductionKey (a, b) -> Printf.sprintf "induction(%d,%d)" a b
  | AbductionKey (a, b) -> Printf.sprintf "abduction(%d,%d)" a b
  | RevisionKey (a, b) -> Printf.sprintf "revision(%d,%d)" a b
  | ModusPonensKey (a, b) -> Printf.sprintf "modus_ponens(%d,%d)" a b
  | ConjunctionKey (a, b) -> Printf.sprintf "conjunction(%d,%d)" a b
  | DisjunctionKey (a, b) -> Printf.sprintf "disjunction(%d,%d)" a b
  | NegationKey a -> Printf.sprintf "negation(%d)" a
  | ChainKey ids -> Printf.sprintf "chain[%s]" (String.concat "," (List.map string_of_int ids))

(** Extract dependencies from a cache key *)
let key_dependencies = function
  | DeductionKey (a, b) -> [a; b]
  | InductionKey (a, b) -> [a; b]
  | AbductionKey (a, b) -> [a; b]
  | RevisionKey (a, b) -> [a; b]
  | ModusPonensKey (a, b) -> [a; b]
  | ConjunctionKey (a, b) -> [a; b]
  | DisjunctionKey (a, b) -> [a; b]
  | NegationKey a -> [a]
  | ChainKey ids -> ids

(** Check if entry is expired *)
let is_expired cache entry =
  now () -. entry.timestamp > cache.ttl

(** Evict least recently used entries *)
let evict_lru cache =
  if CacheKeyMap.cardinal cache.entries <= cache.max_size then ()
  else begin
    (* Find entries to evict (oldest 10%) *)
    let entries_list = CacheKeyMap.bindings cache.entries in
    let sorted = List.sort (fun (_, e1) (_, e2) -> 
      compare e1.last_access e2.last_access
    ) entries_list in
    let to_evict = List.length sorted / 10 + 1 in
    let evict_keys = List.map fst (List.filteri (fun i _ -> i < to_evict) sorted) in
    
    List.iter (fun key ->
      cache.entries <- CacheKeyMap.remove key cache.entries;
      cache.stats.evictions <- cache.stats.evictions + 1
    ) evict_keys
  end

(** Add entry to cache *)
let add cache key result dependencies =
  evict_lru cache;
  let entry = {
    result;
    timestamp = now ();
    access_count = 0;
    last_access = now ();
    dependencies;
  } in
  cache.entries <- CacheKeyMap.add key entry cache.entries

(** Lookup entry in cache *)
let lookup cache key =
  cache.stats.total_queries <- cache.stats.total_queries + 1;
  match CacheKeyMap.find_opt key cache.entries with
  | Some entry when not (is_expired cache entry) ->
    cache.stats.hits <- cache.stats.hits + 1;
    let updated_entry = { entry with
      access_count = entry.access_count + 1;
      last_access = now ();
    } in
    cache.entries <- CacheKeyMap.add key updated_entry cache.entries;
    Some entry.result
  | Some _ ->
    (* Expired - remove and miss *)
    cache.entries <- CacheKeyMap.remove key cache.entries;
    cache.stats.misses <- cache.stats.misses + 1;
    None
  | None ->
    cache.stats.misses <- cache.stats.misses + 1;
    None

(** Invalidate entries depending on an atom *)
let invalidate cache atom_id =
  let keys_to_remove = CacheKeyMap.fold (fun key entry acc ->
    if List.mem atom_id entry.dependencies then key :: acc
    else acc
  ) cache.entries [] in
  
  List.iter (fun key ->
    cache.entries <- CacheKeyMap.remove key cache.entries;
    cache.stats.invalidations <- cache.stats.invalidations + 1
  ) keys_to_remove

(** Invalidate all entries *)
let invalidate_all cache =
  let count = CacheKeyMap.cardinal cache.entries in
  cache.entries <- CacheKeyMap.empty;
  cache.stats.invalidations <- cache.stats.invalidations + count

(** {1 Cached PLN Operations} *)

(** Cached deduction *)
let cached_deduction cache atomspace premise1_id premise2_id compute_fn =
  let key = DeductionKey (premise1_id, premise2_id) in
  match lookup cache key with
  | Some result -> result
  | None ->
    let result = compute_fn atomspace premise1_id premise2_id in
    add cache key result [premise1_id; premise2_id];
    result

(** Cached induction *)
let cached_induction cache atomspace premise1_id premise2_id compute_fn =
  let key = InductionKey (premise1_id, premise2_id) in
  match lookup cache key with
  | Some result -> result
  | None ->
    let result = compute_fn atomspace premise1_id premise2_id in
    add cache key result [premise1_id; premise2_id];
    result

(** Cached abduction *)
let cached_abduction cache atomspace premise1_id premise2_id compute_fn =
  let key = AbductionKey (premise1_id, premise2_id) in
  match lookup cache key with
  | Some result -> result
  | None ->
    let result = compute_fn atomspace premise1_id premise2_id in
    add cache key result [premise1_id; premise2_id];
    result

(** Cached revision *)
let cached_revision cache atomspace link_id1 link_id2 compute_fn =
  let key = RevisionKey (link_id1, link_id2) in
  match lookup cache key with
  | Some result -> result
  | None ->
    let result = compute_fn atomspace link_id1 link_id2 in
    add cache key result [link_id1; link_id2];
    result

(** Cached modus ponens *)
let cached_modus_ponens cache atomspace node_id impl_link_id compute_fn =
  let key = ModusPonensKey (node_id, impl_link_id) in
  match lookup cache key with
  | Some result -> result
  | None ->
    let result = compute_fn atomspace node_id impl_link_id in
    add cache key result [node_id; impl_link_id];
    result

(** Cached conjunction *)
let cached_conjunction cache atomspace node1_id node2_id compute_fn =
  let key = ConjunctionKey (node1_id, node2_id) in
  match lookup cache key with
  | Some (Some (_, tv)) -> tv
  | _ ->
    let result = compute_fn atomspace node1_id node2_id in
    add cache key (Some (0, result)) [node1_id; node2_id];
    result

(** Cached disjunction *)
let cached_disjunction cache atomspace node1_id node2_id compute_fn =
  let key = DisjunctionKey (node1_id, node2_id) in
  match lookup cache key with
  | Some (Some (_, tv)) -> tv
  | _ ->
    let result = compute_fn atomspace node1_id node2_id in
    add cache key (Some (0, result)) [node1_id; node2_id];
    result

(** Cached negation *)
let cached_negation cache atomspace node_id compute_fn =
  let key = NegationKey node_id in
  match lookup cache key with
  | Some (Some (_, tv)) -> tv
  | _ ->
    let result = compute_fn atomspace node_id in
    add cache key (Some (0, result)) [node_id];
    result

(** Cached inference chain *)
let cached_chain cache atomspace link_ids compute_fn =
  let key = ChainKey link_ids in
  match lookup cache key with
  | Some result -> 
    (match result with Some (_, tv) -> [{ Pln_integration.rule_name = "cached"; premises = link_ids; conclusion = 0; truth_value = tv }] | None -> [])
  | None ->
    let result = compute_fn atomspace link_ids in
    let final_tv = match result with
      | [] -> None
      | steps -> Some (0, (List.hd (List.rev steps)).Pln_integration.truth_value)
    in
    add cache key final_tv link_ids;
    result

(** {1 Statistics and Monitoring} *)

(** Get cache statistics *)
let get_stats cache = cache.stats

(** Get hit rate *)
let hit_rate cache =
  if cache.stats.total_queries = 0 then 0.0
  else float_of_int cache.stats.hits /. float_of_int cache.stats.total_queries

(** Get cache size *)
let size cache = CacheKeyMap.cardinal cache.entries

(** Get memory estimate (rough) *)
let memory_estimate cache =
  let entry_size = 64 in  (* Approximate bytes per entry *)
  size cache * entry_size

(** Reset statistics *)
let reset_stats cache =
  cache.stats.hits <- 0;
  cache.stats.misses <- 0;
  cache.stats.evictions <- 0;
  cache.stats.invalidations <- 0;
  cache.stats.total_queries <- 0

(** {1 Persistence} *)

(** Serialize cache to string *)
let serialize cache =
  let entries = CacheKeyMap.bindings cache.entries in
  let entry_strs = List.map (fun (key, entry) ->
    Printf.sprintf "(%s %f %d %f [%s] %s)"
      (key_to_string key)
      entry.timestamp
      entry.access_count
      entry.last_access
      (String.concat "," (List.map string_of_int entry.dependencies))
      (match entry.result with
       | Some (id, tv) -> Printf.sprintf "(result %d %.6f %.6f)" id tv.strength tv.confidence
       | None -> "(none)")
  ) entries in
  Printf.sprintf "(pln-cache (size %d) (max-size %d) (ttl %.1f)\n  %s)"
    (size cache) cache.max_size cache.ttl
    (String.concat "\n  " entry_strs)

(** Statistics to string *)
let stats_to_string stats =
  Printf.sprintf "PLN Cache Stats: hits=%d misses=%d evictions=%d invalidations=%d total=%d hit_rate=%.2f%%"
    stats.hits stats.misses stats.evictions stats.invalidations stats.total_queries
    (if stats.total_queries = 0 then 0.0 
     else 100.0 *. float_of_int stats.hits /. float_of_int stats.total_queries)

(** {1 Scheme Serialization} *)

let stats_to_scheme stats =
  Printf.sprintf "(pln-cache-stats (hits %d) (misses %d) (evictions %d) (invalidations %d) (total-queries %d) (hit-rate %.4f))"
    stats.hits stats.misses stats.evictions stats.invalidations stats.total_queries
    (if stats.total_queries = 0 then 0.0 
     else float_of_int stats.hits /. float_of_int stats.total_queries)
