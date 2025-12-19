(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** MOSES S-Expression Program Representation Interface
    
    This module provides the program representation for MOSES
    (Meta-Optimizing Semantic Evolutionary Search).
*)

(** {1 S-Expression AST} *)

(** Primitive types *)
type primitive =
  | PBool of bool
  | PInt of int
  | PFloat of float
  | PString of string

(** Built-in operators *)
type operator =
  | And | Or | Not | Xor | Implies | Equiv
  | Add | Sub | Mul | Div | Mod | Neg | Abs
  | Eq | Ne | Lt | Le | Gt | Ge
  | If
  | Cons | Car | Cdr | Null | Length
  | Map | Filter | Fold | Apply
  | Quote | Lambda | Let | Define

(** S-expression AST *)
type sexpr =
  | Atom of string
  | Prim of primitive
  | Op of operator
  | List of sexpr list
  | Quoted of sexpr

(** Program with metadata *)
type program = {
  expr: sexpr;
  arity: int;
  variables: string list;
  mutable fitness: float;
  mutable complexity: int;
  generation: int;
}

(** {1 Parsing and Printing} *)

(** Convert S-expression to string *)
val sexpr_to_string : sexpr -> string

(** Parse S-expression from string *)
val parse_sexpr : string -> sexpr

(** Convert operator to string *)
val operator_to_string : operator -> string

(** Parse operator from string *)
val operator_of_string : string -> operator option

(** {1 Program Construction} *)

(** Create program from S-expression string *)
val create_program : ?generation:int -> string -> program

(** Create program from AST *)
val create_program_from_expr : ?generation:int -> sexpr -> program

(** Calculate structural complexity *)
val complexity : sexpr -> int

(** {1 Genetic Operators} *)

(** Crossover: Exchange subtrees between two programs *)
val crossover : program -> program -> program * program

(** Mutation: Random modification of program *)
val mutate : ?rate:float -> program -> program

(** Point mutation: Small local changes *)
val point_mutate : ?rate:float -> program -> program

(** Generate random expression *)
val random_expr : int -> sexpr

(** {1 Program Simplification} *)

(** Simplify expression using algebraic rules *)
val simplify : sexpr -> sexpr

(** Simplify program *)
val simplify_program : program -> program

(** {1 Evaluation} *)

(** Evaluation environment *)
type env = (string * sexpr) list

(** Evaluate S-expression in environment *)
val eval : env -> sexpr -> sexpr

(** Evaluate program with float inputs *)
val eval_program : program -> float list -> sexpr

(** {1 Fitness Evaluation} *)

(** Fitness function type *)
type fitness_fn = program -> float

(** Boolean fitness: percentage of correct outputs *)
val boolean_fitness : (float list * bool) list -> fitness_fn

(** Regression fitness: 1 / (1 + MSE) *)
val regression_fitness : (float list * float) list -> fitness_fn

(** Complexity-penalized fitness *)
val penalized_fitness : ?complexity_weight:float -> fitness_fn -> fitness_fn

(** {1 Population Management} *)

(** Population type *)
type population = {
  programs: program array;
  generation: int;
  best_fitness: float;
  avg_fitness: float;
}

(** Create initial random population *)
val create_population : int -> int -> population

(** Evaluate population fitness *)
val evaluate_population : fitness_fn -> population -> population

(** Tournament selection *)
val tournament_select : ?size:int -> population -> program

(** Evolve population one generation *)
val evolve_population : 
  ?mutation_rate:float -> 
  ?crossover_rate:float -> 
  ?elitism:int -> 
  fitness_fn -> population -> population

(** Run MOSES evolution *)
val run_moses : 
  ?population_size:int -> 
  ?max_generations:int -> 
  ?target_fitness:float -> 
  fitness_fn -> program

(** {1 Scheme Serialization} *)

(** Convert program to Scheme S-expression *)
val program_to_scheme : program -> string

(** Convert population to Scheme S-expression *)
val population_to_scheme : population -> string
