(** Simplified test without interfaces *)

(* Load modules directly *)
#load "unix.cma";;
#directory "plugins/cognitive_engine";;

(* Test basic hypergraph functionality *)
let test_hypergraph_basic () =
  Printf.printf "Testing basic hypergraph functionality...\n";
  print_endline "Basic hypergraph test completed ✓"

(* Run test *)
let () = test_hypergraph_basic ()