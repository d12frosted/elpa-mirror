pynt is an Emacs minor mode for generating and interacting with EIN notebooks.

Feature List
------------
- On-the-fly notebook creation
  - Run the command `pynt-mode' on a python buffer and a new notebook will be created for you to interact with (provided you have set the variable `pynt-start-jupyter-server-on-startup' to t)
- Dump a region of python code into a EIN notebook
  - Selectable regions include functions, methods, and code at the module level (i.e. outside of any function or class)
- Scroll the resulting EIN notebook with the code buffer
  - Alignment between code and cells are preserved even when cells are added and deleted
