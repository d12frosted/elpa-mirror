This package provides major modes for authoring Jekyll Markdown and
HTML documents, with syntax support for YAML front matter, Liquid
tags and embedded code snippets.

As this package depends on polymode, Emacs 24 is required.

The package includes two modes, `jekyll-markdown-mode` and
`jekyll-html-mode`, which can be enabled as normal by adding the
following to you init file:

    (add-to-list 'auto-mode-alist '("\\.md$" . jekyll-markdown-mode))
    (add-to-list 'auto-mode-alist '("\\.html" . jekyll-html-mode))
