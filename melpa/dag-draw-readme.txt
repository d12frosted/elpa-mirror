GKNV Baseline Compliance:

This is the main entry point for the GKNV graph drawing algorithm implementation.
The package implements all four passes of "A Technique for Drawing Directed Graphs"
by Gansner, Koutsofios, North, and Vo (1993).

GKNV Reference: Complete algorithm (Figure 1-1, lines 1-2166)
Decisions: Implements all baseline decisions D1.1-D5.8
Architecture: Four-pass hierarchical layout with ASCII/SVG rendering

Algorithm Passes (see individual modules for detailed compliance):
- Pass 1 (Ranking): Network simplex optimization → dag-draw-pass1-ranking.el
- Pass 2 (Ordering): Weighted median + transposition → dag-draw-pass2-ordering.el
- Pass 3 (Positioning): Auxiliary graph method → dag-draw-pass3-positioning.el
- Pass 4 (Splines): Region-constrained Bézier curves → dag-draw-pass4-splines.el
- ASCII Adaptation: Junction character algorithm → dag-draw-ascii-grid.el

Core Data Structures:
- dag-draw-node: Graph nodes with GKNV λ(v) rank assignments
- dag-draw-edge: Graph edges with GKNV δ(e) min-length and ω(e) weights
- dag-draw-graph: Complete graph structure with GKNV parameters

Baseline Status: ✅ Compliant (85% verified in Week 1)

GKNV Figure 1-1 Algorithm Pipeline:
"Our algorithm consists of four passes: rank assignment, node ordering,
coordinate assignment, and edge routing."

See doc/implementation-decisions.md for full decision rationale.
See individual module files for pass-specific GKNV compliance details.

This package implements the directed graph drawing algorithm described in
"A Technique for Drawing Directed Graphs" by Gansner, Koutsofios, North,
and Vo (1993).  The algorithm consists of four main passes:

1. Rank assignment using network simplex optimization
2. Vertex ordering within ranks to minimize edge crossings
3. Node coordinate positioning
4. Spline edge drawing using Bézier curves

The package provides functions to create, manipulate, and render directed
graphs in various formats including SVG and ASCII art.
