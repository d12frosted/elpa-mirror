dag-draw.el: Draw directed graphs that don't suck.

You focus on the structure (what connects to what), and dag-draw handles
the layout (where everything goes).  No more fiddling with positions or
untangling crossed arrows.

Quick Start:

  (require 'dag-draw)

  ;; Create a graph
  (setq my-graph (dag-draw-create-graph))

  ;; Add nodes
  (dag-draw-add-node my-graph 'start "Start Here")
  (dag-draw-add-node my-graph 'middle "Do Work")
  (dag-draw-add-node my-graph 'done "Finish")

  ;; Connect them
  (dag-draw-add-edge my-graph 'start 'middle)
  (dag-draw-add-edge my-graph 'middle 'done)

  ;; Layout and render
  (dag-draw-layout-graph my-graph)
  (dag-draw-render-graph my-graph 'ascii)  ; or 'svg

Or create from a data structure in one call:

  (dag-draw-create-from-spec
    :nodes '((a :label "Task A") (b :label "Task B"))
    :edges '((a b)))

Output formats: ASCII (box-drawing characters) and SVG (scalable graphics).
Both support node highlighting for "you are here" visual emphasis.

See the README for full documentation, tutorials, and examples.

Under the hood, this implements the GKNV algorithm from "A Technique for
Drawing Directed Graphs" (Gansner et al., 1993) - the same algorithm that
powers Graphviz.  See individual module files for technical details.
