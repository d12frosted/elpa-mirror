go-template-helper-mode is a small minor mode that overlays Go
text/template (Go template) syntax highlighting on top of another
major mode, such as `yaml-mode`, without changing indentation or
syntax rules of the host mode.

It is useful for files that embed Go template snippets ({{ ... }})
inside other formats, for example Helm chart templates under a
`templates/' directory.

The implementation is intentionally lightweight: it adds a small set
of font-lock keywords (regexes) and relies on JIT font-lock for
incremental refontification.
