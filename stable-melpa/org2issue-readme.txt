org2issue is a little tool that export org to github issue

Quick start:

1. specify ~org2issue-user~ as your github username
2. specify ~org2issue-blog-repo~ as the blog repository name
3. open the org file and execute =M-x org2issue=
4. if ~org2issue-browse-issue~ is non-nil, the new/updated issue will be browsed by =browse-url=

BUGS
+ It can't add issue labels.

To add issue labels. You have to redefine the method `gh-issues-issue-req-to-update` as below:
#+BEGIN_SRC emacs-lisp
(defmethod gh-issues-issue-req-to-update ((req gh-issues-issue))
  (let ((assignee (oref req assignee))
        (labels (oref req labels))
        (milestone (oref req milestone))
        (to-update `(("title" . ,(oref req title))
                     ("state" . ,(oref req state))
                     ("body" . ,(oref req body)))))

    (when labels (nconc to-update `(("labels" . ,(oref req labels) ))))
    (when milestone
      (nconc to-update `(("milestone" . ,(oref milestone number)))))
    (when assignee
      (nconc to-update `(("assignee" . ,(oref assignee login) ))))
    to-update))
#+END_SRC
