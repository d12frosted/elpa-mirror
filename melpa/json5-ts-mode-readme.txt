This package provides a tree-sitter major mode for editing JSON5 files.

Installation:

Requirements:

To install a tree-sitter grammar, the following tools are required:

- Git
- C/C++ compiler

If your compiler is not `cc', `gcc', `c99', `c++' or `g++', check out the
documentation of `treesit-language-source-alist'.

Check the availability of `tree-sitter':

```elisp
(treesit-available-p) ; should return t
```

Install grammar:

```elisp
(require 'treesit)
(add-to-list 'treesit-language-source-alist
             '(json5 "https://github.com/Joakker/tree-sitter-json5"))
```

Then run `M-x treesit-install-language-grammar'

Install `json5-ts-mode':

```elisp
(add-to-list 'load-path "/path/to/json5-ts-mode")
(require 'json5-ts-mode)
(add-to-list 'auto-mode-alist
             '("\\.json5\\'" . json5-ts-mode))
```

Customizations:

`json5-ts-mode-indent-offset':

Number of spaces for each indentation step in `json5-ts-mode'.

Limitations:

Currently this mode doesn't support multi-line strings because the grammar
doesn't support it.

License:

GPLv3
