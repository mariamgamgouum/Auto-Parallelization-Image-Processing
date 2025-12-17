#!/bin/bash

echo "=================================="
echo "Auto-Parallelization Demonstration"
echo "=================================="
echo ""

# Step 1: Run auto-parallelizer
echo "Step 1: Running Auto-Parallelizer..."
python3 auto_parallelizer.py codebase.cpp codebase_parallel.cpp
echo ""

# Step 2: Compile sequential version
echo "Step 2: Compiling sequential version..."
g++ codebase.cpp -o image_processor_sequential
echo "✓ Sequential version compiled"
echo ""

# Step 3: Compile parallel version
echo "Step 3: Compiling parallel version..."
g++ -fopenmp codebase_parallel.cpp -o image_processor_parallel
echo "✓ Parallel version compiled"
echo ""

# Step 4: Run benchmarks
echo "Step 4: Running benchmarks..."
echo ""
echo "--- SEQUENTIAL VERSION ---"
./image_processor_sequential 2048 2048
echo ""
echo ""
echo "--- PARALLEL VERSION ---"
./image_processor_parallel 2048 2048
echo ""

echo "=================================="
echo "Comparison Complete!"
echo "=================================="
