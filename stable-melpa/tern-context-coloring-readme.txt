Use Tern as a backend for context coloring.

Add the following code to enable Tern support for context coloring:

(eval-after-load 'context-coloring
  '(tern-context-coloring-setup))
