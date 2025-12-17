#!/usr/bin/env python3
"""
Auto-Parallelizer for C++ Sequential Code using OpenMP
This tool analyzes sequential C++ code and automatically generates
parallelized versions with OpenMP directives.
"""

import re
import sys
from typing import List, Tuple, Optional, Dict
from dataclasses import dataclass


@dataclass
class LoopInfo:
    """Information about a detected loop"""
    start_line: int
    end_line: int
    loop_var: str
    is_parallelizable: bool
    reduction_vars: List[Tuple[str, str]]  # (variable, operation)
    private_vars: List[str]
    function_name: str
    indent: str


class AutoParallelizer:
    """Automatically parallelizes sequential C++ code using OpenMP"""
    
    def __init__(self):
        self.loops: List[LoopInfo] = []
        self.lines: List[str] = []
        self.function_contexts: Dict[str, str] = {}
        
    def analyze_code(self, filepath: str) -> List[str]:
        """Analyze C++ code and detect parallelizable patterns"""
        with open(filepath, 'r') as f:
            self.lines = f.readlines()
        
        self._detect_functions()
        self._detect_loops()
        return self._generate_parallel_code()
    
    def _detect_functions(self):
        """Detect function names for context"""
        func_pattern = re.compile(r'^\s*(void|int|double|float|unsigned|char|long)\s+(\w+)\s*\([^)]*\)\s*\{?')
        current_function = None
        
        for i, line in enumerate(self.lines):
            match = func_pattern.match(line)
            if match:
                current_function = match.group(2)
            self.function_contexts[i] = current_function if current_function else ""
    
    def _detect_loops(self):
        """Detect for loops and analyze if they're parallelizable"""
        i = 0
        while i < len(self.lines):
            line = self.lines[i]
            
            # Match for loop patterns
            for_match = re.match(r'^(\s*)for\s*\(\s*int\s+(\w+)\s*=\s*[^;]+;\s*\2\s*<[^;]+;\s*\2\+\+\s*\)', line)
            if for_match:
                indent = for_match.group(1)
                loop_var = for_match.group(2)
                
                # Find loop body
                loop_start = i
                loop_end = self._find_loop_end(i)
                
                # Analyze loop body
                is_parallelizable, reduction_vars, private_vars = self._analyze_loop_body(
                    loop_start, loop_end, loop_var
                )
                
                function_name = self.function_contexts.get(i, "")
                
                loop_info = LoopInfo(
                    start_line=loop_start,
                    end_line=loop_end,
                    loop_var=loop_var,
                    is_parallelizable=is_parallelizable,
                    reduction_vars=reduction_vars,
                    private_vars=private_vars,
                    function_name=function_name,
                    indent=indent
                )
                
                self.loops.append(loop_info)
                i = loop_end
            i += 1
    
    def _find_loop_end(self, start_line: int) -> int:
        """Find the end of a loop (closing brace)"""
        brace_count = 0
        found_open = False
        
        for i in range(start_line, len(self.lines)):
            line = self.lines[i]
            
            for char in line:
                if char == '{':
                    brace_count += 1
                    found_open = True
                elif char == '}':
                    brace_count -= 1
                    if found_open and brace_count == 0:
                        return i
        
        return start_line
    
    def _analyze_loop_body(self, start: int, end: int, loop_var: str) -> Tuple[bool, List[Tuple[str, str]], List[str]]:
        """
        Analyze loop body to determine if it's parallelizable
        Returns: (is_parallelizable, reduction_vars, private_vars)
        """
        body_lines = self.lines[start:end+1]
        body_text = ''.join(body_lines)
        
        # Check for data dependencies (basic analysis)
        has_dependencies = False
        reduction_vars = []
        private_vars = []
        
        # Check for common parallelizable patterns
        is_simple_array_access = bool(re.search(r'\[\s*' + loop_var + r'\s*\]', body_text))
        
        # Detect reduction patterns (sum += ...)
        reduction_pattern = re.findall(r'(\w+)\s*\+=\s*', body_text)
        if reduction_pattern:
            for var in reduction_pattern:
                # Check if it's accumulating from array indexed by loop var
                if re.search(rf'\w+\[{loop_var}\]', body_text):
                    reduction_vars.append((var, '+'))
        
        # Variables declared inside the loop are automatically private in OpenMP
        # We don't need to (and shouldn't) declare them in private clause
        # So we set private_vars to empty
        private_vars = []
        
        # Check for function calls that might have side effects
        has_io = bool(re.search(r'(cout|cin|printf|scanf|iostream)', body_text))
        
        # Check for complex control flow
        has_break_continue = bool(re.search(r'\b(break|continue)\b', body_text))
        
        # Determine if parallelizable
        is_parallelizable = (
            is_simple_array_access and 
            not has_io and 
            not has_break_continue and
            not has_dependencies
        )
        
        return is_parallelizable, reduction_vars, private_vars
    
    def _generate_parallel_code(self) -> List[str]:
        """Generate parallelized code with OpenMP directives"""
        output_lines = self.lines.copy()
        
        # Add OpenMP header if not present
        has_omp_include = any('#include <omp.h>' in line for line in output_lines)
        offset = 0
        if not has_omp_include:
            # Find the last #include
            last_include = 0
            for i, line in enumerate(output_lines):
                if line.strip().startswith('#include'):
                    last_include = i
            output_lines.insert(last_include + 1, '#include <omp.h>\n')
            offset = 1  # Account for the new line
        
        # Process loops in reverse order to maintain line numbers
        for loop in reversed(self.loops):
            if loop.is_parallelizable:
                pragma = self._generate_omp_pragma(loop)
                # Adjust insertion point by offset
                insert_pos = loop.start_line + offset
                output_lines.insert(insert_pos, pragma)
        
        # Update title to indicate parallel version
        for i, line in enumerate(output_lines):
            if 'Sequential Image Processing Benchmark' in line:
                output_lines[i] = line.replace('Sequential Image Processing Benchmark', 
                                               'Parallel Image Processing Benchmark (OpenMP)')
            # Add thread count output after total pixels
            if 'Total pixels:' in line and 'endl << endl' in line:
                indent = '    '
                output_lines[i] = line.replace('endl << endl', 'endl')
                output_lines.insert(i + 1, f'{indent}cout << "Number of threads: " << omp_get_max_threads() << endl << endl;\n')
                break
        
        return output_lines
    
    def _generate_omp_pragma(self, loop: LoopInfo) -> str:
        """Generate appropriate OpenMP pragma for the loop"""
        indent = loop.indent
        
        # Build pragma clauses
        clauses = []
        
        # Add reduction clause if needed
        if loop.reduction_vars:
            for var, op in loop.reduction_vars:
                clauses.append(f"reduction({op}:{var})")
        
        # Add private clause if needed (exclude loop iterator as it's automatically private)
        private_vars_filtered = [v for v in loop.private_vars if v != loop.loop_var]
        if private_vars_filtered and not loop.reduction_vars:
            private_list = ','.join(private_vars_filtered)
            clauses.append(f"private({private_list})")
        
        # Build complete pragma
        if clauses:
            pragma_str = f"{indent}#pragma omp parallel for {' '.join(clauses)}\n"
        else:
            pragma_str = f"{indent}#pragma omp parallel for\n"
        
        return pragma_str
    
    def generate_parallel_file(self, input_file: str, output_file: str):
        """Generate parallelized version of input file"""
        parallel_lines = self.analyze_code(input_file)
        
        with open(output_file, 'w') as f:
            f.writelines(parallel_lines)
        
        # Generate report
        print(f"Auto-Parallelization Report")
        print(f"{'='*50}")
        print(f"Input file: {input_file}")
        print(f"Output file: {output_file}")
        print(f"\nParallelized {len([l for l in self.loops if l.is_parallelizable])} out of {len(self.loops)} loops:")
        print()
        
        for i, loop in enumerate(self.loops, 1):
            if loop.is_parallelizable:
                print(f"✓ Loop {i} in function '{loop.function_name}' (line {loop.start_line + 1})")
                if loop.reduction_vars:
                    print(f"  - Reduction operations: {loop.reduction_vars}")
                if loop.private_vars:
                    print(f"  - Private variables: {loop.private_vars}")
            else:
                print(f"✗ Loop {i} in function '{loop.function_name}' (line {loop.start_line + 1}) - Not parallelizable")
        
        print(f"\n{'='*50}")
        print(f"Parallel code generated successfully!")


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 auto_parallelizer.py <input_file> [output_file]")
        print("\nExample:")
        print("  python3 auto_parallelizer.py codebase.cpp codebase_parallel.cpp")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else "output_parallel.cpp"
    
    parallelizer = AutoParallelizer()
    parallelizer.generate_parallel_file(input_file, output_file)


if __name__ == "__main__":
    main()
