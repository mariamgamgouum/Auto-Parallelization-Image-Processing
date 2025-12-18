# Windows PowerShell Benchmark Script for Sequential vs Parallel Image Processing

# Configuration
$IMAGE_SIZES = @(512, 1024, 2048, 4096, 8192)
$THREAD_COUNTS = @(1, 2, 4, 8, 16)
$ITERATIONS = 5

$OUTPUT_DIR = "benchmark_results"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"
$RESULTS_FILE = "$OUTPUT_DIR\results_$TIMESTAMP.csv"

# Create output directory
New-Item -ItemType Directory -Force -Path $OUTPUT_DIR | Out-Null

Write-Host "=== Compiling code ===" -ForegroundColor Cyan
Write-Host "Compiling sequential version..."
g++ -O3 -o seq_benchmark.exe codebase.cpp
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error compiling sequential version" -ForegroundColor Red
    exit 1
}

Write-Host "Compiling parallel version..."
g++ -O3 -fopenmp -o par_benchmark.exe codebase_parallel.cpp
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error compiling parallel version" -ForegroundColor Red
    exit 1
}

Write-Host "Compilation successful!" -ForegroundColor Green
Write-Host ""

# Initialize CSV file
"Version,Threads,Width,Height,Pixels,Iteration,DataGen_ms,Grayscale_ms,Average_ms,Brightness_ms,Threshold_ms,Total_ms" | Out-File -FilePath $RESULTS_FILE -Encoding ASCII

# Function to extract timing from output
function Extract-Timing {
    param($output)
    
    $data_gen = ($output | Select-String "Data generation:\s+(\d+)").Matches.Groups[1].Value
    $grayscale = ($output | Select-String "Grayscale conversion:\s+(\d+)").Matches.Groups[1].Value
    $average = ($output | Select-String "Average calculation:\s+(\d+)").Matches.Groups[1].Value
    $brightness = ($output | Select-String "Brightness adjustment:\s+(\d+)").Matches.Groups[1].Value
    $threshold = ($output | Select-String "Threshold application:\s+(\d+)").Matches.Groups[1].Value
    $total = [int]$data_gen + [int]$grayscale + [int]$average + [int]$brightness + [int]$threshold
    
    return "$data_gen,$grayscale,$average,$brightness,$threshold,$total"
}

# Run sequential benchmarks
Write-Host "=== Running Sequential Benchmarks ===" -ForegroundColor Cyan
foreach ($size in $IMAGE_SIZES) {
    Write-Host "Testing image size: ${size}x${size}" -ForegroundColor Yellow
    for ($iter = 1; $iter -le $ITERATIONS; $iter++) {
        Write-Host "  Iteration $iter/$ITERATIONS..." -ForegroundColor Gray
        $output = .\seq_benchmark.exe $size $size 2>&1 | Out-String
        $timings = Extract-Timing $output
        $pixels = $size * $size
        "Sequential,1,$size,$size,$pixels,$iter,$timings" | Out-File -FilePath $RESULTS_FILE -Append -Encoding ASCII
    }
}

Write-Host ""
Write-Host "=== Running Parallel Benchmarks ===" -ForegroundColor Cyan
foreach ($threads in $THREAD_COUNTS) {
    $env:OMP_NUM_THREADS = $threads
    Write-Host "Testing with $threads threads" -ForegroundColor Yellow
    
    foreach ($size in $IMAGE_SIZES) {
        Write-Host "  Image size: ${size}x${size}" -ForegroundColor Gray
        for ($iter = 1; $iter -le $ITERATIONS; $iter++) {
            Write-Host "    Iteration $iter/$ITERATIONS..." -ForegroundColor DarkGray
            $output = .\par_benchmark.exe $size $size 2>&1 | Out-String
            $timings = Extract-Timing $output
            $pixels = $size * $size
            "Parallel,$threads,$size,$size,$pixels,$iter,$timings" | Out-File -FilePath $RESULTS_FILE -Append -Encoding ASCII
        }
    }
}

Write-Host ""
Write-Host "=== Benchmark Complete ===" -ForegroundColor Green
Write-Host "Results saved to: $RESULTS_FILE" -ForegroundColor Green
Write-Host ""
Write-Host "To analyze results, run:" -ForegroundColor Cyan
Write-Host "python analyze_results.py $RESULTS_FILE" -ForegroundColor White

# Display quick summary
Write-Host "`n=== Quick Summary ===" -ForegroundColor Cyan
$csv = Import-Csv $RESULTS_FILE
$summary = $csv | Group-Object Version,Threads,Width | ForEach-Object {
    $group = $_.Group
    [PSCustomObject]@{
        Version = $group[0].Version
        Threads = $group[0].Threads
        Size = "$($group[0].Width)x$($group[0].Height)"
        AvgTotal_ms = ($group | Measure-Object -Property Total_ms -Average).Average
    }
}

Write-Host "`nAverage execution times:" -ForegroundColor Yellow
$summary | Format-Table -AutoSize