org-grimoire is a static site generator for Emacs and Org mode.
Configured and run entirely through your Emacs init file.

Usage:
  (org-grimoire-setup "my-site"
    :base-dir    "~/my-site"
    :base-url    "https://example.com"
    :site-title  "My Site"
    :description "A personal site"
    :theme       "mytheme")

  (org-grimoire-build "my-site")

:site-title is the global name of your site, used in the <title> element,
feeds, and navigation.  The per-page :title placeholder in templates is
filled with each post's own #+TITLE keyword.

A post is represented as a plist:
  (:title        "My Post"
   :date         "2026-01-15"
   :tags         ("emacs" "lisp")
   :slug         "my-post"
   :source       "/path/to/file.org"
   :output       "/path/to/output/my-post.html"
   :assets       ("/path/to/images/screenshot.png"))
