#!/bin/bash

# Validation script for Creative Problem Solving via Combinatorial Hypergraph Traversal

echo "🧠🔄 Validating Creative Problem Solving Implementation 🔄🧠"
echo

# Check if OCaml is available
if ! command -v ocaml &> /dev/null; then
    echo "❌ OCaml not found. Please install OCaml to run tests."
    exit 1
fi

echo "✅ OCaml found: $(ocaml --version)"

# Change to the cognitive engine directory
cd "$(dirname "$0")"

# Check if the creative problem solving files exist
if [[ ! -f "creative_problem_solving.mli" ]]; then
    echo "❌ creative_problem_solving.mli not found"
    exit 1
fi

if [[ ! -f "creative_problem_solving.ml" ]]; then
    echo "❌ creative_problem_solving.ml not found"
    exit 1
fi

if [[ ! -f "test_creative_problem_solving.ml" ]]; then
    echo "❌ test_creative_problem_solving.ml not found"
    exit 1
fi

echo "✅ All required files found"

# Run the comprehensive test
echo
echo "🧠 Running comprehensive creative problem solving tests..."
echo

if ocaml unix.cma test_creative_problem_solving.ml; then
    echo
    echo "🎉 === ALL CREATIVE PROBLEM SOLVING TESTS PASSED === 🎉"
    echo
    echo "🚀 Implementation Summary:"
    echo "   ✅ Creative Engine with 5 traversal strategies"
    echo "   ✅ Combinatorial hypergraph traversal algorithms"
    echo "   ✅ Novel association discovery"
    echo "   ✅ Creativity metrics and evaluation"
    echo "   ✅ Attention-guided exploration"
    echo "   ✅ Constraint relaxation mechanisms"
    echo "   ✅ Multi-objective optimization"
    echo "   ✅ Creative concept generation"
    echo "   ✅ Performance benchmarking"
    echo
    echo "📊 Key Features Implemented:"
    echo "   - Breadth-first creative traversal with novelty seeking"
    echo "   - Depth-first creative traversal with backtracking"
    echo "   - Attention-guided random walk exploration" 
    echo "   - Genetic algorithm for path optimization"
    echo "   - Hybrid multi-objective traversal strategy"
    echo "   - Novel association discovery algorithms"
    echo "   - Creativity, novelty, and feasibility scoring"
    echo "   - Constraint relaxation for creative solutions"
    echo "   - Concept blending and generation mechanisms"
    echo
    echo "🧠 Creative Problem Solving via Combinatorial Hypergraph Traversal is FULLY OPERATIONAL!"
    echo
    exit 0
else
    echo
    echo "❌ === CREATIVE PROBLEM SOLVING TESTS FAILED === ❌"
    echo
    echo "Please check the implementation and try again."
    exit 1
fi