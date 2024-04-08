`markdown-ts-mode` is a major mode that provides BASIC syntax
highlight and iMenu navigation.

To enable it, install the package and call it when needed with:
(markdown-ts-mode)

You can also setup it to be used automatically like:

(use-package markdown-ts-mode
  :mode ("\\.md\\'" . markdown-ts-mode)
  :defer 't
  :config
  (add-to-list 'treesit-language-source-alist '(markdown "https://github.com/ikatyang/tree-sitter-markdown" "master" "src")))
