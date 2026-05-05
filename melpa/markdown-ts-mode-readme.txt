
This package provides tree-sitter support for Markdown for Emacs
29–30.

Emacs 31+ ships with a built-in `markdown-ts-mode`, written by the
same author and derived from this package, which supersedes it and
makes this package obsolete and incompatible.




`markdown-ts-mode` is a major mode that provides BASIC syntax
highlight and iMenu navigation.

To enable it, install the package and call it when needed with:
(markdown-ts-mode)

You can also setup it to be used automatically like:

(use-package markdown-ts-mode
   :mode ("\\.md\\'" . markdown-ts-mode)
   :defer 't
   :config
   (add-to-list 'treesit-language-source-alist '(markdown "https://github.com/tree-sitter-grammars/tree-sitter-markdown" "split_parser" "tree-sitter-markdown/src"))
   (add-to-list 'treesit-language-source-alist '(markdown-inline "https://github.com/tree-sitter-grammars/tree-sitter-markdown" "split_parser" "tree-sitter-markdown-inline/src")))

NOTE: please note you need BOTH markdown and markdown-inline grammars installed!
      so please, run `treesit-install-language-grammar' twice.
