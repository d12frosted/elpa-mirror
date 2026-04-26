org-lark exports Lark/Feishu cloud documents to Org files.

Pipeline:
  1.  Fetch Markdown via `lark-cli docs +fetch'.
  2.  Pre-process: protect code blocks, replace Lark custom tags
      with placeholders or standard Markdown.
  3.  Run Pandoc exactly once on the whole document.
  4.  Restore placeholders, clean up, prepend metadata.

Subprocess calls use `make-process' with a deadline so Emacs never
freezes even when lark-cli or Pandoc stalls.
