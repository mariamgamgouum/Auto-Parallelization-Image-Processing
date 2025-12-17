#!/bin/bash

echo "================================================"
echo "Correctness Validation: Sequential vs Parallel"
echo "================================================"
echo ""

# Compile both versions if needed
if [ ! -f "image_processor_sequential" ] || [ ! -f "image_processor_parallel" ]; then
    echo "Building executables..."
    make all > /dev/null 2>&1
    echo ""
fi

# Test different image sizes
SIZES=(512 1024 2048 4096)
ALL_PASSED=true

for SIZE in "${SIZES[@]}"; do
    echo "Testing ${SIZE}x${SIZE} image:"
    
    # Run sequential version and extract average
    SEQ_OUTPUT=$(./image_processor_sequential $SIZE $SIZE 2>&1)
    SEQ_AVG=$(echo "$SEQ_OUTPUT" | grep "avg =" | sed 's/.*avg = \([0-9.]*\).*/\1/')
    
    # Run parallel version and extract average
    PAR_OUTPUT=$(./image_processor_parallel $SIZE $SIZE 2>&1)
    PAR_AVG=$(echo "$PAR_OUTPUT" | grep "avg =" | sed 's/.*avg = \([0-9.]*\).*/\1/')
    
    # Compare results
    if [ "$SEQ_AVG" == "$PAR_AVG" ]; then
        echo "  ✓ PASS - Average values match: $SEQ_AVG"
    else
        echo "  ✗ FAIL - Average values differ!"
        echo "    Sequential: $SEQ_AVG"
        echo "    Parallel:   $PAR_AVG"
        ALL_PASSED=false
    fi
    echo ""
done

# Test with different thread counts
echo "Testing thread scalability:"
ORIGINAL_THREADS=$OMP_NUM_THREADS
THREADS=(1 2 4 8)

for T in "${THREADS[@]}"; do
    export OMP_NUM_THREADS=$T
    PAR_OUTPUT=$(./image_processor_parallel 2048 2048 2>&1)
    PAR_AVG=$(echo "$PAR_OUTPUT" | grep "avg =" | sed 's/.*avg = \([0-9.]*\).*/\1/')
    ACTUAL_THREADS=$(echo "$PAR_OUTPUT" | grep "Number of threads:" | awk '{print $4}')
    
    if [ "$PAR_AVG" == "124.945" ]; then
        echo "  ✓ Threads=$T (actual=$ACTUAL_THREADS): avg=$PAR_AVG"
    else
        echo "  ✗ Threads=$T (actual=$ACTUAL_THREADS): avg=$PAR_AVG (expected 124.945)"
        ALL_PASSED=false
    fi
done

# Restore original thread count
if [ -n "$ORIGINAL_THREADS" ]; then
    export OMP_NUM_THREADS=$ORIGINAL_THREADS
else
    unset OMP_NUM_THREADS
fi

echo ""
echo "================================================"
if [ "$ALL_PASSED" = true ]; then
    echo "✓ All validation tests PASSED"
    echo "The parallel version produces correct results!"
else
    echo "✗ Some validation tests FAILED"
    echo "Please review the differences above."
fi
echo "================================================"
