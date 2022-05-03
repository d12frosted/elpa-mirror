A major mode for editing Answer Set Programs, formally Potassco
Answer Set Programs (https://potassco.org/).

Answer Set Programs are mainly used to solve complex combinatorial
problems by impressive search methods.
The modeling language follows a declarative approach with a minimal
amount of fixed syntax constructs.

; Install

Open the file with Emacs and run "M-x eval-buffer"
Open an ASP file and run "M-x clingo-mode"

To manually load this file within your Emacs config
add this file to your load path and place
(require 'clingo-mode)
in your init file.

See "M-x customize-mode clingo-mode" for information
about mode configuration.

; Features

- Syntax highlighting (predicates can be toggled)
- Commenting of blocks and standard
- Run ASP program from within Emacs and get the compilation output
- Auto-load mode when a *.lp file is opened

; Keybindings

"C-c C-e" - Call clingo with current buffer and an instance file
"C-c C-b" - Call clingo with current buffer
"C-c C-r" - Call clingo with current region
"C-c C-c" - Comment region
"C-c C-u" - Uncomment region

Remark

I'm not an elisp expert, this is a very basic major mode.
It is intended to get my hands dirty with elisp but also
to be a help full tool.
This mode should provide a basic environment for further
integration of Answer Set Programs into Emacs.

Ideas, issues and pull requests are highly welcome!
