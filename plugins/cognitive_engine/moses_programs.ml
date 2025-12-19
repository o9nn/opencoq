(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** MOSES S-Expression Program Representation
    
    This module implements the program representation for MOSES
    (Meta-Optimizing Semantic Evolutionary Search), including:
    - S-expression AST for program trees
    - Genetic operators (crossover, mutation)
    - Fitness evaluation framework
    - Program simplification and normalization
*)

(** {1 S-Expression AST} *)

(** Primitive types in MOSES programs *)
type primitive =
  | PBool of bool
  | PInt of int
  | PFloat of float
  | PString of string

(** Built-in operators *)
type operator =
  (* Logical operators *)
  | And | Or | Not | Xor | Implies | Equiv
  (* Arithmetic operators *)
  | Add | Sub | Mul | Div | Mod | Neg | Abs
  (* Comparison operators *)
  | Eq | Ne | Lt | Le | Gt | Ge
  (* Conditional *)
  | If
  (* List operators *)
  | Cons | Car | Cdr | Null | Length
  (* Higher-order *)
  | Map | Filter | Fold | Apply
  (* Special *)
  | Quote | Lambda | Let | Define

let operator_to_string = function
  | And -> "and" | Or -> "or" | Not -> "not" | Xor -> "xor"
  | Implies -> "implies" | Equiv -> "equiv"
  | Add -> "+" | Sub -> "-" | Mul -> "*" | Div -> "/" | Mod -> "mod"
  | Neg -> "neg" | Abs -> "abs"
  | Eq -> "=" | Ne -> "!=" | Lt -> "<" | Le -> "<=" | Gt -> ">" | Ge -> ">="
  | If -> "if"
  | Cons -> "cons" | Car -> "car" | Cdr -> "cdr" | Null -> "null?" | Length -> "length"
  | Map -> "map" | Filter -> "filter" | Fold -> "fold" | Apply -> "apply"
  | Quote -> "quote" | Lambda -> "lambda" | Let -> "let" | Define -> "define"

let operator_of_string = function
  | "and" -> Some And | "or" -> Some Or | "not" -> Some Not | "xor" -> Some Xor
  | "implies" -> Some Implies | "equiv" -> Some Equiv
  | "+" -> Some Add | "-" -> Some Sub | "*" -> Some Mul | "/" -> Some Div | "mod" -> Some Mod
  | "neg" -> Some Neg | "abs" -> Some Abs
  | "=" -> Some Eq | "!=" -> Some Ne | "<" -> Some Lt | "<=" -> Some Le | ">" -> Some Gt | ">=" -> Some Ge
  | "if" -> Some If
  | "cons" -> Some Cons | "car" -> Some Car | "cdr" -> Some Cdr | "null?" -> Some Null | "length" -> Some Length
  | "map" -> Some Map | "filter" -> Some Filter | "fold" -> Some Fold | "apply" -> Some Apply
  | "quote" -> Some Quote | "lambda" -> Some Lambda | "let" -> Some Let | "define" -> Some Define
  | _ -> None

(** S-expression AST *)
type sexpr =
  | Atom of string                    (** Symbol or variable *)
  | Prim of primitive                 (** Primitive value *)
  | Op of operator                    (** Built-in operator *)
  | List of sexpr list                (** List/application *)
  | Quoted of sexpr                   (** Quoted expression *)

(** Program with metadata *)
type program = {
  expr: sexpr;
  arity: int;                         (** Number of input variables *)
  variables: string list;             (** Input variable names *)
  mutable fitness: float;             (** Fitness score *)
  mutable complexity: int;            (** Structural complexity *)
  generation: int;                    (** Generation number *)
}

(** {1 S-Expression Parsing and Printing} *)

(** Convert S-expression to string *)
let rec sexpr_to_string = function
  | Atom s -> s
  | Prim (PBool b) -> if b then "#t" else "#f"
  | Prim (PInt i) -> string_of_int i
  | Prim (PFloat f) -> string_of_float f
  | Prim (PString s) -> Printf.sprintf "\"%s\"" s
  | Op op -> operator_to_string op
  | List [] -> "()"
  | List exprs -> 
    Printf.sprintf "(%s)" (String.concat " " (List.map sexpr_to_string exprs))
  | Quoted e -> Printf.sprintf "'%s" (sexpr_to_string e)

(** Tokenize S-expression string *)
let tokenize str =
  let tokens = ref [] in
  let current = Buffer.create 16 in
  let flush () =
    if Buffer.length current > 0 then begin
      tokens := Buffer.contents current :: !tokens;
      Buffer.clear current
    end
  in
  let in_string = ref false in
  String.iter (fun c ->
    if !in_string then begin
      Buffer.add_char current c;
      if c = '"' then begin
        in_string := false;
        flush ()
      end
    end else match c with
    | '(' | ')' | '\'' ->
      flush ();
      tokens := String.make 1 c :: !tokens
    | ' ' | '\t' | '\n' | '\r' -> flush ()
    | '"' ->
      flush ();
      in_string := true;
      Buffer.add_char current c
    | _ -> Buffer.add_char current c
  ) str;
  flush ();
  List.rev !tokens

(** Parse tokens into S-expression *)
let rec parse_tokens tokens =
  match tokens with
  | [] -> failwith "Unexpected end of input"
  | "(" :: rest ->
    let (exprs, remaining) = parse_list rest in
    (List exprs, remaining)
  | ")" :: _ -> failwith "Unexpected )"
  | "'" :: rest ->
    let (expr, remaining) = parse_tokens rest in
    (Quoted expr, remaining)
  | token :: rest ->
    (parse_atom token, rest)

and parse_list tokens =
  match tokens with
  | [] -> failwith "Unexpected end of list"
  | ")" :: rest -> ([], rest)
  | _ ->
    let (expr, remaining) = parse_tokens tokens in
    let (exprs, final) = parse_list remaining in
    (expr :: exprs, final)

and parse_atom token =
  (* Try parsing as primitive *)
  if token = "#t" then Prim (PBool true)
  else if token = "#f" then Prim (PBool false)
  else if String.length token > 0 && token.[0] = '"' then
    Prim (PString (String.sub token 1 (String.length token - 2)))
  else
    try Prim (PInt (int_of_string token))
    with _ ->
      try Prim (PFloat (float_of_string token))
      with _ ->
        match operator_of_string token with
        | Some op -> Op op
        | None -> Atom token

(** Parse S-expression from string *)
let parse_sexpr str =
  let tokens = tokenize str in
  let (expr, _) = parse_tokens tokens in
  expr

(** {1 Program Construction} *)

(** Calculate structural complexity *)
let rec complexity = function
  | Atom _ | Prim _ | Op _ -> 1
  | Quoted e -> 1 + complexity e
  | List exprs -> 1 + List.fold_left (fun acc e -> acc + complexity e) 0 exprs

(** Extract variables from expression *)
let rec extract_variables = function
  | Atom s when String.length s > 0 && s.[0] = '$' -> [s]
  | Atom _ | Prim _ | Op _ -> []
  | Quoted _ -> []
  | List exprs -> List.concat_map extract_variables exprs

(** Create program from S-expression string *)
let create_program ?(generation=0) str =
  let expr = parse_sexpr str in
  let vars = extract_variables expr |> List.sort_uniq String.compare in
  {
    expr;
    arity = List.length vars;
    variables = vars;
    fitness = 0.0;
    complexity = complexity expr;
    generation;
  }

(** Create program from AST *)
let create_program_from_expr ?(generation=0) expr =
  let vars = extract_variables expr |> List.sort_uniq String.compare in
  {
    expr;
    arity = List.length vars;
    variables = vars;
    fitness = 0.0;
    complexity = complexity expr;
    generation;
  }

(** {1 Genetic Operators} *)

(** Random node selection for genetic operations *)
let rec count_nodes = function
  | Atom _ | Prim _ | Op _ -> 1
  | Quoted e -> 1 + count_nodes e
  | List exprs -> 1 + List.fold_left (fun acc e -> acc + count_nodes e) 0 exprs

let rec select_node expr n =
  if n = 0 then Some expr
  else match expr with
  | Atom _ | Prim _ | Op _ -> None
  | Quoted e -> select_node e (n - 1)
  | List exprs ->
    let rec try_children es remaining =
      match es with
      | [] -> None
      | e :: rest ->
        let size = count_nodes e in
        if remaining <= size then select_node e (remaining - 1)
        else try_children rest (remaining - size)
    in
    try_children exprs (n - 1)

let rec replace_node expr n replacement =
  if n = 0 then replacement
  else match expr with
  | Atom _ | Prim _ | Op _ -> expr
  | Quoted e -> Quoted (replace_node e (n - 1) replacement)
  | List exprs ->
    let rec replace_in_children es remaining acc =
      match es with
      | [] -> List (List.rev acc)
      | e :: rest ->
        let size = count_nodes e in
        if remaining <= size then
          List (List.rev_append acc (replace_node e (remaining - 1) replacement :: rest))
        else
          replace_in_children rest (remaining - size) (e :: acc)
    in
    replace_in_children exprs (n - 1) []

(** Crossover: Exchange subtrees between two programs *)
let crossover p1 p2 =
  let n1 = count_nodes p1.expr in
  let n2 = count_nodes p2.expr in
  
  if n1 <= 1 || n2 <= 1 then (p1, p2)
  else
    let pos1 = 1 + Random.int (n1 - 1) in
    let pos2 = 1 + Random.int (n2 - 1) in
    
    match select_node p1.expr pos1, select_node p2.expr pos2 with
    | Some subtree1, Some subtree2 ->
      let new_expr1 = replace_node p1.expr pos1 subtree2 in
      let new_expr2 = replace_node p2.expr pos2 subtree1 in
      let child1 = create_program_from_expr ~generation:(max p1.generation p2.generation + 1) new_expr1 in
      let child2 = create_program_from_expr ~generation:(max p1.generation p2.generation + 1) new_expr2 in
      (child1, child2)
    | _ -> (p1, p2)

(** Random expression generation for mutation *)
let random_primitive () =
  match Random.int 4 with
  | 0 -> Prim (PBool (Random.bool ()))
  | 1 -> Prim (PInt (Random.int 100 - 50))
  | 2 -> Prim (PFloat (Random.float 10.0 -. 5.0))
  | _ -> Atom (Printf.sprintf "$x%d" (Random.int 5))

let random_operator () =
  let ops = [|And; Or; Not; Add; Sub; Mul; Eq; Lt; If|] in
  Op ops.(Random.int (Array.length ops))

let rec random_expr depth =
  if depth <= 0 || Random.float 1.0 < 0.3 then
    random_primitive ()
  else
    let op = random_operator () in
    let arity = match op with
      | Op Not | Op Neg | Op Abs -> 1
      | Op If -> 3
      | _ -> 2
    in
    List (Op (match op with Op o -> o | _ -> And) :: 
          List.init arity (fun _ -> random_expr (depth - 1)))

(** Mutation: Random modification of program *)
let mutate ?(rate=0.1) p =
  let n = count_nodes p.expr in
  if n <= 1 || Random.float 1.0 > rate then p
  else
    let pos = 1 + Random.int (n - 1) in
    let new_subtree = random_expr 2 in
    let new_expr = replace_node p.expr pos new_subtree in
    create_program_from_expr ~generation:(p.generation + 1) new_expr

(** Point mutation: Small local changes *)
let point_mutate ?(rate=0.05) p =
  let rec mutate_expr = function
    | Prim (PInt i) when Random.float 1.0 < rate ->
      Prim (PInt (i + Random.int 3 - 1))
    | Prim (PFloat f) when Random.float 1.0 < rate ->
      Prim (PFloat (f +. Random.float 0.2 -. 0.1))
    | Prim (PBool b) when Random.float 1.0 < rate ->
      Prim (PBool (not b))
    | Op And when Random.float 1.0 < rate -> Op Or
    | Op Or when Random.float 1.0 < rate -> Op And
    | Op Add when Random.float 1.0 < rate -> Op Sub
    | Op Sub when Random.float 1.0 < rate -> Op Add
    | Op Mul when Random.float 1.0 < rate -> Op Div
    | Op Lt when Random.float 1.0 < rate -> Op Gt
    | List exprs -> List (List.map mutate_expr exprs)
    | Quoted e -> Quoted (mutate_expr e)
    | e -> e
  in
  let new_expr = mutate_expr p.expr in
  create_program_from_expr ~generation:(p.generation + 1) new_expr

(** {1 Program Simplification} *)

(** Simplify expression using algebraic rules *)
let rec simplify = function
  (* Boolean simplifications *)
  | List [Op And; Prim (PBool true); e] -> simplify e
  | List [Op And; e; Prim (PBool true)] -> simplify e
  | List [Op And; Prim (PBool false); _] -> Prim (PBool false)
  | List [Op And; _; Prim (PBool false)] -> Prim (PBool false)
  | List [Op Or; Prim (PBool false); e] -> simplify e
  | List [Op Or; e; Prim (PBool false)] -> simplify e
  | List [Op Or; Prim (PBool true); _] -> Prim (PBool true)
  | List [Op Or; _; Prim (PBool true)] -> Prim (PBool true)
  | List [Op Not; Prim (PBool b)] -> Prim (PBool (not b))
  | List [Op Not; List [Op Not; e]] -> simplify e
  
  (* Arithmetic simplifications *)
  | List [Op Add; Prim (PInt 0); e] -> simplify e
  | List [Op Add; e; Prim (PInt 0)] -> simplify e
  | List [Op Add; Prim (PInt a); Prim (PInt b)] -> Prim (PInt (a + b))
  | List [Op Sub; e; Prim (PInt 0)] -> simplify e
  | List [Op Sub; Prim (PInt a); Prim (PInt b)] -> Prim (PInt (a - b))
  | List [Op Mul; Prim (PInt 0); _] -> Prim (PInt 0)
  | List [Op Mul; _; Prim (PInt 0)] -> Prim (PInt 0)
  | List [Op Mul; Prim (PInt 1); e] -> simplify e
  | List [Op Mul; e; Prim (PInt 1)] -> simplify e
  | List [Op Mul; Prim (PInt a); Prim (PInt b)] -> Prim (PInt (a * b))
  | List [Op Div; e; Prim (PInt 1)] -> simplify e
  | List [Op Neg; Prim (PInt i)] -> Prim (PInt (-i))
  | List [Op Neg; List [Op Neg; e]] -> simplify e
  
  (* Float simplifications *)
  | List [Op Add; Prim (PFloat 0.0); e] -> simplify e
  | List [Op Add; e; Prim (PFloat 0.0)] -> simplify e
  | List [Op Add; Prim (PFloat a); Prim (PFloat b)] -> Prim (PFloat (a +. b))
  | List [Op Mul; Prim (PFloat 0.0); _] -> Prim (PFloat 0.0)
  | List [Op Mul; _; Prim (PFloat 0.0)] -> Prim (PFloat 0.0)
  | List [Op Mul; Prim (PFloat 1.0); e] -> simplify e
  | List [Op Mul; e; Prim (PFloat 1.0)] -> simplify e
  
  (* Conditional simplifications *)
  | List [Op If; Prim (PBool true); then_e; _] -> simplify then_e
  | List [Op If; Prim (PBool false); _; else_e] -> simplify else_e
  | List [Op If; cond; e1; e2] when e1 = e2 -> simplify e1
  
  (* Comparison simplifications *)
  | List [Op Eq; e1; e2] when e1 = e2 -> Prim (PBool true)
  | List [Op Ne; e1; e2] when e1 = e2 -> Prim (PBool false)
  
  (* Recursive simplification *)
  | List exprs -> 
    let simplified = List (List.map simplify exprs) in
    if simplified = List exprs then simplified
    else simplify simplified
  | Quoted e -> Quoted (simplify e)
  | e -> e

(** Simplify program *)
let simplify_program p =
  let simplified_expr = simplify p.expr in
  { p with 
    expr = simplified_expr;
    complexity = complexity simplified_expr;
  }

(** {1 Fitness Evaluation} *)

(** Evaluation environment *)
type env = (string * sexpr) list

(** Evaluate S-expression *)
let rec eval env = function
  | Atom s -> 
    (try List.assoc s env with Not_found -> Atom s)
  | Prim _ as p -> p
  | Op _ as o -> o
  | Quoted e -> e
  | List [] -> List []
  | List (Op op :: args) -> eval_op env op args
  | List (Atom "lambda" :: _) as lambda -> lambda
  | List (f :: args) ->
    let f' = eval env f in
    let args' = List.map (eval env) args in
    apply env f' args'

and eval_op env op args =
  let eval_args () = List.map (eval env) args in
  match op, args with
  (* Logical *)
  | And, [a; b] ->
    (match eval env a, eval env b with
     | Prim (PBool x), Prim (PBool y) -> Prim (PBool (x && y))
     | _ -> List (Op And :: eval_args ()))
  | Or, [a; b] ->
    (match eval env a, eval env b with
     | Prim (PBool x), Prim (PBool y) -> Prim (PBool (x || y))
     | _ -> List (Op Or :: eval_args ()))
  | Not, [a] ->
    (match eval env a with
     | Prim (PBool x) -> Prim (PBool (not x))
     | _ -> List [Op Not; eval env a])
  
  (* Arithmetic *)
  | Add, [a; b] ->
    (match eval env a, eval env b with
     | Prim (PInt x), Prim (PInt y) -> Prim (PInt (x + y))
     | Prim (PFloat x), Prim (PFloat y) -> Prim (PFloat (x +. y))
     | _ -> List (Op Add :: eval_args ()))
  | Sub, [a; b] ->
    (match eval env a, eval env b with
     | Prim (PInt x), Prim (PInt y) -> Prim (PInt (x - y))
     | Prim (PFloat x), Prim (PFloat y) -> Prim (PFloat (x -. y))
     | _ -> List (Op Sub :: eval_args ()))
  | Mul, [a; b] ->
    (match eval env a, eval env b with
     | Prim (PInt x), Prim (PInt y) -> Prim (PInt (x * y))
     | Prim (PFloat x), Prim (PFloat y) -> Prim (PFloat (x *. y))
     | _ -> List (Op Mul :: eval_args ()))
  | Div, [a; b] ->
    (match eval env a, eval env b with
     | Prim (PInt x), Prim (PInt y) when y <> 0 -> Prim (PInt (x / y))
     | Prim (PFloat x), Prim (PFloat y) when y <> 0.0 -> Prim (PFloat (x /. y))
     | _ -> List (Op Div :: eval_args ()))
  | Neg, [a] ->
    (match eval env a with
     | Prim (PInt x) -> Prim (PInt (-x))
     | Prim (PFloat x) -> Prim (PFloat (-.x))
     | _ -> List [Op Neg; eval env a])
  | Abs, [a] ->
    (match eval env a with
     | Prim (PInt x) -> Prim (PInt (abs x))
     | Prim (PFloat x) -> Prim (PFloat (abs_float x))
     | _ -> List [Op Abs; eval env a])
  
  (* Comparison *)
  | Eq, [a; b] ->
    let a' = eval env a in
    let b' = eval env b in
    Prim (PBool (a' = b'))
  | Lt, [a; b] ->
    (match eval env a, eval env b with
     | Prim (PInt x), Prim (PInt y) -> Prim (PBool (x < y))
     | Prim (PFloat x), Prim (PFloat y) -> Prim (PBool (x < y))
     | _ -> List (Op Lt :: eval_args ()))
  | Le, [a; b] ->
    (match eval env a, eval env b with
     | Prim (PInt x), Prim (PInt y) -> Prim (PBool (x <= y))
     | Prim (PFloat x), Prim (PFloat y) -> Prim (PBool (x <= y))
     | _ -> List (Op Le :: eval_args ()))
  | Gt, [a; b] ->
    (match eval env a, eval env b with
     | Prim (PInt x), Prim (PInt y) -> Prim (PBool (x > y))
     | Prim (PFloat x), Prim (PFloat y) -> Prim (PBool (x > y))
     | _ -> List (Op Gt :: eval_args ()))
  | Ge, [a; b] ->
    (match eval env a, eval env b with
     | Prim (PInt x), Prim (PInt y) -> Prim (PBool (x >= y))
     | Prim (PFloat x), Prim (PFloat y) -> Prim (PBool (x >= y))
     | _ -> List (Op Ge :: eval_args ()))
  
  (* Conditional *)
  | If, [cond; then_e; else_e] ->
    (match eval env cond with
     | Prim (PBool true) -> eval env then_e
     | Prim (PBool false) -> eval env else_e
     | _ -> List [Op If; eval env cond; eval env then_e; eval env else_e])
  
  | _ -> List (Op op :: eval_args ())

and apply env f args =
  match f with
  | List (Atom "lambda" :: List params :: body :: []) ->
    let param_names = List.map (function Atom s -> s | _ -> "_") params in
    let bindings = List.combine param_names args in
    eval (bindings @ env) body
  | _ -> List (f :: args)

(** Evaluate program with inputs *)
let eval_program p inputs =
  if List.length inputs <> p.arity then
    failwith "Input arity mismatch"
  else
    let env = List.combine p.variables (List.map (fun x -> Prim (PFloat x)) inputs) in
    eval env p.expr

(** Fitness function type *)
type fitness_fn = program -> float

(** Boolean fitness: percentage of correct outputs *)
let boolean_fitness test_cases p =
  let correct = List.fold_left (fun acc (inputs, expected) ->
    try
      let result = eval_program p inputs in
      match result, expected with
      | Prim (PBool r), b when r = b -> acc + 1
      | _ -> acc
    with _ -> acc
  ) 0 test_cases in
  float_of_int correct /. float_of_int (List.length test_cases)

(** Regression fitness: 1 / (1 + MSE) *)
let regression_fitness test_cases p =
  let mse = List.fold_left (fun acc (inputs, expected) ->
    try
      let result = eval_program p inputs in
      match result with
      | Prim (PFloat r) -> acc +. (r -. expected) ** 2.0
      | Prim (PInt r) -> acc +. (float_of_int r -. expected) ** 2.0
      | _ -> acc +. 1000.0  (* Penalty for wrong type *)
    with _ -> acc +. 1000.0  (* Penalty for error *)
  ) 0.0 test_cases in
  1.0 /. (1.0 +. mse /. float_of_int (List.length test_cases))

(** Complexity-penalized fitness *)
let penalized_fitness ?(complexity_weight=0.01) base_fitness p =
  let base = base_fitness p in
  base -. complexity_weight *. float_of_int p.complexity

(** {1 Population Management} *)

(** Population type *)
type population = {
  programs: program array;
  generation: int;
  best_fitness: float;
  avg_fitness: float;
}

(** Create initial random population *)
let create_population size depth =
  let programs = Array.init size (fun _ ->
    let expr = random_expr depth in
    create_program_from_expr ~generation:0 expr
  ) in
  { programs; generation = 0; best_fitness = 0.0; avg_fitness = 0.0 }

(** Evaluate population fitness *)
let evaluate_population fitness_fn pop =
  Array.iter (fun p -> p.fitness <- fitness_fn p) pop.programs;
  let total = Array.fold_left (fun acc p -> acc +. p.fitness) 0.0 pop.programs in
  let best = Array.fold_left (fun acc p -> max acc p.fitness) 0.0 pop.programs in
  { pop with 
    best_fitness = best;
    avg_fitness = total /. float_of_int (Array.length pop.programs);
  }

(** Tournament selection *)
let tournament_select ?(size=3) pop =
  let best = ref pop.programs.(Random.int (Array.length pop.programs)) in
  for _ = 1 to size - 1 do
    let candidate = pop.programs.(Random.int (Array.length pop.programs)) in
    if candidate.fitness > !best.fitness then best := candidate
  done;
  !best

(** Evolve population one generation *)
let evolve_population ?(mutation_rate=0.1) ?(crossover_rate=0.7) ?(elitism=2) fitness_fn pop =
  let n = Array.length pop.programs in
  let new_programs = Array.make n pop.programs.(0) in
  
  (* Sort by fitness for elitism *)
  let sorted = Array.copy pop.programs in
  Array.sort (fun a b -> compare b.fitness a.fitness) sorted;
  
  (* Keep elite *)
  for i = 0 to elitism - 1 do
    new_programs.(i) <- sorted.(i)
  done;
  
  (* Generate rest through crossover and mutation *)
  let i = ref elitism in
  while !i < n do
    if Random.float 1.0 < crossover_rate && !i + 1 < n then begin
      let p1 = tournament_select pop in
      let p2 = tournament_select pop in
      let (c1, c2) = crossover p1 p2 in
      new_programs.(!i) <- mutate ~rate:mutation_rate c1;
      new_programs.(!i + 1) <- mutate ~rate:mutation_rate c2;
      i := !i + 2
    end else begin
      let p = tournament_select pop in
      new_programs.(!i) <- mutate ~rate:mutation_rate p;
      incr i
    end
  done;
  
  let new_pop = { 
    programs = new_programs;
    generation = pop.generation + 1;
    best_fitness = 0.0;
    avg_fitness = 0.0;
  } in
  evaluate_population fitness_fn new_pop

(** Run MOSES evolution *)
let run_moses ?(population_size=100) ?(max_generations=100) ?(target_fitness=0.99) fitness_fn =
  let pop = ref (create_population population_size 4) in
  pop := evaluate_population fitness_fn !pop;
  
  while !pop.generation < max_generations && !pop.best_fitness < target_fitness do
    pop := evolve_population fitness_fn !pop;
    if !pop.generation mod 10 = 0 then
      Printf.printf "Generation %d: best=%.4f avg=%.4f\n" 
        !pop.generation !pop.best_fitness !pop.avg_fitness
  done;
  
  (* Return best program *)
  let sorted = Array.copy !pop.programs in
  Array.sort (fun a b -> compare b.fitness a.fitness) sorted;
  sorted.(0)

(** {1 Scheme Serialization} *)

let program_to_scheme p =
  Printf.sprintf "(moses-program (expr %s) (arity %d) (fitness %.6f) (complexity %d) (generation %d))"
    (sexpr_to_string p.expr)
    p.arity
    p.fitness
    p.complexity
    p.generation

let population_to_scheme pop =
  let programs_str = Array.to_list pop.programs 
    |> List.map program_to_scheme 
    |> String.concat "\n  " in
  Printf.sprintf "(moses-population (generation %d) (best-fitness %.6f) (avg-fitness %.6f)\n  %s)"
    pop.generation pop.best_fitness pop.avg_fitness programs_str
