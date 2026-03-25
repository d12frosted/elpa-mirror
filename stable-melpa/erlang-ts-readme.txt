# Emacs Erlang mode using treesitter #

Requires emacs-29 compiled with treesitter support.

Uses tree-sitter for syntax-highlighting and indentation.
Other features are inherited from erlang-mode.

# Install #

Add to your .emacs file:

```
 (add-to-list 'treesit-language-source-alist
      '(erlang "https://github.com/WhatsApp/tree-sitter-erlang"))

 (use-package erlang-ts
     :mode ("\\.erl\\'" . erlang-ts-mode)
     :defer 't)
```
Install/compile erlang treesitter support (first time or upgrade grammer):

```
  M-x treesit-install-language-grammar
  Language: erlang
```
