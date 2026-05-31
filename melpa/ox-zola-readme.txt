
Org-mode export backend for Zola static site generator.

This package derives from ox-hugo to produce Zola-compatible
TOML frontmatter and shortcodes.  It supports subtree exports,
taxonomies with [taxonomies] section, and Zola shortcode syntax.

Usage:
  M-x ox-zola-export-to-md       ; Export to file
  M-x ox-zola-export-as-md       ; Export to buffer
  M-x ox-zola-export-wim-to-md   ; "What I Mean" export
