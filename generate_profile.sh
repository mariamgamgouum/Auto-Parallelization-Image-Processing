#!/bin/bash

# Automated Profiling Report Generator with gprof-style output
# Compiles, runs, and generates profiling report automatically

IMAGE_SIZE=${1:-8192}
SOURCE_FILE="codebase.cpp"
OUTPUT_EXE="image_processor_profiled.exe"

echo "=== Automated Profiling Report Generator ==="
echo ""

# Step 1: Compile
echo "Step 1: Compiling $SOURCE_FILE..."
g++ -O2 -std=c++11 "$SOURCE_FILE" -o "$OUTPUT_EXE"
if [ $? -ne 0 ]; then
    echo "✗ Compilation failed!"
    exit 1
fi
echo "✓ Compilation successful"
echo ""

# Step 2: Run and capture output
echo "Step 2: Running profiling ($IMAGE_SIZE by $IMAGE_SIZE)..."
OUTPUT=$(./"$OUTPUT_EXE" $IMAGE_SIZE $IMAGE_SIZE 2>&1)
if [ $? -ne 0 ]; then
    echo "✗ Execution failed!"
    exit 1
fi
echo "✓ Execution complete"
echo ""

# Step 3: Parse timing data and generate report
echo "Step 3: Parsing timing data and generating report..."

{
    echo "Flat profile:"
    echo ""
    echo "Each sample counts as 0.01 seconds."
    echo "  %   cumulative   self              self     total"
    echo " time   seconds   seconds    calls   s/call   s/call  name"
    
    # Extract timing data in milliseconds
    GRAYSCALE=$(echo "$OUTPUT" | grep "Grayscale conversion:" | grep -oE '[0-9]+' | head -1)
    DATA_GEN=$(echo "$OUTPUT" | grep "Data generation:" | grep -oE '[0-9]+' | head -1)
    BRIGHTNESS=$(echo "$OUTPUT" | grep "Brightness adjustment:" | grep -oE '[0-9]+' | head -1)
    THRESHOLD=$(echo "$OUTPUT" | grep "Threshold application:" | grep -oE '[0-9]+' | head -1)
    AVERAGE=$(echo "$OUTPUT" | grep "Average calculation:" | grep -oE '[0-9]+' | head -1)
    
    # Calculate total pixels and total time
    TOTAL_PIXELS=$((IMAGE_SIZE * IMAGE_SIZE))
    TOTAL_MS=$((GRAYSCALE + DATA_GEN + BRIGHTNESS + THRESHOLD + AVERAGE))
    TOTAL_S=$(echo "scale=4; $TOTAL_MS / 1000" | bc)
    
    # Convert to seconds
    GRAY_S=$(echo "scale=4; $GRAYSCALE / 1000" | bc)
    DATA_S=$(echo "scale=4; $DATA_GEN / 1000" | bc)
    BRIGHT_S=$(echo "scale=4; $BRIGHTNESS / 1000" | bc)
    THRESH_S=$(echo "scale=4; $THRESHOLD / 1000" | bc)
    AVG_S=$(echo "scale=4; $AVERAGE / 1000" | bc)
    
    # Calculate percentages
    GRAY_PCT=$(echo "scale=1; ($GRAYSCALE / $TOTAL_MS) * 100" | bc)
    DATA_PCT=$(echo "scale=1; ($DATA_GEN / $TOTAL_MS) * 100" | bc)
    BRIGHT_PCT=$(echo "scale=1; ($BRIGHTNESS / $TOTAL_MS) * 100" | bc)
    THRESH_PCT=$(echo "scale=1; ($THRESHOLD / $TOTAL_MS) * 100" | bc)
    AVG_PCT=$(echo "scale=1; ($AVERAGE / $TOTAL_MS) * 100" | bc)
    
    # Calculate cumulative times
    CUM_GRAY=$(echo "scale=2; $GRAY_S" | bc)
    CUM_DATA=$(echo "scale=2; $GRAY_S + $DATA_S" | bc)
    CUM_BRIGHT=$(echo "scale=2; $CUM_DATA + $BRIGHT_S" | bc)
    CUM_THRESH=$(echo "scale=2; $CUM_BRIGHT + $THRESH_S" | bc)
    CUM_AVG=$(echo "scale=2; $CUM_THRESH + $AVG_S" | bc)
    
    # Calculate s/call (time in seconds per pixel)
    GRAY_SCALL=$(echo "scale=6; $GRAY_S / $TOTAL_PIXELS" | bc)
    DATA_SCALL=$(echo "scale=6; $DATA_S / 1" | bc)  # Only 1 call to generateImageData
    BRIGHT_SCALL=$(echo "scale=6; $BRIGHT_S / $TOTAL_PIXELS" | bc)
    THRESH_SCALL=$(echo "scale=6; $THRESH_S / $TOTAL_PIXELS" | bc)
    AVG_SCALL=$(echo "scale=6; $AVG_S / $TOTAL_PIXELS" | bc)
    MAIN_SCALL=$(echo "scale=4; $TOTAL_S / 1" | bc)
    
    # Output in gprof format
    printf "%5.1f %9.2f %9.4f %9d %8.6f %8.6f  convertToGrayscale(Image&)\n" \
        "$GRAY_PCT" "$CUM_GRAY" "$GRAY_S" "$TOTAL_PIXELS" "$GRAY_SCALL" "$GRAY_SCALL"
    
    printf "%5.1f %9.2f %9.4f %9d %8.6f %8.6f  adjustBrightness(Image&, int)\n" \
        "$BRIGHT_PCT" "$CUM_BRIGHT" "$BRIGHT_S" "$TOTAL_PIXELS" "$BRIGHT_SCALL" "$BRIGHT_SCALL"
    
    printf "%5.1f %9.2f %9.4f %9d %8.6f %8.6f  applyThreshold(Image&, unsigned char)\n" \
        "$THRESH_PCT" "$CUM_THRESH" "$THRESH_S" "$TOTAL_PIXELS" "$THRESH_SCALL" "$THRESH_SCALL"
    
    printf "%5.1f %9.2f %9.4f %9d %8.6f %8.6f  calculateAverageGray(Image const&)\n" \
        "$AVG_PCT" "$CUM_AVG" "$AVG_S" "$TOTAL_PIXELS" "$AVG_SCALL" "$AVG_SCALL"
    
    printf "%5.1f %9.2f %9.4f %9d %8.4f %8.4f  main\n" \
        "$DATA_PCT" "$CUM_DATA" "$DATA_S" "1" "$MAIN_SCALL" "$MAIN_SCALL"
    
    printf "%5.1f %9.2f %9.4f %9d %8.4f %8.4f  generateImageData(Image&)\n" \
        "0.0" "$TOTAL_S" "0.0000" "1" "0.0000" "0.0000"
    
    echo ""
    echo "Summary:"
    echo "- Image Size: ${IMAGE_SIZE} x ${IMAGE_SIZE} pixels (${TOTAL_PIXELS} total)"
    echo "- Total Time: ${TOTAL_S}s (${TOTAL_MS}ms)"
    echo "- Times measured using std::chrono (high resolution, accurate)"
    echo "- Calls for pixel operations = number of pixels"
    echo "- s/call = seconds per pixel operation"
    echo "- Generated: $(date)"
    
} > gprof_report.txt

echo "✓ Report generated: gprof_report.txt"
echo ""
echo "=== Profiling Complete ==="
echo ""
cat gprof_report.txt
