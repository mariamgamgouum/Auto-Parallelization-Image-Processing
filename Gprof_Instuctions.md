# GPROF-Based Parallelization Analysis Report

## Overview
This document describes how to use GPROF profiling to analyze the sequential codebase and identify parallelization opportunities. This is a documentation-only feature that provides insights for developers working on parallelizing image processing pipelines.

## Purpose
- Analyze sequential code performance using GPROF
- Identify computationally intensive functions suitable for parallelization
- Generate actionable bullet-point recommendations for each function
- Document the parallelization strategy before actual implementation

## Prerequisites
- GPROF installed (usually comes with GCC)
- Sequential code compiled with profiling flags
- Basic understanding of OpenMP parallelization patterns

## Step 1: Compile with Profiling Support

### Modified Makefile Target
```bash
# Add this target to your Makefile
profile_build:
	@echo "Building sequential version with profiling support..."
	$(CC) $(CFLAGS) -pg $(SOURCES_SEQ) -o $(EXEC_SEQ)_profiled
	@echo "✓ Profiled version built: $(EXEC_SEQ)_profiled"
```

### Compilation Command
```bash
g++ -pg -O0 -fno-inline -std=c++11 codebase.cpp -o image_processor_profiled
```

## Step 2: Run Profiling

### Execute with Representative Workload
```bash
./image_processor_profiled 8192 8192  # Large image for meaningful profiling
```

This generates `gmon.out` file containing profiling data.

### Generate Profiling Report and selects the first 50 objects from terminal to put and ignores extra data
```bash
gprof -b image_processor_profiled.exe gmon.out | Select-Object -First 50 > gprof_report.txt
```

## Step 3: Analyze GPROF Output

### Expected GPROF Report Structure
```
Flat profile:

Each sample counts as 0.01 seconds.
  %   cumulative   self              self     total
 time   seconds   seconds    calls   s/call   s/call  name
 45.2      0.45     0.45 16777216     0.00     0.00  convertToGrayscale(Image&)
 25.1      0.70     0.25 16777216     0.00     0.00  adjustBrightness(Image&, int)
 15.3      0.85     0.15 16777216     0.00     0.00  applyThreshold(Image&, unsigned char)
 10.2      0.95     0.10 16777216     0.00     0.00  calculateAverageGray(Image const&)
  4.2      0.99     0.04        1     0.04     0.99  main
  0.0      0.99     0.00        1     0.00     0.00  generateImageData(Image&)
```

## Step 4: Parallelization Recommendations by Function

### 1. `generateImageData(Image&)`
**GPROF Analysis:**
- Typically shows minimal time (0-2%)
- Single function call per execution
- Memory-bound initialization pattern

**Parallelization Assessment:**
- ✅ **NOT RECOMMENDED** for parallelization
- Very low impact on overall performance
- Sequential initialization is sufficient
- No significant performance gain expected

**Action Items:**
- [ ] Keep as sequential function
- [ ] Consider only if called multiple times per execution
- [ ] Document as intentionally sequential

---

### 2. `convertToGrayscale(Image&)`
**GPROF Analysis:**
- Typically shows 40-50% of execution time
- Called once per image processing pipeline
- Large loop (width × height iterations)
- Independent pixel operations

**Parallelization Assessment:**
- ✅ **HIGH PRIORITY** for parallelization
- Embarrassingly parallel problem
- No data dependencies between pixels
- Significant performance gain expected

**Action Items:**
- [ ] Apply `#pragma omp parallel for` to the main loop
- [ ] Ensure private variables for thread safety
- [ ] Consider dynamic scheduling for load balancing
- [ ] Test with different thread counts (2, 4, 8, 16)
- [ ] Verify correctness across different image sizes
- [ ] Document speedup achieved vs. sequential version

---

### 3. `calculateAverageGray(const Image&)`
**GPROF Analysis:**
- Typically shows 10-20% of execution time  
- Called once per image processing pipeline
- Large loop with reduction pattern
- Accumulates sum across all pixels

**Parallelization Assessment:**
- ✅ **HIGH PRIORITY** for parallelization
- Reduction operation pattern
- Requires careful handling of shared variable
- Significant performance gain expected

**Action Items:**
- [ ] Apply `#pragma omp parallel for reduction(+:sum)`
- [ ] Ensure proper reduction variable handling
- [ ] Consider atomic operations if reduction not suitable
- [ ] Test numerical accuracy with parallel reduction
- [ ] Benchmark against sequential version
- [ ] Document reduction pattern for educational purposes

---

### 4. `adjustBrightness(Image&, int)`
**GPROF Analysis:**
- Typically shows 20-30% of execution time
- Called once per image processing pipeline
- Large loop with conditional operations
- Independent pixel operations with clamping

**Parallelization Assessment:**
- ✅ **HIGH PRIORITY** for parallelization
- Embarrassingly parallel problem
- No data dependencies between pixels
- Simple arithmetic operations per pixel
- Significant performance gain expected

**Action Items:**
- [ ] Apply `#pragma omp parallel for` to the main loop
- [ ] Verify clamping operations are thread-safe
- [ ] Consider SIMD optimizations in addition to OpenMP
- [ ] Test edge cases with different brightness values
- [ ] Measure performance with various image sizes
- [ ] Document thread safety analysis


---

### 5. `applyThreshold(Image&, unsigned char)`
**GPROF Analysis:**
- Typically shows 15-25% of execution time
- Called once per image processing pipeline
- Large loop with conditional operations
- Simple threshold comparison per pixel

**Parallelization Assessment:**
- ✅ **HIGH PRIORITY** for parallelization
- Embarrassingly parallel problem
- No data dependencies between pixels
- Minimal computational complexity per pixel
- Significant performance gain expected

**Action Items:**
- [ ] Apply `#pragma omp parallel for` to the main loop
- [ ] Verify threshold comparison is thread-safe
- [ ] Consider branch prediction optimization
- [ ] Test with different threshold values
- [ ] Benchmark performance improvements
- [ ] Document as example of simple parallel pattern
