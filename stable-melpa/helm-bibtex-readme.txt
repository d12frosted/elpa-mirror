A BibTeX bibliography manager based on Helm and the
bibtex-completion backend

News:
- 04/18/2016: Improved support for Mendely/Jabref/Zotero way of
  referencing PDFs.
- 04/06/2016: Generic functions are factored out into a backend for
  use with other completion frameworks like ivy.
- 04/02/2016: Added support for biblio.el which is useful for
  importing BibTeX from CrossRef and other sources.  See new
  fallback options and the section "Importing BibTeX from CrossRef"
  on the GitHub page.
- 02/25/2016: Support for pre- and postnotes for pandoc-citeproc
  citations.
- 11/23/2015: Added support for keeping all notes in one
  org-file.  See customization variable `bibtex-completion-notes-path'.
- 11/10/2015: Added support for PDFs specified in a BibTeX
  field.  See customization variable `bibtex-completion-pdf-field'.
- 11/09/2015: Improved insertion of LaTeX cite commands.

See NEWS.org for old news.

Key features:
- Quick access to your bibliography from within Emacs
- Tightly integrated workflows
- Provides instant search results as you type
- Powerful search expressions
- Open the PDFs, URLs, or DOIs associated with an entry
- Insert LaTeX cite commands, Ebib links, or Pandoc citations,
  BibTeX entries, or plain text references at point, attach PDFs to
  emails
- Attach notes to publications
- Quick access to online bibliographic databases such as Pubmed,
  arXiv, Google Scholar, Library of Congress, etc.
- Import BibTeX entries from CrossRef and other sources.

See the github page for details:

   https://github.com/tmalsburg/helm-bibtex
