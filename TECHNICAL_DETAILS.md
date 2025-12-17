# Auto-Parallelizer Technical Documentation

## Architecture Overview

The auto-parallelizer is a source-to-source compiler that transforms sequential C++ code into OpenMP-parallelized code. It uses pattern matching, static analysis, and code generation techniques to automatically identify and parallelize loops.

## Components

### 1. LoopInfo Dataclass

Stores information about detected loops:
- `start_line`: Line number where the loop begins
- `end_line`: Line number where the loop ends  
- `loop_var`: Loop iterator variable name (e.g., 'i')
- `is_parallelizable`: Boolean indicating if loop can be safely parallelized
- `reduction_vars`: List of variables involved in reduction operations
- `private_vars`: List of variables that should be private to each thread
- `function_name`: Name of the function containing the loop
- `indent`: Indentation level for proper code formatting

### 2. AutoParallelizer Class

Main class implementing the parallelization logic.

#### Key Methods

**`analyze_code(filepath)`**
- Entry point for analysis
- Reads source file
- Orchestrates detection and generation phases
- Returns list of parallelized code lines

**`_detect_functions()`**
- Scans code for function definitions
- Builds context map: line number → function name
- Used to provide context in analysis reports
- Regex pattern: `^\s*(void|int|double|float|unsigned|char|long)\s+(\w+)\s*\([^)]*\)\s*\{?`

**`_detect_loops()`**
- Identifies for-loop patterns in code
- Regex pattern: `^\s*for\s*\(\s*int\s+(\w+)\s*=\s*[^;]+;\s*\2\s*<[^;]+;\s*\2\+\+\s*\)`
- Matches standard C-style loops: `for (int i = start; i < end; i++)`
- Captures loop variable name for dependency analysis
- Calls `_find_loop_end()` to determine loop body boundaries
- Calls `_analyze_loop_body()` to assess parallelizability

**`_find_loop_end(start_line)`**
- Tracks opening and closing braces
- Returns line number of loop's closing brace
- Handles nested braces correctly

**`_analyze_loop_body(start, end, loop_var)`**
- Analyzes loop body for parallelization safety
- Returns tuple: `(is_parallelizable, reduction_vars, private_vars)`

Key checks:
1. **Array access patterns**: Looks for `array[loop_var]` patterns
2. **Reduction operations**: Detects `variable += expression` patterns
3. **I/O operations**: Flags loops with cout/cin/printf/scanf
4. **Control flow**: Detects break/continue statements
5. **Data dependencies**: Basic analysis for race conditions

**`_generate_parallel_code()`**
- Generates parallelized version of code
- Adds `#include <omp.h>` header if missing
- Inserts OpenMP pragmas before parallelizable loops
- Updates output strings to indicate parallel version
- Maintains correct line offsets after insertions

**`_generate_omp_pragma(loop)`**
- Generates appropriate OpenMP pragma for a loop
- Base pragma: `#pragma omp parallel for`
- Adds `reduction(+:var)` clause for accumulation patterns
- Excludes loop iterator from private clause (automatically private in OpenMP)
- Maintains original code indentation

## Parallelization Patterns

### 1. Simple Parallel Loop

**Input:**
```cpp
for (int i = 0; i < size; i++) {
    array[i] = array[i] * 2;
}
```

**Output:**
```cpp
#pragma omp parallel for
for (int i = 0; i < size; i++) {
    array[i] = array[i] * 2;
}
```

### 2. Reduction Pattern

**Input:**
```cpp
for (int i = 0; i < size; i++) {
    sum += array[i];
}
```

**Output:**
```cpp
#pragma omp parallel for reduction(+:sum)
for (int i = 0; i < size; i++) {
    sum += array[i];
}
```

### 3. Private Variables

Variables declared inside the loop are automatically private in OpenMP, so no explicit private clause is needed:

**Input:**
```cpp
for (int i = 0; i < size; i++) {
    int temp = array[i] + offset;
    array[i] = temp;
}
```

**Output:**
```cpp
#pragma omp parallel for
for (int i = 0; i < size; i++) {
    int temp = array[i] + offset;
    array[i] = temp;
}
```

## Detection Algorithms

### Loop Detection Algorithm

1. Scan each line of source code
2. Match against for-loop regex pattern
3. Extract loop variable name using backreference `\2`
4. Find loop body boundaries using brace counting
5. Store loop information for analysis

### Parallelizability Analysis Algorithm

```
function analyze_loop_body(start, end, loop_var):
    body = lines[start:end]
    
    // Check for parallelizable array access pattern
    if body contains pattern "array[loop_var]":
        is_parallelizable = true
    else:
        is_parallelizable = false
    
    // Detect reduction operations
    for each pattern "var += expr" in body:
        if expr contains "array[loop_var]":
            add (var, '+') to reduction_vars
    
    // Check for non-parallelizable constructs
    if body contains I/O operations:
        is_parallelizable = false
    if body contains break or continue:
        is_parallelizable = false
    
    return (is_parallelizable, reduction_vars, [])
```

### Code Generation Algorithm

```
function generate_parallel_code():
    output = copy of input lines
    offset = 0
    
    // Add OpenMP header
    if "#include <omp.h>" not in output:
        find last #include line
        insert "#include <omp.h>" after it
        offset = 1
    
    // Insert pragmas (in reverse order to maintain line numbers)
    for each loop in reverse(parallelizable_loops):
        pragma = generate_pragma(loop)
        insert pragma at (loop.start_line + offset)
    
    // Update output messages
    replace "Sequential" with "Parallel" in titles
    add thread count output
    
    return output
```

## Limitations and Future Work

### Current Limitations

1. **Loop Patterns**: Only detects standard `for (int i = 0; i < n; i++)` patterns
2. **Dependency Analysis**: Basic analysis, may miss complex dependencies
3. **Nested Loops**: Not explicitly optimized for nested loop parallelization
4. **Reduction Operations**: Only detects `+=` operator
5. **Loop Scheduling**: Uses default OpenMP scheduling (no static/dynamic clauses)

### Planned Enhancements

1. **Advanced Patterns**:
   - Support for `i--`, `i+=step`, and other iteration patterns
   - Detection of nested loop parallelization opportunities
   - Support for while and do-while loops

2. **Sophisticated Analysis**:
   - Data flow analysis for dependency detection
   - Pointer aliasing analysis
   - Function call side effect analysis
   - Loop-carried dependency detection

3. **Extended Reduction Support**:
   - Min/max reductions: `reduction(min:var)`, `reduction(max:var)`
   - Multiplication: `reduction(*:var)`
   - Logical operations: `reduction(&&:var)`, `reduction(||:var)`
   - Custom reduction operations

4. **Scheduling Optimizations**:
   - Add `schedule(static)` for uniform work distribution
   - Add `schedule(dynamic)` for irregular workloads
   - Add `schedule(guided)` for adaptive scheduling
   - Chunk size optimization

5. **SIMD Support**:
   - Add `#pragma omp simd` for vectorization
   - Detect SIMD-friendly operations
   - Add alignment hints

6. **Advanced OpenMP Features**:
   - Task parallelism: `#pragma omp task`
   - Parallel sections: `#pragma omp sections`
   - Worksharing constructs
   - Thread affinity and binding

## Testing Strategy

### Unit Tests
- Loop detection accuracy
- Reduction pattern recognition
- Pragma generation correctness
- Edge case handling

### Integration Tests
- Full file parallelization
- Compilation of generated code
- Correctness verification
- Performance benchmarking

### Benchmark Tests
- Sequential vs parallel timing
- Speedup calculations
- Scalability analysis (varying thread counts)
- Problem size impact

## Performance Considerations

### Parallelization Overhead
- Thread creation/destruction cost
- Memory bandwidth limitations
- Cache effects and false sharing
- Load imbalance

### When Parallelization Helps
- Large data sets (>100K elements)
- Compute-intensive operations
- Independent iterations
- Multi-core systems available

### When Parallelization May Hurt
- Small data sets (<10K elements)
- Memory-bound operations
- Significant thread overhead
- Single-core systems

## OpenMP Best Practices

The auto-parallelizer follows these best practices:

1. **Loop Iterator Privacy**: Loop variables are automatically private
2. **Reduction Clauses**: Properly handled for accumulation patterns
3. **No Redundant Clauses**: Avoids unnecessary private declarations
4. **Default Scheduling**: Uses OpenMP default (typically static)
5. **Header Inclusion**: Ensures `#include <omp.h>` is present

## Compilation Flags

### Required
- `-fopenmp`: Enable OpenMP support in GCC/Clang
- `/openmp`: Enable OpenMP support in MSVC

### Recommended
- `-O3`: Maximum optimization level
- `-march=native`: CPU-specific optimizations
- `-ffast-math`: Aggressive math optimizations (if safe)

### Debug
- `-g`: Include debug symbols
- `-fsanitize=thread`: Thread sanitizer for race detection

## Environment Variables

Key OpenMP environment variables:

- `OMP_NUM_THREADS=N`: Set number of threads
- `OMP_SCHEDULE="type,chunk"`: Set loop scheduling
- `OMP_PROC_BIND=true`: Enable thread affinity
- `OMP_PLACES=cores`: Thread placement policy

Example:
```bash
export OMP_NUM_THREADS=4
export OMP_SCHEDULE="dynamic,100"
./image_processor_parallel 2048 2048
```

## References

- OpenMP 5.0 Specification
- "Using OpenMP: Portable Shared Memory Parallel Programming" by Chapman et al.
- Intel OpenMP Documentation
- GCC OpenMP Implementation Guide
