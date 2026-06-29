Read Me

This library was created to fascilitate quickly building web pages,
though it also includes tools for working with parsed xml


1 Code Generation with esxml.el
═══════════════════════════════

  This library provides to formats for xml code generation.  The primary
  form is esxml.  esxml is the form that is returned by such functions
  as libxml-parse-xml-region and is used internally by emacs in many xml
  related libraries.


1.1 A brief example
───────────────────

  The following is a very simple esxml document, paths are handled
  directly, via a case statement.  While this is not good practice, this
  is meant to be a very simple example.


1.1.1 sxml example
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (let ((count 0))
  │   (defun sxml-demo (httpcon)
  │     (incf count)
  │     (case (intern (elnode-http-pathinfo httpcon))
  │       (/messages (with-current-buffer "*Messages*"
  │                    (sxml-to-xml `(html (body (pre ,(buffer-string)))))))
  │ 
  │       (t (sxml-to-xml
  │           `(html
  │             (body
  │              (h1 "Hello from Emacs!") (br)
  │              "Trying to visit " ,(format "%s" (elnode-http-pathinfo httpcon)) (br)
  │              "Visit " (a (@ (href "/messages")) "messages") " to see the *Messages* buffer." (br)
  │              "Have been visited " ,(format "%s" count) " times since last started.")))))))
  └────

  This outputs the following HTML:

  ┌────
  │ <html >
  │   <body >
  │     <h1 >Hello from Emacs!</h1><br />
  │     Trying to visit /anywhere<br />
  │     Visit <a href="/messages">messages</a> to see the *Messages* buffer.<br />
  │     Have been visited 1 times since last started.
  │   </body>
  │ </html>
  └────


1.1.2 esxml example
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (let ((count 0))
  │   (defun esxml-demo (httpcon)
  │     (incf count)
  │     (case (intern (elnode-http-pathinfo httpcon))
  │       (/messages (with-current-buffer "*Messages*"
  │                    (esxml-to-xml `(html () (body () (pre () ,(buffer-string)))))))
  │ 
  │       (t (esxml-to-xml
  │           `(html ()
  │                  (body ()
  │                        (h1 () "Hello from Emacs!")
  │                        (br) "Trying to visit " ,(format "%s" (elnode-http-pathinfo httpcon))
  │                        (br)  "Visit " (a ((href . "/messages")) "messages")  " to see the *Messages* buffer."
  │                        (br) "Have been visited " ,(format "%s" count) " times since last started.")))))))
  └────


1.2 Advanced examples
─────────────────────

1.2.1 A standard page generator
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌


2 Extracting data from HTML and XML documents with esxml-query.el
═════════════════════════════════════════════════════════════════

  ┌────
  │ (require 'dom)
  │ (require 'esxml-query)
  │ 
  │ (url-retrieve
  │  "https://schneierfacts.com/"
  │  (lambda (status &rest args)
  │    (let* ((html (libxml-parse-html-region url-http-end-of-headers (point-max)))
  │           (fact (esxml-query "p.fact" html)))
  │      (message "Did you know: %s" (car (dom-children fact))))))
  └────

  ┌────
  │ (require 'dom)
  │ (require 'esxml-query)
  │ 
  │ (url-retrieve
  │  "https://www.xkcd.com/rss.xml"
  │  (lambda (status &rest args)
  │    (goto-char url-http-end-of-headers)
  │    (forward-line 1)
  │    (let* ((xml (libxml-parse-xml-region (point) (point-max)))
  │           (latest (esxml-query "rss>channel>item" xml))
  │           (title (car (dom-children (esxml-query "title" latest))))
  │           (link (car (dom-children (esxml-query "link" latest)))))
  │      (message "%S: %s" title link))))
  └────

  See the following packages for more examples:

  • <https://gitlab.com/fvdbeek/emacs-pubmed>
  • <https://github.com/balddotcat/posthtml>
  • <https://gist.github.com/dustinlacewell/86f2fedc8ebcea22f96a3c5a81a0e0ba>
  • <https://github.com/alphapapa/org-web-tools>
  • <https://github.com/alphapapa/org-books>
  • <https://github.com/mihaiolteanu/versuri>
  • <https://depp.brause.cc/nov.el/>
