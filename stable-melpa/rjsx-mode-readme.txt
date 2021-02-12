Defines a major mode `rjsx-mode' based on `js2-mode' for editing
JSX files.  `rjsx-mode' extends the parser in `js2-mode' to support
the full JSX syntax.  This means you get all of the `js2' features
plus proper syntax checking and highlighting of JSX code blocks.

Some features that this mode adds to js2:

- Highlighting JSX tag names and attributes (using the rjsx-tag and
  rjsx-attr faces)
- Highlight undeclared JSX components
- Parsing the spread operator {...otherProps}
- Parsing && and || in child expressions {cond && <BigComponent/>}
- Parsing ternary expressions {toggle ? <ToggleOn /> : <ToggleOff />}

Additionally, since rjsx-mode extends the js2 AST, utilities using
the parse tree gain access to the JSX structure.
