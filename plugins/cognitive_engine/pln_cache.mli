(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** PLN Inference Caching System Interface *)

open Pln_formulas

(** {1 Cache Types} *)

(** Cache key for identifying cached inferences *)
type cache_key =
  | DeductionKey of int * int
  | InductionKey of int * int
  | AbductionKey of int * int
  | RevisionKey of int * int
  | ModusPonensKey of int * int
  | ConjunctionKey of int * int
  | DisjunctionKey of int * int
  | NegationKey of int
  | ChainKey of int list

(** Cache statistics *)
type cache_stats = {
  mutable hits: int;
  mutable misses: int;
  mutable evictions: int;
  mutable invalidations: int;
  mutable total_queries: int;
}

(** Abstract cache type *)
type cache

(** {1 Cache Management} *)

(** Create a new cache with optional size limit and TTL *)
val create : ?max_size:int -> ?ttl:float -> unit -> cache

(** Invalidate entries depending on an atom *)
val invalidate : cache -> int -> unit

(** Invalidate all entries *)
val invalidate_all : cache -> unit

(** {1 Cached PLN Operations} *)

(** Cached deduction with compute function *)
val cached_deduction : 
  cache -> 'a -> int -> int -> 
  ('a -> int -> int -> (int * truth_value) option) -> 
  (int * truth_value) option

(** Cached induction with compute function *)
val cached_induction : 
  cache -> 'a -> int -> int -> 
  ('a -> int -> int -> (int * truth_value) option) -> 
  (int * truth_value) option

(** Cached abduction with compute function *)
val cached_abduction : 
  cache -> 'a -> int -> int -> 
  ('a -> int -> int -> (int * truth_value) option) -> 
  (int * truth_value) option

(** Cached revision with compute function *)
val cached_revision : 
  cache -> 'a -> int -> int -> 
  ('a -> int -> int -> (int * truth_value) option) -> 
  (int * truth_value) option

(** Cached modus ponens with compute function *)
val cached_modus_ponens : 
  cache -> 'a -> int -> int -> 
  ('a -> int -> int -> (int * truth_value) option) -> 
  (int * truth_value) option

(** Cached conjunction with compute function *)
val cached_conjunction : 
  cache -> 'a -> int -> int -> 
  ('a -> int -> int -> truth_value) -> 
  truth_value

(** Cached disjunction with compute function *)
val cached_disjunction : 
  cache -> 'a -> int -> int -> 
  ('a -> int -> int -> truth_value) -> 
  truth_value

(** Cached negation with compute function *)
val cached_negation : 
  cache -> 'a -> int -> 
  ('a -> int -> truth_value) -> 
  truth_value

(** Cached inference chain with compute function *)
val cached_chain : 
  cache -> 'a -> int list -> 
  ('a -> int list -> Pln_integration.inference_step list) -> 
  Pln_integration.inference_step list

(** {1 Statistics and Monitoring} *)

(** Get cache statistics *)
val get_stats : cache -> cache_stats

(** Get cache hit rate *)
val hit_rate : cache -> float

(** Get current cache size *)
val size : cache -> int

(** Get memory estimate in bytes *)
val memory_estimate : cache -> int

(** Reset statistics *)
val reset_stats : cache -> unit

(** {1 Serialization} *)

(** Serialize cache to string *)
val serialize : cache -> string

(** Statistics to string *)
val stats_to_string : cache_stats -> string

(** Statistics to Scheme *)
val stats_to_scheme : cache_stats -> string

(** Key to string *)
val key_to_string : cache_key -> string
