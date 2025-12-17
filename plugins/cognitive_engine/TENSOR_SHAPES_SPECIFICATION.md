# Tensor Shapes and Degrees of Freedom Specification

## Overview

This document provides comprehensive documentation of all tensor shapes, dimensions, and degrees of freedom used throughout the OpenCoq cognitive engine (Phases 2-4).

---

## Phase 2: Neural Integration

### 2.1 Neural Activation Tensor

**Shape**: `(N, D, F)`

- **N** (Neurons): Number of neural units in the layer (typical: 10-1000)
- **D** (Degrees of Freedom): Dimensionality of neural state space (typical: 5-20)
- **F** (Feature Depth): Number of features extracted per neuron (typical: 8-64)

**Purpose**: Represents neural activations in the neural-symbolic fusion layer.

**Typical Values**:
- Small network: `(10, 5, 8)` = 400 elements
- Medium network: `(100, 10, 32)` = 32,000 elements  
- Large network: `(1000, 20, 64)` = 1,280,000 elements

**Operations**:
```ocaml
(* Create neural tensor *)
let shape = [n; d; f] in
let data = Array.init (n * d * f) (fun i -> random_float ()) in

(* Apply neural operations *)
let activated = Tensor_backend.tensor_relu ctx shape data in
let normalized = Tensor_backend.tensor_sigmoid ctx shape activated in
```

**Degrees of Freedom**: `N × D × F` total parameters

---

### 2.2 Attention Tensor

**Shape**: `(A, T)`

- **A** (Attention Heads): Number of parallel attention mechanisms (typical: 4-16)
- **T** (Temporal Depth): Number of time steps in attention history (typical: 5-50)

**Purpose**: Implements multi-head attention with temporal memory for ECAN-inspired economic allocation.

**Typical Values**:
- Basic attention: `(4, 5)` = 20 time-sliced heads
- Standard attention: `(8, 10)` = 80 time-sliced heads
- Advanced attention: `(16, 30)` = 480 time-sliced heads

**Operations**:
```ocaml
(* Create attention tensor *)
let attention_tensor = Attention_system.create_attention_tensor num_heads temporal_depth in

(* Initialize attention heads *)
for head_id = 0 to num_heads - 1 do
  Attention_system.initialize_attention_head attention_tensor head_id atom_ids
done;

(* Update attention over time *)
Attention_system.update_attention_temporal attention_tensor timestep head_id values
```

**Degrees of Freedom**: `A × T` attention values + `A` head-specific parameters

**Economic Properties**:
- Each attention head has economic budget
- Temporal decay: `attention(t) = attention(t-1) × (1 - decay_rate)`
- Spread mechanism: `Δ attention(i) = α × Σⱼ (weight(i,j) × attention(j))`

---

### 2.3 Neural-Symbolic Embedding Tensor

**Shape**: `(S, E)`

- **S** (Symbolic Concepts): Number of symbolic atoms in AtomSpace (variable)
- **E** (Embedding Dimension): Dimensionality of neural embedding space (typical: 32-512)

**Purpose**: Maps symbolic concepts to dense neural representations for fusion.

**Typical Values**:
- Small knowledge base: `(100, 64)` = 6,400 elements
- Medium knowledge base: `(1000, 128)` = 128,000 elements
- Large knowledge base: `(10000, 256)` = 2,560,000 elements

**Fusion Strategies**:

1. **Embedding-Based**: Direct symbolic → neural mapping
   ```
   symbolic_id → embedding[E] via lookup table
   ```

2. **Compositional**: Build embeddings from structure
   ```
   link([n₁, n₂, ...]) → f(embed(n₁), embed(n₂), ...)
   ```

3. **Attention-Guided**: Use attention to weight embeddings
   ```
   embed_weighted(s) = Σᵢ αᵢ × embed(sᵢ) where Σ αᵢ = 1
   ```

4. **Hierarchical**: Multi-level embedding hierarchy
   ```
   level₀: base embeddings
   level₁: composed from level₀
   level₂: abstracted from level₁
   ```

**Degrees of Freedom**: `S × E` embedding weights + fusion parameters

---

### 2.4 Hypergraph Encoding Tensor

**Shape**: `(N, K, H)`

- **N** (Nodes): Number of nodes in hypergraph
- **K** (Hyperedge Connectivity): Maximum hyperedge arity (typical: 2-10)
- **H** (Hierarchical Levels): Number of abstraction levels (typical: 2-5)

**Purpose**: Encodes hypergraph structure as neural activations for processing.

**Typical Values**:
- Simple graph: `(100, 2, 1)` = 200 elements (binary edges only)
- Hypergraph: `(500, 5, 3)` = 7,500 elements
- Deep hypergraph: `(1000, 10, 5)` = 50,000 elements

**Operations**:
```ocaml
(* Encode node in hypergraph structure *)
let encode_node node_id atomspace =
  let neighbors = Hypergraph.get_neighbors atomspace node_id in
  let connectivity = List.length neighbors in
  let hierarchy_level = Hypergraph.get_abstraction_level node_id in
  (node_id, connectivity, hierarchy_level)
```

**Degrees of Freedom**: `N + (N × K)` (nodes + edges) × `H` levels

---

## Phase 3: Advanced Reasoning

### 3.1 PLN Logic Tensor

**Shape**: `(L, P)`

- **L** (Logic Types): Number of inference rule types (fixed: 6)
  1. Deduction
  2. Induction  
  3. Abduction
  4. Analogy
  5. Revision
  6. Bayesian
  
- **P** (Probability States): Probabilistic state dimensions (fixed: 4)
  1. Strength (truth value strength)
  2. Confidence (certainty of truth value)
  3. Count (evidence count)
  4. Weight (importance weight)

**Shape Value**: `(6, 4)` = 24 parameters per logical inference

**Purpose**: Represents Probabilistic Logic Networks inference state.

**Operations**:
```ocaml
(* Apply PLN rule with tensor state *)
type pln_state = {
  rule_type : int;         (* 0-5: which logic type *)
  strength : float;        (* 0.0-1.0 *)
  confidence : float;      (* 0.0-1.0 *)
  count : float;          (* evidence count *)
  weight : float;         (* importance *)
}

let apply_rule pln_state premises =
  match pln_state.rule_type with
  | 0 -> deduction premises pln_state
  | 1 -> induction premises pln_state
  | 2 -> abduction premises pln_state
  | 3 -> analogy premises pln_state
  | 4 -> revision premises pln_state
  | 5 -> bayes premises pln_state
```

**Degrees of Freedom**: `L × P = 24` total per inference

**Truth Value Formulas**:
- **Deduction**: `sAB × sBC → sAC` where `s = strength`
- **Induction**: `P(B|A) from observed (A,B) pairs`
- **Revision**: `TV_new = (TV_old × w_old + TV_obs × w_obs) / (w_old + w_obs)`

---

### 3.2 MOSES Evolutionary Tensor

**Shape**: `(G, S, E)`

- **G** (Genome Length): Number of genes/instructions in program (typical: 10-100)
- **S** (Semantic Depth): Depth of semantic parse tree (typical: 3-10)
- **E** (Evolutionary Epochs): Number of generations evolved (typical: 10-1000)

**Purpose**: Represents evolutionary search space for program optimization.

**Typical Values**:
- Simple evolution: `(20, 5, 10)` = 1,000 gene-steps
- Standard evolution: `(50, 7, 100)` = 35,000 gene-steps
- Deep evolution: `(100, 10, 500)` = 500,000 gene-steps

**Program Representation**:
```ocaml
type gene = 
  | Variable of string
  | Constant of float
  | Operator of string * gene list

type program = {
  genome : gene array;        (* length G *)
  semantic_depth : int;       (* max S *)
  fitness : float;
  generation : int;           (* current E *)
}
```

**Genetic Operations**:

1. **Crossover**: 
   ```
   offspring = parent1[0..k] @ parent2[k..G]
   where k ∈ random(0, G)
   ```

2. **Mutation**:
   ```
   For each gene g ∈ genome:
     if random() < mutation_rate:
       g' = random_gene()
   ```

3. **Selection**:
   ```
   P(selection) ∝ fitness^selection_pressure
   ```

**Degrees of Freedom**: 
- Per program: `G × 2^S` possible parse trees
- Per population: `population_size × G × 2^S`
- Over evolution: `E × population_size × G × 2^S`

**Fitness Function**:
```ocaml
fitness(program) = 
  semantic_correctness × 0.4 +
  syntactic_validity × 0.2 +
  efficiency × 0.2 +
  novelty × 0.2
```

---

### 3.3 Causal Reasoning Tensor

**Shape**: `(C, L)`

- **C** (Cause-Effect Pairs): Number of causal relationships (variable)
- **L** (Logical Chain Length): Maximum length of causal chains (typical: 3-20)

**Purpose**: Encodes causal graph structure for Pearl-style causal inference.

**Typical Values**:
- Simple causality: `(10, 5)` = 50 chain steps
- Complex causality: `(100, 10)` = 1,000 chain steps  
- Deep causality: `(500, 20)` = 10,000 chain steps

**Causal Levels** (Pearl's Hierarchy):

1. **Association** (L=1): `P(Y|X)` - observational
   ```
   Do we observe correlation?
   ```

2. **Intervention** (L=2-5): `P(Y|do(X))` - interventional
   ```
   What happens if we force X?
   ```

3. **Counterfactual** (L>5): `P(Y_X|X', Y')` - counterfactual
   ```
   What would have happened if X had been different?
   ```

**Operations**:
```ocaml
(* Encode causal relationship *)
type causal_link = {
  cause_id : node_id;
  effect_id : node_id;
  strength : float;        (* 0.0-1.0 *)
  chain_position : int;    (* 0 to L-1 *)
  intervention_type : int; (* 0=obs, 1=do, 2=counterfactual *)
}

(* Compute causal effect *)
let causal_effect cause effect chain_length =
  (* Trace path from cause to effect with max length chain_length *)
  let path = find_causal_path cause effect chain_length in
  let total_effect = List.fold_left ( *. ) 1.0 (List.map (fun link -> link.strength) path) in
  total_effect
```

**Degrees of Freedom**: `C × L` causal strengths

**Temporal Logic Integration**:
```
Temporal operators:
- Always(φ): φ holds at all future times
- Eventually(φ): φ holds at some future time  
- Until(φ, ψ): φ holds until ψ becomes true
- Since(φ, ψ): φ has held since ψ was true

Causal-temporal: cause at t₁ → effect at t₂ where t₂ > t₁
```

---

## Phase 4: Emergent Capabilities

### 4.1 Meta-Cognitive Tensor

**Shape**: `(R, M)`

- **R** (Recursion Depth): Levels of meta-reasoning (typical: 2-7)
  - R=1: Base cognition (reasoning about problems)
  - R=2: Meta-cognition (reasoning about reasoning)
  - R=3: Meta-meta-cognition (reasoning about meta-reasoning)
  - R>3: Higher-order reflection
  
- **M** (Modifiable Modules): Number of system components (fixed: 7)
  1. Hypergraph (memory)
  2. Tensor Backend (neural)
  3. Task System (scheduling)
  4. Attention System (focus)
  5. Reasoning Engine (inference)
  6. Metacognition (self-modification)
  7. Cognitive Engine (integration)

**Shape Value**: `(R, 7)` where R varies by recursion depth

**Purpose**: Enables recursive self-improvement and meta-reasoning.

**Operations**:
```ocaml
(* Meta-cognitive recursion *)
let rec meta_reason depth max_depth state =
  if depth >= max_depth then state
  else
    let self_assessment = introspect_at_level depth state in
    let modifications = plan_modifications depth self_assessment in
    let new_state = apply_modifications state modifications in
    meta_reason (depth + 1) max_depth new_state

(* Introspect module performance *)
let introspect_module module_id depth =
  match module_id with
  | 0 -> measure_hypergraph_performance ()
  | 1 -> measure_tensor_performance ()
  | 2 -> measure_task_performance ()
  | 3 -> measure_attention_performance ()
  | 4 -> measure_reasoning_performance ()
  | 5 -> measure_metacognition_performance ()
  | 6 -> measure_integration_performance ()
```

**Degrees of Freedom**: `R × M × parameter_count` where parameter_count varies by module

**Self-Modification Types**:
1. **Parameter tuning**: Adjust thresholds, rates, weights
2. **Structure modification**: Add/remove nodes, rewire connections
3. **Algorithm selection**: Choose between alternative strategies
4. **Goal adjustment**: Update objectives and priorities

---

### 4.2 Autonomous Goal Tensor

**Shape**: `(G, C)`

- **G** (Goal Categories): Types of cognitive goals (fixed: 6)
  1. Learning (acquire new knowledge)
  2. Optimization (improve efficiency)
  3. Exploration (discover novel patterns)
  4. Consolidation (strengthen memories)
  5. Social (communicate, collaborate)
  6. Self-Improvement (meta-level enhancement)
  
- **C** (Context Dimension): Cognitive context vector size (typical: 16-128)

**Purpose**: Generates and manages autonomous cognitive goals.

**Typical Values**:
- Basic autonomy: `(6, 16)` = 96 context elements
- Standard autonomy: `(6, 32)` = 192 context elements
- Advanced autonomy: `(6, 128)` = 768 context elements

**Goal Representation**:
```ocaml
type autonomous_goal = {
  category : int;              (* 0-5: which goal type *)
  context : float array;       (* dimension C *)
  priority : float;            (* 0.0-1.0 *)
  expected_value : float;      (* estimated utility *)
  time_horizon : float;        (* when to achieve *)
  dependencies : int list;     (* other goal IDs *)
}
```

**Goal Generation Process**:
```ocaml
(* Generate goal based on current cognitive state *)
let generate_goal category context_vec =
  (* Analyze current state *)
  let current_knowledge = assess_knowledge_state () in
  let current_performance = assess_performance () in
  let current_resources = assess_resource_availability () in
  
  (* Identify gap or opportunity *)
  let goal_vector = match category with
  | 0 -> identify_learning_opportunities current_knowledge
  | 1 -> identify_optimization_targets current_performance  
  | 2 -> identify_exploration_frontiers current_knowledge
  | 3 -> identify_consolidation_needs current_knowledge
  | 4 -> identify_social_opportunities context_vec
  | 5 -> identify_self_improvement_areas current_performance
  in
  
  (* Create goal with priority *)
  let priority = compute_goal_priority goal_vector current_resources in
  { category; context = goal_vector; priority; ... }
```

**Degrees of Freedom**: `G × C` context weights + goal-specific parameters

---

### 4.3 Creative Problem-Solving Tensor

**Shape**: `(P, S, N)`

- **P** (Problem Space Size): Number of possible problem states (variable)
- **S** (Solution Strategies): Number of creative strategies (fixed: 5)
  1. Breadth-first creative
  2. Depth-first creative
  3. Random walk attention
  4. Genetic traversal
  5. Hybrid multi-objective
  
- **N** (Novelty Dimensions): Feature dimensions for measuring novelty (typical: 8-32)

**Purpose**: Explores creative solution spaces via combinatorial hypergraph traversal.

**Typical Values**:
- Small problem: `(100, 5, 8)` = 4,000 exploration states
- Medium problem: `(1000, 5, 16)` = 80,000 exploration states
- Large problem: `(10000, 5, 32)` = 1,600,000 exploration states

**Creative Solution Representation**:
```ocaml
type solution_path = {
  nodes : node_id list;           (* path through hypergraph *)
  creativity_score : float;       (* how creative? *)
  novelty_score : float;          (* how novel? *)
  feasibility_score : float;      (* how feasible? *)
  novelty_features : float array; (* dimension N *)
}
```

**Novelty Computation**:
```ocaml
(* Measure novelty in N-dimensional feature space *)
let compute_novelty solution history novelty_dim =
  (* Extract features *)
  let features = extract_novelty_features solution novelty_dim in
  
  (* Compare to historical solutions *)
  let distances = List.map (fun past_solution ->
    let past_features = extract_novelty_features past_solution novelty_dim in
    euclidean_distance features past_features
  ) history in
  
  (* Novelty = minimum distance to any past solution *)
  let min_distance = List.fold_left min infinity distances in
  1.0 /. (1.0 +. min_distance) (* normalize to [0,1] *)
```

**Traversal Strategies**:

1. **Breadth-First Creative**:
   ```
   Queue all neighbors at depth d before depth d+1
   + creativity heuristic for neighbor ordering
   ```

2. **Attention-Guided Random Walk**:
   ```
   P(next_node | current_node) ∝ attention(next_node) × creativity_bonus
   ```

3. **Genetic Traversal**:
   ```
   Treat paths as genomes
   Crossover: exchange path segments
   Mutation: random path modifications
   Selection: fitness = creativity × feasibility
   ```

**Degrees of Freedom**: `P × S × N` exploration states

---

## Integration: Cross-Phase Tensor Operations

### Gradient-Based Attention Optimization

Combines Phase 2 (attention) with Phase 3 (reasoning) and Phase 4 (meta-cognition):

```ocaml
(* Compute gradients for attention allocation *)
let compute_attention_gradient attention_tensor reasoning_state meta_state =
  (* Current attention distribution *)
  let current_attention = get_attention_distribution attention_tensor in
  
  (* Desired attention based on reasoning needs *)
  let reasoning_gradient = compute_reasoning_based_gradient reasoning_state in
  
  (* Meta-cognitive adjustment *)
  let meta_adjustment = compute_meta_adjustment meta_state in
  
  (* Combined gradient *)
  let gradient = Array.mapi (fun i curr ->
    let reasoning_term = reasoning_gradient.(i) in
    let meta_term = meta_adjustment.(i) in
    0.5 *. reasoning_term +. 0.3 *. meta_term -. 0.2 *. curr
  ) current_attention in
  
  gradient
```

**Tensor Shape**: `(A, T, L, R)` - attention heads × temporal × logic types × recursion

---

### Neural-Symbolic-Meta Integration

Full stack integration from Phase 2 → Phase 3 → Phase 4:

```
Layer 1 (Neural): Raw tensor operations
  ↓ embedding: (N,D,F) → (S,E)
Layer 2 (Symbolic): AtomSpace hypergraph
  ↓ reasoning: (L,P) logic operations
Layer 3 (Meta): Self-modification
  ↓ recursion: (R,M) meta-reasoning
Layer 4 (Emergent): Goal generation + creativity
```

**Total System Degrees of Freedom**:
```
DOF_total = DOF_neural + DOF_attention + DOF_embedding +
            DOF_pln + DOF_moses + DOF_causal +
            DOF_meta + DOF_goals + DOF_creative

Typical: 10⁴ to 10⁶ parameters depending on problem scale
```

---

## Performance Considerations

### Memory Efficiency

| Tensor Type | Shape | Elements | Memory (float32) |
|-------------|-------|----------|------------------|
| Neural | (100, 10, 32) | 32,000 | 128 KB |
| Attention | (8, 10) | 80 | 320 B |
| Embedding | (1000, 128) | 128,000 | 512 KB |
| PLN | (6, 4) | 24 | 96 B |
| MOSES | (50, 7, 100) | 35,000 | 140 KB |
| Causal | (100, 10) | 1,000 | 4 KB |
| Meta | (5, 7) | 35 | 140 B |
| Goals | (6, 32) | 192 | 768 B |
| Creative | (1000, 5, 16) | 80,000 | 320 KB |
| **TOTAL** | - | **276,331** | **~1.1 MB** |

### Computational Complexity

| Operation | Complexity | Notes |
|-----------|-----------|-------|
| Tensor add/multiply | O(N×D×F) | Elementwise |
| Matrix multiply | O(N²×D) | Dense matmul |
| Attention spread | O(A×N) | Per head × nodes |
| PLN inference | O(L×P×N) | Rules × premises |
| MOSES evolution | O(G×S×pop) | Genome × depth × population |
| Causal inference | O(C×L²) | Chain traversal |
| Meta-reasoning | O(R×M×ops) | Recursive depth × modules |
| Goal generation | O(G×C×N) | Categories × context × nodes |
| Creative search | O(P×S×depth) | Exponential in search depth |

### Optimization Strategies

1. **Sparse Tensors**: Use sparse representations where >90% values are zero
2. **Attention Pruning**: Focus on top-k attention values
3. **Early Stopping**: Terminate MOSES when fitness plateaus
4. **Causal Caching**: Cache frequently-used causal chains
5. **Meta Throttling**: Limit recursion depth based on utility
6. **Lazy Evaluation**: Compute tensor operations only when needed

---

## Validation and Testing

Each tensor shape must be validated:

```ocaml
(* Shape validation *)
let validate_tensor_shape shape expected_dims =
  assert (List.length shape = expected_dims);
  assert (List.for_all (fun dim -> dim > 0) shape)

(* Degrees of freedom validation *)
let validate_dof actual expected tolerance =
  let ratio = float_of_int actual /. float_of_int expected in
  assert (ratio >= 1.0 -. tolerance && ratio <= 1.0 +. tolerance)

(* Integration validation *)
let validate_integration () =
  (* Ensure all phases connect properly *)
  let neural_output = phase2_neural_ops () in
  let symbolic_input = phase3_symbolic_reasoning neural_output in
  let meta_feedback = phase4_meta_cognition symbolic_input in
  assert (compatible neural_output symbolic_input meta_feedback)
```

---

## Summary Table

| Phase | Tensor | Shape | Purpose | DOF |
|-------|--------|-------|---------|-----|
| 2 | Neural | (N,D,F) | Neural activations | N×D×F |
| 2 | Attention | (A,T) | Multi-head temporal attention | A×T |
| 2 | Embedding | (S,E) | Symbol→neural mapping | S×E |
| 2 | Hypergraph | (N,K,H) | Graph structure encoding | N×K×H |
| 3 | PLN | (L,P) | Logic inference | L×P |
| 3 | MOSES | (G,S,E) | Evolutionary programs | G×S×E |
| 3 | Causal | (C,L) | Causal chains | C×L |
| 4 | Meta | (R,M) | Self-modification | R×M |
| 4 | Goals | (G,C) | Autonomous objectives | G×C |
| 4 | Creative | (P,S,N) | Problem-solving paths | P×S×N |

**Total Degrees of Freedom**: O(10⁴ - 10⁶) depending on problem scale and network size.

---

## References

1. **GGML**: Tensor operations backend
2. **ECAN**: Economic Attention Networks (Goertzel et al.)
3. **PLN**: Probabilistic Logic Networks (Goertzel et al.)
4. **MOSES**: Meta-Optimizing Semantic Evolutionary Search (Looks et al.)
5. **Pearl's Causality**: "Causality: Models, Reasoning, and Inference"
6. **Hypergraph Theory**: "Handbook of Graph Theory" (Gross et al.)

---

*Last Updated*: November 2025  
*Version*: 1.0 (Phases 2-4 Integration)  
*Maintained by*: OpenCoq Cognitive Engine Team
