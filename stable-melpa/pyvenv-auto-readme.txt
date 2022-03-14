pyvenv-auto automatically activates a Python venv with pyvenv package.
When you open a file in python-mode, it searches for the venv
directory near the file, and activates it.  When you open a Python
file, pyvenv-auto searches for a venv directory with a name in
`pyvenv-auto-venv-dirnames`.  The search behavior is similar to that of
`locate-dominating-file`.  The directory name with a smaller index
has higher priority than that with a greater index.
