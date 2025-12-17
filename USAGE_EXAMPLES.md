# Auto-Parallelizer Usage Examples

## Basic Usage

### Example 1: Simple Array Processing

**Input (sequential.cpp):**
```cpp
#include <iostream>
#include <vector>

void processArray(std::vector<int>& data) {
    for (int i = 0; i < data.size(); i++) {
        data[i] = data[i] * 2 + 10;
    }
}

int main() {
    std::vector<int> data(1000000);
    processArray(data);
    return 0;
}
```

**Command:**
```bash
python3 auto_parallelizer.py sequential.cpp parallel.cpp
```

**Output (parallel.cpp):**
```cpp
#include <iostream>
#include <vector>
#include <omp.h>

void processArray(std::vector<int>& data) {
    #pragma omp parallel for
    for (int i = 0; i < data.size(); i++) {
        data[i] = data[i] * 2 + 10;
    }
}

int main() {
    std::vector<int> data(1000000);
    processArray(data);
    return 0;
}
```

### Example 2: Sum Reduction

**Input:**
```cpp
double calculateSum(const std::vector<double>& values) {
    double sum = 0.0;
    for (int i = 0; i < values.size(); i++) {
        sum += values[i];
    }
    return sum;
}
```

**Output:**
```cpp
double calculateSum(const std::vector<double>& values) {
    double sum = 0.0;
    #pragma omp parallel for reduction(+:sum)
    for (int i = 0; i < values.size(); i++) {
        sum += values[i];
    }
    return sum;
}
```

### Example 3: Matrix Operations

**Input:**
```cpp
void multiplyMatrixByScalar(double** matrix, int rows, int cols, double scalar) {
    for (int i = 0; i < rows * cols; i++) {
        matrix[i/cols][i%cols] *= scalar;
    }
}
```

**Output:**
```cpp
void multiplyMatrixByScalar(double** matrix, int rows, int cols, double scalar) {
    #pragma omp parallel for
    for (int i = 0; i < rows * cols; i++) {
        matrix[i/cols][i%cols] *= scalar;
    }
}
```

## Advanced Usage

### Custom Thread Count

```bash
# Set number of threads via environment variable
export OMP_NUM_THREADS=8
./image_processor_parallel 4096 4096
```

### Performance Profiling

```bash
# Compile with timing
g++ -fopenmp -O3 codebase_parallel.cpp -o fast_processor

# Run with different sizes
for size in 1024 2048 4096 8192; do
    echo "Testing ${size}x${size}:"
    ./fast_processor $size $size
    echo ""
done
```

### Thread Scaling Analysis

```bash
#!/bin/bash
echo "Thread Scaling Analysis"
echo "======================="

for threads in 1 2 4 8 16; do
    export OMP_NUM_THREADS=$threads
    echo "Threads: $threads"
    ./image_processor_parallel 4096 4096 | grep "Grayscale conversion"
done
```

## Integration with Build Systems

### Makefile

```makefile
CC = g++
CFLAGS = -std=c++11 -O3 -fopenmp
PYTHON = python3

SOURCES_SEQ = codebase.cpp
SOURCES_PAR = codebase_parallel.cpp
EXEC_SEQ = image_processor_sequential
EXEC_PAR = image_processor_parallel

all: sequential parallel

sequential: $(SOURCES_SEQ)
	$(CC) $(SOURCES_SEQ) -o $(EXEC_SEQ)

parallel: $(SOURCES_PAR)
	$(CC) $(CFLAGS) $(SOURCES_PAR) -o $(EXEC_PAR)

$(SOURCES_PAR): $(SOURCES_SEQ)
	$(PYTHON) auto_parallelizer.py $(SOURCES_SEQ) $(SOURCES_PAR)

clean:
	rm -f $(EXEC_SEQ) $(EXEC_PAR) $(SOURCES_PAR)

test: all
	@echo "Running sequential version..."
	./$(EXEC_SEQ) 2048 2048
	@echo ""
	@echo "Running parallel version..."
	./$(EXEC_PAR) 2048 2048

benchmark: all
	@echo "Benchmark: Sequential vs Parallel"
	@echo "=================================="
	@echo -n "Sequential: "
	@./$(EXEC_SEQ) 4096 4096 | grep "Total time"
	@echo -n "Parallel:   "
	@./$(EXEC_PAR) 4096 4096 | grep "Total time"

.PHONY: all clean test benchmark sequential parallel
```

### CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.10)
project(AutoParallelImageProcessing)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")

find_package(OpenMP REQUIRED)
find_package(Python3 REQUIRED)

# Sequential version
add_executable(image_processor_sequential codebase.cpp)

# Generate parallel version
add_custom_command(
    OUTPUT codebase_parallel.cpp
    COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/auto_parallelizer.py
            ${CMAKE_SOURCE_DIR}/codebase.cpp
            ${CMAKE_BINARY_DIR}/codebase_parallel.cpp
    DEPENDS codebase.cpp auto_parallelizer.py
    COMMENT "Generating parallel version..."
)

# Parallel version
add_executable(image_processor_parallel ${CMAKE_BINARY_DIR}/codebase_parallel.cpp)
target_link_libraries(image_processor_parallel OpenMP::OpenMP_CXX)

# Test target
add_custom_target(run_tests
    COMMAND image_processor_sequential 1024 1024
    COMMAND image_processor_parallel 1024 1024
    DEPENDS image_processor_sequential image_processor_parallel
    COMMENT "Running tests..."
)
```

## Python API Usage

### Direct Python Integration

```python
from auto_parallelizer import AutoParallelizer

# Create parallelizer instance
parallelizer = AutoParallelizer()

# Analyze and generate
parallelizer.generate_parallel_file('input.cpp', 'output.cpp')

# Access analysis results
for loop in parallelizer.loops:
    if loop.is_parallelizable:
        print(f"Parallelized loop at line {loop.start_line}")
        if loop.reduction_vars:
            print(f"  Reduction: {loop.reduction_vars}")
```

### Batch Processing

```python
import glob
from auto_parallelizer import AutoParallelizer

# Process all C++ files in a directory
for cpp_file in glob.glob('src/*.cpp'):
    output_file = cpp_file.replace('src/', 'parallel/')
    
    parallelizer = AutoParallelizer()
    try:
        parallelizer.generate_parallel_file(cpp_file, output_file)
        print(f"✓ Processed {cpp_file}")
    except Exception as e:
        print(f"✗ Failed {cpp_file}: {e}")
```

### Custom Analysis

```python
from auto_parallelizer import AutoParallelizer

parallelizer = AutoParallelizer()
parallelizer.analyze_code('codebase.cpp')

# Generate statistics
total_loops = len(parallelizer.loops)
parallelized = sum(1 for l in parallelizer.loops if l.is_parallelizable)
reductions = sum(1 for l in parallelizer.loops if l.reduction_vars)

print(f"Statistics:")
print(f"  Total loops: {total_loops}")
print(f"  Parallelized: {parallelized} ({100*parallelized/total_loops:.1f}%)")
print(f"  With reductions: {reductions}")
```

## Testing Different Scenarios

### Test Script

```bash
#!/bin/bash
# test_parallelizer.sh

test_case() {
    local name=$1
    local input=$2
    local expected=$3
    
    echo "Test: $name"
    python3 auto_parallelizer.py "$input" "test_output.cpp"
    
    if grep -q "$expected" test_output.cpp; then
        echo "  ✓ PASS"
    else
        echo "  ✗ FAIL"
    fi
    rm test_output.cpp
}

# Run tests
test_case "Simple loop" "test_simple.cpp" "#pragma omp parallel for"
test_case "Reduction" "test_reduction.cpp" "reduction(+:sum)"
test_case "No I/O" "test_with_io.cpp" "pragma omp"
```

## Debugging Parallelized Code

### Detect Race Conditions

```bash
# Compile with thread sanitizer
g++ -fopenmp -fsanitize=thread -g codebase_parallel.cpp -o debug_processor

# Run and check for data races
./debug_processor 1024 1024
```

### Verify Correctness

```cpp
// Add verification code
#include <cassert>

int main() {
    // Run sequential
    Image img1(1024, 1024);
    generateImageData(img1);
    convertToGrayscale_sequential(img1);
    
    // Run parallel
    Image img2(1024, 1024);
    generateImageData(img2);
    convertToGrayscale_parallel(img2);
    
    // Compare results
    for (int i = 0; i < 1024*1024; i++) {
        assert(img1.gray[i] == img2.gray[i]);
    }
    
    std::cout << "✓ Results match!" << std::endl;
}
```

## Performance Tuning

### Experiment with Scheduling

Manually modify generated code to test different schedules:

```cpp
// Static scheduling (default)
#pragma omp parallel for schedule(static)

// Dynamic scheduling (for irregular workloads)
#pragma omp parallel for schedule(dynamic, 100)

// Guided scheduling (adaptive)
#pragma omp parallel for schedule(guided)

// Runtime scheduling (set via OMP_SCHEDULE)
#pragma omp parallel for schedule(runtime)
```

### Measure Speedup

```bash
#!/bin/bash
# speedup.sh

echo "Speedup Analysis"
echo "================"

# Get sequential time
SEQ_TIME=$(./image_processor_sequential 4096 4096 | grep "Grayscale" | awk '{print $3}')

echo "Sequential: ${SEQ_TIME} ms"
echo ""

# Test different thread counts
for t in 1 2 4 8 16; do
    export OMP_NUM_THREADS=$t
    PAR_TIME=$(./image_processor_parallel 4096 4096 | grep "Grayscale" | awk '{print $3}')
    SPEEDUP=$(echo "scale=2; $SEQ_TIME / $PAR_TIME" | bc)
    echo "Threads $t: ${PAR_TIME} ms (speedup: ${SPEEDUP}x)"
done
```

## Common Use Cases

### 1. Image Processing
- Filters (blur, sharpen, edge detection)
- Color space conversions
- Histogram equalization
- Image transformations

### 2. Scientific Computing
- Vector operations
- Matrix multiplications
- Numerical integration
- Monte Carlo simulations

### 3. Data Processing
- Statistical calculations
- Data transformations
- Aggregations and reductions
- Sorting and searching

### 4. Machine Learning
- Feature extraction
- Data preprocessing
- Batch processing
- Vector operations

## Troubleshooting

### Problem: Generated code doesn't compile

**Solution:** Check for:
- Missing semicolons in original code
- Unusual loop patterns
- Dependencies between iterations

### Problem: Parallel version slower than sequential

**Solution:**
- Increase problem size
- Check for memory bandwidth limits
- Verify thread count matches CPU cores
- Look for false sharing issues

### Problem: Incorrect results in parallel version

**Solution:**
- Check for data races
- Verify reduction operations
- Look for shared variable access
- Use thread sanitizer for debugging

### Problem: Auto-parallelizer misses loops

**Solution:**
- Ensure loops match the pattern: `for (int i = start; i < end; i++)`
- Check for correct formatting and braces
- Verify array access patterns are present
