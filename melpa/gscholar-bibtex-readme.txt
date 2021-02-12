* gscholar bibtex

  Retrieve BibTeX entries from Google Scholar, ACM Digital Library, IEEE Xplore
  and DBLP by your query. All in Emacs Lisp!

  *UPDATE*: ACM Digital Library, IEEE Xplore, and DBLP are now supported though
   the package name doesn't suggest that.
** Basic usage
   Without package.el:
       (add-to-list 'load-path "/path/to/gscholar-bibtex.el")
       (require 'gscholar-bibtex)

   With package.el: install via melpa!

   To use, simply call
        M-x gscholar-bibtex

  Choose a source, then enter your query and select the results.

  Available commands in `gscholar-bibtex-mode', i.e., in the window of search
  results:
  - n/p: next/previous
  - TAB: show BibTeX entry for current search result
  - A/W: append/write to `gscholar-bibtex-database-file' (see later)
  - a/w: append/write to a file
  - c: copy the current BibTeX entry
  - x: close BibTeX entry window
  - q: quit

** Sources
  By default, I enable all sources(Google Scholar, ACM Digital Library, IEEE
  Xplore and DBLP). If you don't want to enable some of them, you could call
      M-x gscholar-bibtex-turn-off-sources

  Similarly, if you want to enable some of them, you could call
      M-x gscholar-bibtex-turn-on-sources

  To keep the configuration in your init file, you could use the following
  format(*NOT* real code):
      (gscholar-bibtex-source-on-off action source-name)

  Possible values:
  - action: :on or :off
  - source-name: "Google Scholar", "ACM Digital Library", "IEEE Xplore" or "DBLP"

  Say if you want to disable "IEEE Xplore", use the following code:
      (gscholar-bibtex-source-on-off :off "IEEE Xplore")

** Default source
  If you have a preferred source, you can set it as default so you don't have to
  type the name to select the source every time you call `gscholar-bibtex'. Say
  if you want to set "Google Scholar" as default:
      (setq gscholar-bibtex-default-source "Google Scholar")

  Note that in order to make it work, you have to make sure the source name is
  correct and you don't disable the source that you set as default, otherwise
  the default source setting has no effect. Besides, if you only have one source
  enabled, then the enabled source automatically becomes the default, regardless
  of the value of `gscholar-bibtex-default-source'.

** Configuring `gscholar-bibtex-database-file'
   If you have a master BibTeX file, say refs.bib, as database, and want to
   append/write the BibTeX entry to refs.bib without being asked for a
   filename to be written every time, you can set
   `gscholar-bibtex-database-file':
       (setq gscholar-bibtex-database-file "/path/to/refs.bib")

   Then use "A" or "W" to append or write to refs.bib, respectively.

** Adding more sources
   Currently these three sources cover nearly all my needs, and it is possible
   if you need to add more sources.

   Basically, you need to implement following five functions(if you're willing,
   I think looking the source code is better. The implementation is easy!):
#+BEGIN_SRC elisp
(defun gscholar-bibtex-SourceName-search-results (query)
"In the body, call `gscholar-bibtex--url-retrieve-as-string' to return a string
containing query results"
  body)

(defun gscholar-bibtex-SourceName-titles (buffer-content)
"Given the string `buffer-content', return the list of titles"
  body)

(defun gscholar-bibtex-SourceName-subtitles (buffer-content)
"Given the string `buffer-content', return the list of subtitles"
  body)

(defun gscholar-bibtex-SourceName-bibtex-urls (buffer-content)
"Given the string `buffer-content', return the list of urls(or maybe other
 feature) of the BibTeX entries, which would be fed to the next function"
  body)

(defun gscholar-bibtex-SourceName-bibtex-content (arg)
"Given the url(or other feature) of a BibTeX entry, return the entry as string.
Also call `gscholar-bibtex--url-retrieve-as-string' for convenience"
  body)
#+END_SRC

   Then you need to add a line:
       (gscholar-bibtex-install-source "Source Name" 'SourceName)

   You should put this line somewhere near the end of `gscholar-bibtex.el',
   where you could find several `gscholar-bibtex-install-source' lines.

   That's all. Enjoy hacking^_^
