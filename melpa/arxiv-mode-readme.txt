
arxiv-mode is an Emacs major mode for viewing
updates on arXiv.org.


Common Usage
============

arxiv-mode provides many functions for accessing arXiv.org.
To browse the daily new submissions list in a category, run `M-x arxiv-read-new`.
To browse the recent (weekly) submissions, run `M-x arxiv-read-recent`.
Use `M-x arxiv-read-author` to search for specific author(s).
Use `M-x arxiv-search` to perform a simple search on the arXiv database.

For more complicated searches, use `M-x arxiv-complex-search`.
This command allows user to dynamically refine and modify search conditions.
You can also use `r` to refine search condition in the abstract list obtained from a search.

In the article list, use `n` and `p` to navigate the article list.
Press `SPC` to toggle visibility of the abstract window.
Press `RET` to open the entry in a web browser. Press `d` to download the pdf.
Press `b` to export the bibtex entry of current paper to your specified .bib file.
Press `B` to export the bibtex entry to a new buffer.
Press `e` to download pdf and add a bibtex entry with a link to the actual pdf file.

All available commands are listed in a hydra help menu accessable by `?` whenever you are in the article list.


Installation
============

arxiv-mode is available on MELPA.
After `M-x package-install RET arxiv-mode RET`, put the following code in your `init.el`:

(require 'arxiv-mode)

Or if you use `use-package`, you can simply put:
(use-package arxiv-mode
  :ensure t)

into the your init file. `use-package` will automatically download `arxiv-mode` for you.


Customization
=============

Run `M-x arxiv-customize` to customize or set the customization variables directly.
