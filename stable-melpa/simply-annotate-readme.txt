
A lightweight annotation system for Emacs that allows
you to add persistent notes to any text file without modifying the
original content.

Quick Start:

(use-package simply-annotate
 :bind ("C-c A" . simply-annotate-mode))

1. Open any file
2. Enable annotation mode: =C-c A=
3. Select text and press =M-s SPC= to create your first annotation
4. Create some more annotations
5. Navigate with =M-n= (next) and =M-p= (previous)

Usage:

* Editing
- Place cursor on annotated text
- Press =M-s SPC= to open the annotation buffer
- Make your changes
- Save with =C-c C-c=

* Deleting
- Place cursor on annotated text
- Press =M-s -= to remove the annotation

* Listing All Annotations
- Press =M-s l= to open a grep-mode buffer showing all annotations in the current file
- Click on line numbers or press =Enter= to jump directly to annotations
- Perfect for getting an overview of all your notes

* Cross-file Overview
- Press =M-s 0= to browse annotations across all files
- Select a file from the completion list
- View all annotations for that file in grep-mode format
