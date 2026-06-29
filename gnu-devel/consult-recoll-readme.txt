                ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                 RECOLL QUERIES IN EMACS USING CONSULT
                ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━





1 About
═══════

  [Recoll] is a local search engine that knows how to index a wide
  variety of file formats, including PDFs, org and other text files and
  emails.  It also offers a sophisticated query language, and, for some
  document kinds, snippets in the the found documents actually matching
  the query at hand.

  This package provides an emacs interface to perform recoll queries,
  and display its results, via [consult].  It is also recommened that
  you use a a package for vertical display of completions that works
  well with /consult/, such as [vertico].

  <https://codeberg.org/jao/consult-recoll/raw/branch/main/consult-recoll.png>

  This package is part of [GNU ELPA], so for recent Emacs versions you
  can install it directly via `M-x package-install RET consult-recoll
  RET'.


[Recoll] <https://www.lesbonscomptes.com/recoll/>

[consult] <http://elpa.gnu.org/packages/consult.html>

[vertico] <http://elpa.gnu.org/packages/vertico.html>

[GNU ELPA] <http://elpa.gnu.org/packages/consult-recoll.html>

1.1 Tip: using consult-recoll with helm
───────────────────────────────────────

  If you use `helm-mode', you'll need to disable helm's completing read
  for `consult-recoll', with something like:

  ┌────
  │ (with-eval-after-load "helm"
  │   (with-eval-after-load "recoll"
  │     (add-to-list 'helm-completing-read-handlers-alist
  │ 		 (cons #'consult-recoll nil))))
  └────


2 Searching
═══════════

  The entry point of `consult-recoll' is the interactive command
  `consult-recoll'. Just invoke it (e.g., via `M-x consult-recoll') to
  perform any query and get its results dynamically displayed in the
  minibuffer, with "live" updates as the query changes.  Selecting any
  of the candidate results will open the associated file, using the
  functions in `consult-recoll-open-fns' (see [Opening search results]
  below).

  By default, your input will be interpreted as a recoll query, in the
  recoll query language (so you can issue queries like
  "author:jao@foo.io" or "dir:/home/jao/docs mime:application/pdf where
  is wally", and so on).  You can fine tune how queries are issued by
  customizing `consult-recoll-search-flags'.


[Opening search results] See section 4

2.1 Tip: Two-level filtering
────────────────────────────

  `consult-recoll' builds on the asychronous logic inside `consult.el',
  so you can use consult's handy [two-level filtering], which allows
  searching over the results of a query. For example, if you start
  typing

  ┌────
  │ #goedel's theorem
  └────

  see a bunch of results, and want to narrow them to those lines
  matching, say, "hofstadter", you can type `#' (which stops further
  recoll queries) followed by the term you're interested in:

  ┌────
  │ #goedel's theorem#hofstadter
  └────

  at which point only matches containing "hofstadter" will be offered.


[two-level filtering]
<https://github.com/minad/consult#asynchronous-search>


3 Displaying results
════════════════════

  For each matching result, `consult-recoll' retrieves its title, full
  file name and mime type, and shows, by default, a line with the first
  two in the minibuffer, using the customizable faces
  `consult-recoll-title-face' and `consult-recoll-url-face'.  You can
  provide your own formatting function (perhaps stripping common
  prefixes of the file name, or displaying also the MIME) as the value
  of the customizable variable `consult-recoll-format-candidate'.

  By default, `consult-recoll' uses consult's [live previews] to show,
  for each selected candidate hit, a buffer with further information,
  including snippets of the file (when provided by recoll).  The title,
  path and mime type of the document are also shown in previews.

  See [Opening search results] below for ways of customizing how Emacs
  will open selected results.


[live previews] <https://github.com/minad/consult#live-previews>

[Opening search results] See section 4

3.1 Example: formatting results list
────────────────────────────────────

  As mentioned, one can use `consult-recoll-format-candidate' to
  customize how search results are shown in the minibufer.  For
  instance, i like to shorten paths removing common prefixes and to show
  MIME types, so i use a formatter similar to this one:
  ┌────
  │ (defun jao-recoll-format (title url mime-type)
  │   ;; remove from url the common prefixes /home/jao/{org/doc,doc,...}
  │   (let* ((u (replace-regexp-in-string "/home/jao/" "" url))
  │ 	 (u (replace-regexp-in-string
  │ 	     "\\(doc\\|org/doc\\|.emacs.d/gnus/Mail\\|var/mail\\)/" "" u)))
  │     (format "%s (%s, %s)"
  │ 	    (propertize title 'face 'consult-recoll-title-face)
  │ 	    (propertize u 'face 'consult-recoll-url-face)
  │ 	    (propertize mime-type 'face 'consult-recoll-mime-face))))
  │ 
  │ 
  │ (setq consult-recoll-format-candidate #'jao-recoll-format)
  └────


3.2 Integration with embark-collect
───────────────────────────────────

  If you use [embark], you can use `embark-collect' to export the list
  of search results in the minibuffer to an /Embark collect/ buffer.  To
  allow opening buffer in that buffer as if they had been selected in
  the minibuffer, enable integration with embark adding this call to
  your init file:

  ┌────
  │ (consult-recoll-embark-setup)
  └────


[embark] <http://elpa.gnu.org/packages/embark.html>


3.3 Tip: displaying snippets in results list
────────────────────────────────────────────

  Instead of relying on a separate preview buffer to display snippets,
  you can set `consult-recoll-inline-snippets' to `t' to show them in
  the minibuffer, as individual candidates.

  <https://codeberg.org/jao/consult-recoll/raw/branch/main/consult-recoll-inline.png>


3.4 Tip: disabling mime type groups
───────────────────────────────────

  By default, results are listed grouped by their mime type.  You can
  disable grouping by setting the customizable variable
  `consult-recoll-group-by-mime' to `nil'.

  <https://codeberg.org/jao/consult-recoll/raw/branch/main/consult-recoll-no-groups.png>


4 Opening search results
════════════════════════

  When a search result candidate is selected, its MIME type is used to
  look up a function to open its associated file in the customizable
  variable `consult-recoll-open-fns'.  If no entry is found,
  consult-recoll uses the value of `consult-open-fn' as a default.  If
  the latter is not set, `eww-open-file' is used for HTML files and
  `find-file' for the rest, moving to the result's page number if the
  major mode of the opened file is either `doc-view-mode' or
  `pdf-view-mode'.

  If `consult-recoll-inline-snippets' is set, the functions above take
  two arguments: the URL of the file to open and, if present, the
  snippet page number (or `nil' if it is not available, e.g., because
  the selected candidate is the one showing the document data).

  If the selected candidate is a snippet corresponding to a text MIME
  and the page number of the snippet is 0 (as is often the case, since
  text files are normally not paginated), `consult-recoll' will perform
  a search for the snippet text after opening the file.

  See also [Integration with embark-collect] for an alternative way of
  listing and opening search results using embark.


[Integration with embark-collect] See section 3.2

4.1 Example: opening PDFs with external viewer
──────────────────────────────────────────────

  For instance, if you want to use `zathura' to open PDF documents, you
  could define an elisp helper like:

  ┌────
  │ (defun open-with-zathura (file &optional page)
  │   (shell-command (format "zathura %s -P %s" file (or page 1))))
  └────

  and then add it to `consult-recoll-open-fns':

  ┌────
  │ (add-to-list 'consult-recoll-open-fns '("application/pdf" . open-with-zathura))
  └────


4.2 Example: Opening emails with notmuch
────────────────────────────────────────

  If you use [notmuch] and include your maildirs in recoll's indexed
  directories, a simple way to open a candidate result given its file
  name is to find out the message's ID and use `notmuch.el''s function
  `notmuch-show' to open it:

  ┌────
  │ (defun open-with-notmuch (file &optional _page)
  │   (with-temp-buffer
  │     (insert-file-contents-literally file)
  │     (goto-char (point-min))
  │     (and (re-search-forward "^Message-ID: <\\([^>]+\\)>$" nil t)
  │ 	 (notmuch-show (concat "id:" (match-string 1))))))
  │ 
  │ (add-to-list 'consult-recoll-open-fns '("message/rfc822" . open-with-notmuch))
  └────


[notmuch] <https://notmuchmail.org/>


5 Thanks
════════

  Thanks to

  • [Nicholas P. Rougier] for useful discussions and suggestions,
    including actual fixes.
  • [Stefan Monnier] for setting up the GNU ELPA package.
  • Johan Widén for tips on using consult-recoll with helm.


[Nicholas P. Rougier] <https://codeberg.org/rougier>

[Stefan Monnier] <https://codeberg.org/monnier>
