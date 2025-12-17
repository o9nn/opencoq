# Hypergraph Cognition Kernel for OpenCoq

## Overview

This implementation provides the foundational architecture for a neural-symbolic, hypergraph-centric cognitive engine in OpenCoq. The system is designed for modular growth, dynamic attention allocation, and agentic self-organization, using Scheme for cognitive representation and hypergraph encoding.

## Architecture

### Core Subsystems

1. **Memory System** (`hypergraph.ml`)
   - AtomSpace-inspired persistent hypergraph store
   - Support for Nodes, Links, and Tensors
   - CRUD operations with Scheme S-expression serialization
   - Truth value and attention value management

2. **Task System** (`task_system.ml`)
   - Distributed cognitive operations scheduler
   - Priority-based task queue
   - Dependency management
   - Performance monitoring

3. **Attention System** (`attention_system.ml`)
   - ECAN (Economic Attention Networks) implementation
   - Dynamic attention allocation
   - Attention spread and decay mechanisms
   - Economic dynamics for resource allocation

4. **Reasoning Engine** (`reasoning_engine.ml`)
   - PLN (Probabilistic Logic Networks) stubs
   - MOSES (Meta-Optimizing Semantic Evolutionary Search) integration points
   - Forward and backward chaining
   - Pattern discovery capabilities

5. **Meta-Cognition System** (`metacognition.ml`)
   - Introspection and self-assessment
   - Self-modification capabilities
   - Goal management
   - Learning and adaptation

6. **Cognitive Engine** (`cognitive_engine.ml`)
   - Main integration module
   - High-level cognitive operations
   - Natural language processing interface
   - State management

## Key Features

### Hypergraph Data Structures

```scheme
(node (id 1) (type Concept) (name "test_concept") 
      (attention (sti 0.0) (lti 0.0) (vlti 0.0))
      (truth 1.0 1.0))

(link (id 1) (type Inheritance) (outgoing (1 2))
      (attention (sti 0.0) (lti 0.0) (vlti 0.0))
      (truth 1.0 1.0))
```

### Attention Allocation

- **STI (Short-Term Importance)**: Dynamic attention values
- **LTI (Long-Term Importance)**: Persistent importance values
- **VLTI (Very Long-Term Importance)**: Structural importance
- **Economic Model**: Attention as limited resource with rent collection

### Task Scheduling

- **Priority Levels**: High, Medium, Low
- **Task Types**: Reasoning, Pattern Matching, Attention Allocation, Memory Consolidation, Meta-cognition
- **Dependency Management**: Task execution ordering
- **Concurrent Processing**: Configurable parallel task execution

### Self-Modification

- **Introspection**: System performance monitoring
- **Adaptation**: Parameter tuning based on performance
- **Goal Management**: Dynamic goal setting and adjustment
- **Learning**: Experience-based improvement

## Usage Examples

### Basic Knowledge Creation

```ocaml
let atomspace = Hypergraph.create_atomspace () in
let concept_id = Hypergraph.add_node atomspace Hypergraph.Concept "example" in
let relation_id = Hypergraph.add_link atomspace Hypergraph.Inheritance [concept_id] in
```

### Cognitive Engine Initialization

```ocaml
let config = Cognitive_engine.default_engine_config in
let engine = Cognitive_engine.create_cognitive_engine config in
Cognitive_engine.bootstrap_basic_knowledge engine;
Cognitive_engine.single_cognitive_cycle engine;
```

### Natural Language Interface

```ocaml
let response = Cognitive_engine.process_natural_language engine "learn new pattern" in
let answer = Cognitive_engine.answer_question engine "what is learning?" in
```

## Scheme Integration

The system provides comprehensive Scheme S-expression serialization for all data structures, enabling:

- **Knowledge Export/Import**: Complete cognitive state serialization
- **Interactive Programming**: Scheme-based cognitive operations
- **Visualization**: S-expression format for cognitive flowcharts
- **Integration**: Easy integration with other symbolic AI systems

## Future Extensions

### Phase 2: Neural Integration
- Tensor operations with ggml backend
- Neural-symbolic fusion
- Gradient-based attention optimization

### Phase 3: Advanced Reasoning
- Complete PLN implementation
- MOSES evolutionary search
- Causal reasoning
- Temporal logic

### Phase 4: Emergent Capabilities
- Self-improving architectures
- Recursive self-modification
- Autonomous goal generation
- Creative problem solving

## Testing

Run the basic functionality test:

```bash
cd /home/runner/work/opencoq/opencoq
./working_test
```

Expected output:
```
🧠 Hypergraph Cognition Kernel Foundation is working! 🧠
```

## Technical Details

### Compilation Requirements
- OCaml 4.14.1+
- Unix module
- Coq build system integration

### Module Dependencies
```
Hypergraph (foundation)
├── Task_system
├── Attention_system  
├── Reasoning_engine
├── Metacognition
└── Cognitive_engine (integration)
```

### Memory Management
- Hashtable-based storage for efficiency
- Configurable attention decay and forgetting
- Garbage collection of low-attention atoms

### Performance Characteristics
- O(1) node/link lookup
- O(n) attention spread operations
- Configurable concurrent task processing
- Memory usage scales with knowledge base size

## Cognitive Flowchart

```
[Perception] → [AtomSpace] → [Attention Allocation] → [Task Scheduling]
      ↓              ↑              ↓                     ↓
[Meta-cognition] ← [Reasoning] ← [Pattern Recognition] ← [Execution]
      ↓              ↓              ↓                     ↓
[Self-modification] → [Learning] → [Memory Consolidation] → [Action]
```

This foundational implementation establishes the core architecture for a truly cognitive AI system, with the flexibility and modularity needed for future enhancements and emergent capabilities.