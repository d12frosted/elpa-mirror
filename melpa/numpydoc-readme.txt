This package provides a function to automatically generate NumPy
style docstrings for Python functions: `numpydoc-generate'. The
NumPy docstring style guide can be found at
https://numpydoc.readthedocs.io/en/latest/format.html

There are three ways that one can be guided to insert descriptions
for the components:

1. Minibuffer prompt (the default).
2. yasnippet expansion (requires `yasnippet' to be installed)
3. Nothing (placeholding template text is inserted).

Convenience functions are provided to interactively configure the
insertion style symbol:
- `numpydoc-use-prompt'
- `numpydoc-use-yasnippet'
- `numpydoc-use-templates'
