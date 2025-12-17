CC = g++
CFLAGS = -std=c++11 -O3
OMPFLAGS = -fopenmp
PYTHON = python3

SOURCES_SEQ = codebase.cpp
SOURCES_PAR = codebase_parallel.cpp
PARALLELIZER = auto_parallelizer.py

EXEC_SEQ = image_processor_sequential
EXEC_PAR = image_processor_parallel

.PHONY: all clean test benchmark help sequential parallel parallelize

all: sequential parallel

help:
	@echo "Auto-Parallelization Image Processing - Makefile"
	@echo "================================================="
	@echo ""
	@echo "Targets:"
	@echo "  make all          - Build both sequential and parallel versions"
	@echo "  make sequential   - Build sequential version only"
	@echo "  make parallel     - Build parallel version only"
	@echo "  make parallelize  - Generate parallel code from sequential"
	@echo "  make test         - Run both versions with default settings"
	@echo "  make benchmark    - Run performance comparison"
	@echo "  make clean        - Remove all generated files"
	@echo "  make help         - Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make && make test"
	@echo "  make benchmark"
	@echo "  OMP_NUM_THREADS=4 make test"

sequential: $(EXEC_SEQ)

$(EXEC_SEQ): $(SOURCES_SEQ)
	@echo "Compiling sequential version..."
	$(CC) $(CFLAGS) $(SOURCES_SEQ) -o $(EXEC_SEQ)
	@echo "✓ Sequential version built: $(EXEC_SEQ)"

parallelize: $(SOURCES_PAR)

$(SOURCES_PAR): $(SOURCES_SEQ) $(PARALLELIZER)
	@echo "Running auto-parallelizer..."
	$(PYTHON) $(PARALLELIZER) $(SOURCES_SEQ) $(SOURCES_PAR)

parallel: $(EXEC_PAR)

$(EXEC_PAR): $(SOURCES_PAR)
	@echo "Compiling parallel version..."
	$(CC) $(CFLAGS) $(OMPFLAGS) $(SOURCES_PAR) -o $(EXEC_PAR)
	@echo "✓ Parallel version built: $(EXEC_PAR)"

clean:
	@echo "Cleaning generated files..."
	rm -f $(EXEC_SEQ) $(EXEC_PAR)
	@echo "✓ Clean complete"

test: all
	@echo ""
	@echo "======================================"
	@echo "Testing Sequential Version"
	@echo "======================================"
	./$(EXEC_SEQ) 2048 2048
	@echo ""
	@echo "======================================"
	@echo "Testing Parallel Version"
	@echo "======================================"
	./$(EXEC_PAR) 2048 2048
	@echo ""

benchmark: all
	@echo ""
	@echo "======================================"
	@echo "Performance Benchmark"
	@echo "======================================"
	@echo ""
	@echo "Small (1024x1024):"
	@echo "-------------------"
	@echo -n "Sequential: "
	@./$(EXEC_SEQ) 1024 1024 | grep "Grayscale conversion"
	@echo -n "Parallel:   "
	@./$(EXEC_PAR) 1024 1024 | grep "Grayscale conversion"
	@echo ""
	@echo "Medium (2048x2048):"
	@echo "-------------------"
	@echo -n "Sequential: "
	@./$(EXEC_SEQ) 2048 2048 | grep "Grayscale conversion"
	@echo -n "Parallel:   "
	@./$(EXEC_PAR) 2048 2048 | grep "Grayscale conversion"
	@echo ""
	@echo "Large (4096x4096):"
	@echo "------------------"
	@echo -n "Sequential: "
	@./$(EXEC_SEQ) 4096 4096 | grep "Grayscale conversion"
	@echo -n "Parallel:   "
	@./$(EXEC_PAR) 4096 4096 | grep "Grayscale conversion"
	@echo ""
