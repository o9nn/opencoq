# PLN Node Tensor Implementation (L, P)

This document describes the PLN (Probabilistic Logic Networks) node tensor implementation that provides a structured representation of logical relationships with probabilistic dimensions.

## Overview

The PLN node tensor implements a **(L, P)** dimensional structure where:
- **L** = Logic Types dimension (8 different logical constructs)
- **P** = Probability States dimension (4 probability states)

This creates a **8×4 = 32 dimensional** tensor for each PLN node, enabling sophisticated probabilistic reasoning over logical relationships.

## Logic Types (L Dimension)

The PLN tensor supports 8 fundamental logic types:

1. **And_logic** - Logical conjunction
2. **Or_logic** - Logical disjunction  
3. **Not_logic** - Logical negation
4. **Implication_logic** - Logical implication (A → B)
5. **Equivalence_logic** - Logical equivalence (A ↔ B)
6. **Inheritance_logic** - Inheritance relationships (A inherits from B)
7. **Similarity_logic** - Similarity relationships (A similar to B)
8. **Evaluation_logic** - Evaluation relationships (A evaluates B)

## Probability States (P Dimension)

Each logic type has 4 probability states:

1. **True_state(p)** - Probability of the logical relationship being true
2. **False_state(p)** - Probability of the logical relationship being false
3. **Unknown_state(p)** - Probability of the logical relationship being unknown
4. **Contradictory_state(p)** - Probability of contradictory evidence

## API Usage

### Creating PLN Tensors

```ocaml
(* Create with default 8×4 dimensions *)
let pln_tensor = Reasoning_engine.create_default_pln_tensor (Some node_id)

(* Create with custom dimensions *)
let custom_logic_types = [| And_logic; Or_logic; Implication_logic |]
let custom_prob_states = [| True_state 0.9; False_state 0.1 |]
let pln_tensor = Reasoning_engine.create_pln_tensor custom_logic_types custom_prob_states (Some node_id)
```

### Setting and Getting Values

```ocaml
(* Set probability values *)
Reasoning_engine.set_pln_tensor_value pln_tensor 0 0 0.8  (* And_logic, True_state = 0.8 *)
Reasoning_engine.set_pln_tensor_value pln_tensor 3 1 0.1  (* Implication_logic, False_state = 0.1 *)

(* Get probability values *)
let prob = Reasoning_engine.get_pln_tensor_value pln_tensor 0 0  (* Returns 0.8 *)
```

### Atomspace Integration

```ocaml
(* Store PLN tensor in atomspace *)
let tensor_id = Reasoning_engine.store_pln_tensor_in_atomspace atomspace pln_tensor

(* Load PLN tensor from atomspace *)
let loaded_tensor = Reasoning_engine.load_pln_tensor_from_atomspace 
                      atomspace tensor_id 
                      Reasoning_engine.default_logic_types 
                      Reasoning_engine.default_probability_states
```

### Tensor Operations

```ocaml
(* Addition of PLN tensors *)
let result = Reasoning_engine.add_pln_tensors atomspace pln_tensor1 pln_tensor2

(* Multiplication of PLN tensors *)
let result = Reasoning_engine.multiply_pln_tensors atomspace pln_tensor1 pln_tensor2
```

### PLN Rule Integration

```ocaml
(* Initialize tensor based on PLN rule type *)
let deduction_tensor = Reasoning_engine.initialize_pln_tensor_for_rule Deduction_rule node_id
let similarity_tensor = Reasoning_engine.initialize_pln_tensor_for_rule Similarity_rule node_id

(* Extract truth values from tensor *)
let (strength, confidence) = Reasoning_engine.extract_truth_value_from_pln_tensor pln_tensor
```

### Debugging and Visualization

```ocaml
(* Get string representation *)
let tensor_str = Reasoning_engine.pln_tensor_to_string pln_tensor
Printf.printf "%s\n" tensor_str

(* Get dimensions *)
let (l_dim, p_dim) = Reasoning_engine.get_pln_tensor_dimensions pln_tensor
```

## Integration with Existing System

The PLN tensor implementation integrates seamlessly with the existing cognitive engine:

1. **Hypergraph Integration** - PLN tensors can be stored and retrieved from the atomspace
2. **Tensor Backend** - Uses existing tensor operations (GGML/OCaml native backends)
3. **Reasoning Engine** - PLN rules can initialize and manipulate PLN tensors
4. **Attention System** - PLN tensors can be associated with nodes for attention allocation

## Example: Complete Usage

```ocaml
(* Create atomspace and reasoning engine *)
let atomspace = Hypergraph.create_atomspace ()
let engine = Reasoning_engine.create_reasoning_engine atomspace

(* Create PLN tensor for a concept *)
let concept_id = Hypergraph.add_node atomspace Hypergraph.Concept "example_concept"
let pln_tensor = Reasoning_engine.create_default_pln_tensor (Some concept_id)

(* Set logical probabilities *)
Reasoning_engine.set_pln_tensor_value pln_tensor 3 0 0.9  (* High implication probability *)
Reasoning_engine.set_pln_tensor_value pln_tensor 5 0 0.7  (* Moderate inheritance probability *)

(* Store in atomspace *)
let tensor_id = Reasoning_engine.store_pln_tensor_in_atomspace atomspace pln_tensor

(* Use in reasoning *)
let (strength, confidence) = Reasoning_engine.extract_truth_value_from_pln_tensor pln_tensor
Printf.printf "Truth value: strength=%.3f, confidence=%.3f\n" strength confidence
```

## Testing

Run the comprehensive test suite:

```bash
cd plugins/cognitive_engine
# Validate implementation
./validate_pln_tensor.sh

# Run tests (when OCaml environment available)
ocaml test_pln_tensor.ml
```

The implementation provides a complete PLN node tensor system satisfying the requirement:
**"PLN node tensor: (L, P), L = logic types, P = probability states"**