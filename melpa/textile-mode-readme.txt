An emacs major mode for Textile markup language
(https://textile-lang.com/) editing.

; Known bugs or limitations:

- if several {style}, [lang] or (class) attributes are given for
  the same block, only the first one of each type will be
  highlighted.

- some complex imbrications of inline markup and attributes are
  not well-rendered (for example, *strong *{something}notstrong*)
