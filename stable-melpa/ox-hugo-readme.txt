ox-hugo implements a Markdown back-end for Org exporter.  The
exported Markdown is compatible with the Hugo static site generator
(https://gohugo.io/).  This exporter also generates the post
front-matter in TOML or YAML.

To start using this exporter, add the below to your Emacs config:

  (with-eval-after-load 'ox
    (require 'ox-hugo))

With the above evaluated, the ox-hugo exporter options will be
available in the Org Export Dispatcher.  The ox-hugo export
commands have bindings beginning with "H" (for Hugo).

# Blogging Flows

1. one-post-per-subtree flow :: A single Org file can have multiple
     Org subtrees which export to individual Hugo posts.  Each of
     those subtrees that has the EXPORT_FILE_NAME property set is
     called a 'valid Hugo post subtree' in this package and its
     documentation.

2. one-post-per-file flow :: A single Org file exports to only
     *one* Hugo post.  An Org file intended to be exported by this
     flow must not have any 'valid Hugo post subtrees', and instead
     must have the #+title property set.

# Commonly used export commands

## For both one-post-per-subtree and one-post-per-file flows

   - C-c C-e H H  -> Export "What I Mean".
                     - If point is in a 'valid Hugo post subtree',
                       export that subtree to a Hugo post in
                       Markdown.
                     - If the file is intended to be exported as a
                       whole (i.e. has the #+title keyword),
                       export the whole Org file to a Hugo post in
                       Markdown.

   - C-c C-e H A  -> Export *all* "What I Mean"
                     - If the Org file has one or more 'valid Hugo
                       post subtrees', export them to Hugo posts in
                       Markdown.
                     - If the file is intended to be exported as a
                       whole (i.e. no 'valid Hugo post subtrees'
                       at all, and has the #+title keyword),
                       export the whole Org file to a Hugo post in
                       Markdown.

## For only the one-post-per-file flow

   - C-c C-e H h  -> Export the Org file to a Hugo post in Markdown.

Do M-x customize-group, and select `org-export-hugo' to see the
available customization options for this package.

See this package's website for more instructions and examples:

  https://ox-hugo.scripter.co
