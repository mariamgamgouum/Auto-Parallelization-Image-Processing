# Quick Start Guide

Get started with the Auto-Parallelizer in 60 seconds!

## Prerequisites

- C++ compiler with OpenMP support (g++ recommended)
- Python 3.x
- Linux, macOS, or Windows with MinGW

## Installation

1. Clone or download the repository
2. Navigate to the project directory

```bash
cd Auto-Parallelization-Image-Processing
```

## Option 1: One-Command Demo (Recommended)

Run everything automatically:

```bash
./run_comparison.sh
```

This will:
1. Generate parallel code from sequential code
2. Compile both versions
3. Run benchmarks
4. Display performance comparison

## Option 2: Using Makefile

### Build Everything

```bash
make all
```

### Run Tests

```bash
make test
```

### Run Benchmarks

```bash
make benchmark
```

### Validate Correctness

```bash
./validate_correctness.sh
```

## Option 3: Step-by-Step Manual

### Step 1: Generate Parallel Code

```bash
python3 auto_parallelizer.py codebase.cpp codebase_parallel.cpp
```

You'll see a report like:
```
Auto-Parallelization Report
==================================================
Parallelized 5 out of 5 loops:
✓ Loop 1 in function 'generateImageData'
✓ Loop 2 in function 'convertToGrayscale'
✓ Loop 3 in function 'calculateAverageGray'
  - Reduction operations: [('sum', '+')]
...
```

### Step 2: Compile Sequential Version

```bash
g++ codebase.cpp -o image_processor_sequential
```

### Step 3: Compile Parallel Version

```bash
g++ -fopenmp codebase_parallel.cpp -o image_processor_parallel
```

### Step 4: Run and Compare

Sequential:
```bash
./image_processor_sequential 2048 2048
```

Parallel:
```bash
./image_processor_parallel 2048 2048
```

## Controlling Thread Count

Set the number of OpenMP threads:

```bash
# Use 4 threads
export OMP_NUM_THREADS=4
./image_processor_parallel 2048 2048

# Use 8 threads
export OMP_NUM_THREADS=8
./image_processor_parallel 2048 2048
```

## Testing Different Image Sizes

The executables accept optional width and height parameters:

```bash
# Small image (fast)
./image_processor_parallel 512 512

# Default size
./image_processor_parallel 1024 1024

# Large image (shows better speedup)
./image_processor_parallel 4096 4096

# Very large (if you have enough RAM)
./image_processor_parallel 8192 8192
```

## Understanding the Output

### Sequential Version Output

```
=== Sequential Image Processing Benchmark ===
Image size: 2048x2048 pixels
Total pixels: 4194304

Data generation: 32 ms
Grayscale conversion: 39 ms
Average calculation: 11 ms (avg = 124.945)
Brightness adjustment: 21 ms
Threshold application: 23 ms

=== Processing Complete ===
```

### Parallel Version Output

```
=== Parallel Image Processing Benchmark (OpenMP) ===
Image size: 2048x2048 pixels
Total pixels: 4194304
Number of threads: 2

Data generation: 16 ms
Grayscale conversion: 21 ms
Average calculation: 5 ms (avg = 124.945)
Brightness adjustment: 11 ms
Threshold application: 19 ms

=== Processing Complete ===
```

Notice:
- Title shows "Parallel" and "OpenMP"
- Thread count is displayed
- Times are generally lower (faster)
- Average value is identical (correctness maintained)

## Expected Performance

Typical speedup on a dual-core system:
- **Data generation**: ~2x speedup
- **Grayscale conversion**: ~1.8x speedup  
- **Average calculation**: ~2x speedup (with reduction)
- **Brightness adjustment**: ~1.9x speedup
- **Threshold**: ~1.2-1.8x speedup

Note: Speedup increases with:
- More CPU cores
- Larger image sizes
- Better memory bandwidth

## Troubleshooting

### "Command not found: g++"

Install g++:
```bash
# Ubuntu/Debian
sudo apt-get install g++

# macOS
xcode-select --install

# Windows
# Install MinGW from mingw-w64.org
```

### "python3: command not found"

Install Python 3:
```bash
# Ubuntu/Debian
sudo apt-get install python3

# macOS (using Homebrew)
brew install python3
```

### OpenMP not found

Install OpenMP:
```bash
# Ubuntu/Debian
sudo apt-get install libomp-dev

# macOS
brew install libomp
```

### Parallel version slower than sequential

This is normal for small images. Try:
```bash
# Use larger image
./image_processor_parallel 4096 4096

# Adjust thread count to match CPU cores
export OMP_NUM_THREADS=4  # Use your actual core count
```

### Results don't match

Run the validation script:
```bash
./validate_correctness.sh
```

If validation fails, there may be a race condition. Please report as a bug.

## What to Try Next

### Experiment with Thread Counts

```bash
for threads in 1 2 4 8; do
    export OMP_NUM_THREADS=$threads
    echo "Testing with $threads threads:"
    ./image_processor_parallel 4096 4096 | grep "Grayscale conversion"
done
```

### Test Different Image Sizes

```bash
for size in 1024 2048 4096 8192; do
    echo "Testing ${size}x${size}:"
    ./image_processor_parallel $size $size | grep "Grayscale"
done
```

### Apply to Your Own Code

```bash
# Parallelize your own C++ file
python3 auto_parallelizer.py your_file.cpp your_file_parallel.cpp

# Compile with OpenMP
g++ -fopenmp your_file_parallel.cpp -o your_program
```

## Documentation

For more detailed information, see:

- **README.md** - Full project documentation
- **TECHNICAL_DETAILS.md** - Architecture and algorithms
- **USAGE_EXAMPLES.md** - Advanced usage and examples

## Get Help

Common commands:
```bash
# Show Makefile help
make help

# Clean build artifacts
make clean

# Rebuild everything
make clean && make all

# Full test suite
make test && ./validate_correctness.sh
```

## Example Session

Here's a complete example session:

```bash
# 1. Build everything
$ make all
Compiling sequential version...
✓ Sequential version built
Compiling parallel version...
✓ Parallel version built

# 2. Run quick test
$ make test
======================================
Testing Sequential Version
======================================
=== Sequential Image Processing Benchmark ===
...

======================================
Testing Parallel Version
======================================
=== Parallel Image Processing Benchmark (OpenMP) ===
...

# 3. Validate correctness
$ ./validate_correctness.sh
================================================
Correctness Validation: Sequential vs Parallel
================================================
Testing 512x512 image:
  ✓ PASS - Average values match: 124.945
...
✓ All validation tests PASSED

# 4. Run benchmark
$ make benchmark
======================================
Performance Benchmark
======================================
Small (1024x1024):
Sequential: Grayscale conversion: 1 ms
Parallel:   Grayscale conversion: 0 ms
...

# Success! 🎉
```

## Next Steps

1. ✅ Run the demo: `./run_comparison.sh`
2. ✅ Understand the output
3. ✅ Experiment with thread counts
4. ✅ Try different image sizes
5. ✅ Apply to your own code
6. 📚 Read TECHNICAL_DETAILS.md to understand how it works
7. 🚀 Extend the auto-parallelizer for your needs

## Support

If you encounter issues:
1. Check the Troubleshooting section above
2. Review TECHNICAL_DETAILS.md for implementation details
3. Look at USAGE_EXAMPLES.md for more examples
4. Examine the generated codebase_parallel.cpp to see what was changed

Happy parallelizing! 🚀
