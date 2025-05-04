┌─────────┐
│ Summary │
└─────────┘
The Jupyter Ascending package facilitates editing and executing
code in a Jupyter Python notebook from an ordinary Python buffer.
It does this by providing commands which utilize the Jupytext and
Jupyter Ascending command line tools for
- rendering .ipynb notebooks as standard Python source files,
- synchronizing the state of the 2 files, and
- executing code in the Jupyter notebook.
This allows users to work with Jupyter Python notebooks and make
use of all the features they would normally have when editing
Python code, such as code completion, linting, etc.

┌──────────┐
│ Features │
└──────────┘
- Synchronization: Editing and saving the Python buffer
  automatically updates the Jupyter notebook
- Cell execution commands: Run individual cells or the entire
  notebook
- Navigation tools: Jump between cells with simple commands
- Cell management: Create new cells and toggle between code and
  markdown types
- Enhanced markdown editing:
  - Edit markdown cells in dedicated markdown buffers (similar to
    Org mode's special edit mode)
  - Automatic comment insertion when pressing return in markdown
    cells
- Setup utilities: Commands for starting Jupyter notebooks and
  creating synchronized file pairs

┌─────────────┐
│ Limitations │
└─────────────┘
This package only works with Python notebooks because the Jupyter
Ascending command line tool only supports Python notebooks.  See
here: https://github.com/imbue-ai/jupyter_ascending/issues/25

┌──────────────┐
│ Installation │
└──────────────┘
The following dependencies must be installed, in addition to Jupyter:
pip install jupyter_ascending &&
python3 -m jupyter nbextension    install jupyter_ascending --sys-prefix --py && \
python3 -m jupyter nbextension     enable jupyter_ascending --sys-prefix --py && \
python3 -m jupyter serverextension enable jupyter_ascending --sys-prefix --py

Example use-package installation
(use-package jupyter-ascending
  :ensure t
  :hook (python-mode . (lambda ()
                         (when (and buffer-file-name
                                    (string-match-p "\\.sync\\.py\\'" buffer-file-name))
                           (jupyter-ascending-mode 1))))
  :bind (:map jupyter-ascending-mode-map
              ("C-c C-k" . jupyter-ascending-execute-line)
              ("C-c C-a" . jupyter-ascending-execute-all)
              ("C-c C-n" . jupyter-ascending-next-cell)
              ("C-c C-p" . jupyter-ascending-previous-cell)
              ("C-c t" . jupyter-ascending-cycle-cell-type)
              ("C-c '" . jupyter-ascending-edit-markdown-cell)))

┌───────┐
│ Usage │
└───────┘
Create a notebook pair with:
    M-x `jupyter-ascending-create-notebook-pair' RET example RET
Or, equivalently
    python3 -m jupyter_ascending.scripts.make_pair --base example
This creates synced files: example.sync.py and example.sync.ipynb

Start jupyter and open the notebook:
    With example.sync.py open,
    M-x `jupyter-ascending-start-notebook'
Or, equivalently,
    python3 -m jupyter notebook example.sync.ipynb

If you have an existing jupyter notebook, create a python file from it,
    M-x `jupyter-ascending-convert-notebook' RET example.ipynb RET
Or, equivalently,
    jupytext --to py:percent <file_name>
and then add the .sync suffix to both files
