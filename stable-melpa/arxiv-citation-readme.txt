Generate citation data for PDF files from the arXiv.
Additionally, download preprints to a specified directory and open
them.  Includes elfeed[1] support.

The high-level overview is:

 + `arxiv-citation-gui': Slurp an arXiv link from the primary
   selection or the clipboard and insert the corresponding citation
   into every file specified in `arxiv-citation-bibtex-files' (NOTE:
   this is `nil' by default!).  This uses `gui-get-selection' and is
   thus dependent on X11.

 + `arxiv-citation-download-and-open': Invoking this function with an
   arXiv url downloads it to `arxiv-citation-library' with name
   "author1-author2-...authorn_title-sep-by-dashes.pdf" and opens it
   with `arxiv-citation-open-pdf-function'.

 + `arxiv-citation-elfeed': Elfeed integration.  This works much like
   `arxiv-citation-download-and-open', but uses the currently viewed
   elfeed item instead of any X selections.

Refer to the README on the homepage for more information and visual
demonstrations.

An example configuration, using use-package[2], may look like

    (use-package arxiv-citation
      :commands (arxiv-citation-elfeed arxiv-citation-gui)
      :custom
      (arxiv-citation-library "~/library")
      (arxiv-citation-bibtex-files
       '("~/.tex/bibliography.bib"
         "~/projects/super-secret-project/main.bib")))

[1]: https://github.com/skeeto/elfeed
[2]: https://github.com/jwiegley/use-package
