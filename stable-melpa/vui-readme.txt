vui.el (Virtual UI) is a declarative, component-based UI library for Emacs.
It brings React-like patterns to buffer-based interfaces: define components
as functions of state, compose them into trees, and let the library handle
efficient updates through reconciliation.

Built on top of `widget.el' for battle-tested input handling, vui.el adds
state management, automatic re-rendering, cursor preservation, and layout
primitives for building complex, interactive UIs in Emacs buffers.

Core Philosophy:
- Declarative: Describe the UI as a function of state
- Component-based: Build complex UIs from small, reusable pieces
- Unidirectional data flow: Data flows down through props; events flow up
- Predictable: Same props + state always produces the same output
- Emacs-native: Respect Emacs conventions (point, markers, keymaps, faces)
