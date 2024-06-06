Usage

0. config example:

(use-package org-bookmarks
  :ensure t
  :custom ((org-bookmarks-file "~/Org/Bookmarks/Bookmarks.org")
           (org-bookmarks-add-org-capture-template t))
  :commands (org-bookmarks)
  :init (org-bookmarks-add-org-capture-template))

1. Record bookmark information into Org mode file.

2. bookmark entry is recorded with format like bellowing:

   #+begin_src org
   * bookmark title                                         :bookmark:tag1:tag2:
   :PROPERTIES:
   :URL:      https://www.example.com
   :DESCRIPTION: example url
   :END:

   #+end_src

3. execute command `org-bookmarks' to search and select bookmark to open in web browser.
