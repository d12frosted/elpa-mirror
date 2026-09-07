Survey your code: LLM-generated diagrams of code, rendered inline in Emacs.

Surveyor asks your configured LLM (via gptel) for a diagram of the code you
are looking at, validates the result by actually rendering it, feeds renderer
errors back to the LLM for automatic repair, and shows the image in a view
buffer.

Diagrams are produced by a pluggable engine (`surveyor-engine'):

- `d2': single Go binary (`brew install d2'), fast native rendering.
- `mermaid': needs mermaid-cli (`mmdc'), which drives headless
  Chromium; best LLM fluency and pairs with org-babel/ob-mermaid.
- `dot': Graphviz, tiny and fast, but flowcharts only.

The default `auto' picks the first engine whose binary is installed,
in the order d2, mermaid, dot.

Entry points: `surveyor' (or the standalone commands).

The rendered diagram is shown in an `image-mode' buffer (fit to window,
smooth scrolling, zoom) with surveyor keys on top, listed in the header
line.
