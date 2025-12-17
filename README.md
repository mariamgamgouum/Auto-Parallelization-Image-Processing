# Auto-Parallelization Image Processing

An automatic parallelization tool that converts sequential C++ image processing code to OpenMP-parallelized code dynamically.

## Overview

This project demonstrates automatic parallelization of sequential C++ code using OpenMP. It includes:

1. **Sequential Implementation** (`codebase.cpp`) - Original sequential image processing pipeline
2. **Auto-Parallelizer** (`auto_parallelizer.py`) - Python tool that automatically analyzes and parallelizes code
3. **Parallel Implementation** (`codebase_parallel.cpp`) - Auto-generated OpenMP parallelized version

## Features

The auto-parallelizer automatically:
- Detects parallelizable for-loops in C++ code
- Identifies reduction operations (e.g., sum accumulation)
- Generates appropriate OpenMP pragmas (`#pragma omp parallel for`)
- Handles reduction clauses for parallel accumulation
- Adds OpenMP header includes
- Produces compilation-ready parallel code

## How to Use

### Quick Start - Run Full Comparison

```bash
./run_comparison.sh
```

This script will:
1. Run the auto-parallelizer to generate parallel code
2. Compile both sequential and parallel versions
3. Run benchmarks on both versions
4. Display timing comparisons

### Manual Usage

#### 1. Generate Parallel Code

```bash
python3 auto_parallelizer.py codebase.cpp codebase_parallel.cpp
```

The tool will analyze the sequential code and generate a report showing which loops were parallelized.

#### 2. Compile Sequential Version

```bash
g++ codebase.cpp -o image_processor_sequential
```

#### 3. Compile Parallel Version

```bash
g++ -fopenmp codebase_parallel.cpp -o image_processor_parallel
```

#### 4. Run and Compare

```bash
# Sequential version
./image_processor_sequential 2048 2048

# Parallel version  
./image_processor_parallel 2048 2048
```

## Image Processing Pipeline

The code implements a typical image processing pipeline with 5 operations:

1. **Generate Synthetic Data** - Creates test RGB image data
2. **RGB to Grayscale Conversion** - Converts color image to grayscale
3. **Calculate Average** - Computes average grayscale value (uses reduction)
4. **Brightness Adjustment** - Adjusts image brightness
5. **Threshold Application** - Applies binary threshold

All operations except data generation are automatically parallelized by the tool.

## Auto-Parallelizer Technical Details

### Loop Detection
- Identifies standard C-style for loops with integer iterators
- Analyzes loop bounds and iteration patterns

### Parallelizability Analysis
- Checks for data dependencies
- Detects array access patterns
- Identifies I/O operations (not parallelizable)
- Detects break/continue statements

### Reduction Detection
- Automatically identifies accumulation patterns (e.g., `sum += ...`)
- Generates appropriate `reduction(+:var)` clauses

### Code Generation
- Inserts pragmas at correct positions
- Maintains code formatting and indentation
- Handles loop iterator scope correctly
- Avoids redundant private variable declarations

## Command Line Arguments

Both executables accept optional image dimensions:

```bash
./image_processor_sequential [width] [height]
./image_processor_parallel [width] [height]
```

Default: 1024x1024 pixels

## Requirements

- **C++ Compiler**: g++ with OpenMP support
- **Python**: Python 3.x
- **Operating System**: Linux, macOS, or Windows with MinGW

## Performance

The parallel version typically achieves significant speedup on multi-core systems. Speedup depends on:
- Number of CPU cores
- Image size (larger images benefit more)
- Memory bandwidth
- Thread scheduling overhead

Typical speedup: 2-4x on quad-core systems

## Project Structure

```
.
├── codebase.cpp                 # Sequential implementation
├── codebase_parallel.cpp        # Auto-generated parallel version
├── auto_parallelizer.py         # Auto-parallelization tool
├── run_comparison.sh            # Automated test script
├── README.md                    # This file
└── CSE355 Project Specification.pdf  # Project specification
```

## How the Auto-Parallelizer Works

1. **Parsing**: Reads the C++ source file line by line
2. **Function Detection**: Identifies function boundaries for context
3. **Loop Detection**: Uses regex to find for-loop patterns
4. **Dependency Analysis**: 
   - Checks for array access patterns
   - Identifies reduction operations
   - Detects non-parallelizable constructs
5. **Code Generation**:
   - Adds `#include <omp.h>` header
   - Inserts OpenMP pragmas before parallelizable loops
   - Maintains correct indentation and formatting
6. **Report Generation**: Provides detailed analysis of parallelization

## Example Output

### Auto-Parallelizer Report
```
Auto-Parallelization Report
==================================================
Input file: codebase.cpp
Output file: codebase_parallel.cpp

Parallelized 5 out of 5 loops:

✓ Loop 1 in function 'generateImageData' (line 32)
✓ Loop 2 in function 'convertToGrayscale' (line 42)
✓ Loop 3 in function 'calculateAverageGray' (line 53)
  - Reduction operations: [('sum', '+')]
✓ Loop 4 in function 'adjustBrightness' (line 62)
✓ Loop 5 in function 'applyThreshold' (line 73)

==================================================
Parallel code generated successfully!
```

## Future Enhancements

Potential improvements to the auto-parallelizer:
- Support for nested loops
- More sophisticated dependency analysis
- Detection of other reduction operations (min, max, multiplication)
- Support for parallel sections and tasks
- Loop scheduling clauses (static, dynamic, guided)
- SIMD vectorization hints

## License

Educational project for CSE355 - Theory of Computation

## Authors

Auto-Parallelization Image Processing Project
