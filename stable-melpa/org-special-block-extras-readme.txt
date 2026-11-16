Org markup all the way down: details, graph, math, callouts, and more.  Graphs from lists, folds from blocks,
colors from red:links.  We offer folds, graphs, maths, callouts, colors, tooltips, and badges; and
`org-defblock', a `cl-defun' for making our own.

Some text is tangential: a run of import statements, the gory steps of a proof, a worked solution to an
exercise.  We want it folded away until the reader asks for it; so we declare a block that does so, as we would
a Lisp function:

    (org-defblock details (&optional (title "Details") &context backend contents)
      "Fold CONTENTS away beneath TITLE, until the reader clicks it."
      (pcase backend
        ('html (format "<details><summary>%s</summary>%s</details>" title contents))
        (_     (format "\\begin{quote}\\textbf{%s}\n%s\\end{quote}" title contents))))

Now we write

    #+begin_details Why does this terminate?
    Each step *shrinks* the list, and no list is shorter than the empty one.
    #+end_details

and HTML folds it away, while LaTeX, sans clicks, sets it apart.  CONTENTS arrives already exported, which is
why the Org within ---*bold*, [[links]], red:text--- works as it does anywhere.  Moreover, a section tagged
`:details_Hint:' folds its text away under the title Hint.  Our own `details' is just this, plus colors.
Atop that one idea, we provide:

- Definers: `org-defblock', `org-deflink', and `org-deftag', each declared as a `cl-defun' is.
- Switches that every block understands ---ours, yours, or Org's own src and quote blocks---:
  `:folded', `:when', `:let', `:boxed', `:demo', and more; see `org-block-switches'.
- Blocks: `details', `box', callouts such as `note' and `warning', `parallel' columns, `margin' notes,
  `spoiler', `solution', `remark', `quote', `image', proof trees, and `math' with calculational proofs.
- Links: colors such as `red:', tooltips by `doc:', `kbd:', `badge:', and permalinks for Org's <<targets>>.
- Editing, as for src blocks: C-c C-c runs a block, C-c ' edits it, C-c C-v C-j inserts an argument,
  C-c C-v C-d splits it; and `:fontify' says how it looks in the buffer.
- Graphs: `#+begin_graph' draws a nested Org list as a Graphviz diagram.  Graphviz is a program of its own,
  so the graph block is opt-in, by (require 'org-graph-block); see graphs-README.org.

The manual, with every block demonstrated, is https://alhassy.com/org-special-block-extras
