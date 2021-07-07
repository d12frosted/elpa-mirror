A bibliography manager for Emacs, based on Helm and the
bibtex-completion backend.

News:
- 09/06/2018: Added virtual APA field `author-or-editor` for use in
  notes templates.
- 02/06/2018: Reload bibliography proactively when bib files are
  changed.
- 21/10/2017: Added support for multiple PDFs and other file
  types.  See `bibtex-completion-pdf-extension' and
  `bibtex-completion-find-additional-pdfs' for details.
- 10/10/2017: Added support for ~@string~ constants.
- 02/10/2017: Date field is used when year is undefined.
- 29/09/2017: BibTeX entry, citation macro, or org-bibtex entry at
  point, will be pre-selected in helm-bibtex and ivy-bibtex giving
  quick access to PDFs and other functions.

See NEWS.org for old news.

Key features:
- Quick access to your bibliography from within Emacs
- Powerful search capabilities
- Provides instant search results as you type
- Tightly integrated with LaTeX authoring, emails, Org mode, etc.
- Open the PDFs, URLs, or DOIs associated with an entry
- Insert LaTeX cite commands, Ebib links, or Pandoc citations,
  BibTeX entries, or plain text references at point, attach PDFs to
  emails
- Support for note taking
- Quick access to online bibliographic databases such as Pubmed,
  arXiv, Google Scholar, Library of Congress, etc.
- Imports BibTeX entries from CrossRef and other sources.

See the github page for details:

   https://github.com/tmalsburg/helm-bibtex
