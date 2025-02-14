# Emacs Erlang mode using treesitter #

Requires emacs-29 compiled with treesitter support.

Currently uses treesitter only for syntax-highlighting,
*font-lock-mode*, and uses the "old" erlang-mode for everything else.

# Install #

Add to your .emacs file:

```
 (add-to-list 'treesit-language-source-alist
      '(erlang "https://github.com/WhatsApp/tree-sitter-erlang"))

 (use-package erlang-ts
     :mode ("\\.erl\\'" . erlang-ts-mode)
     :defer 't)
```
Install/compile erlang treesitter support (first time only):

```
  M-x treesit-install-language-grammar
  Language: erlang
```
