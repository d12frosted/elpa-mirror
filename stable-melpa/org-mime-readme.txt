WYSIWYG, html mime composition using org-mode

For mail composed using the orgstruct-mode minor mode, this
provides a function for converting all or part of your mail buffer
to embedded html as exported by org-mode.  Call `org-mime-htmlize'
in a message buffer to convert either the active region or the
entire buffer to html.

Similarly the `org-mime-org-buffer-htmlize' function can be called
from within an org-mode buffer to convert the buffer to html, and
package the results into an email handling with appropriate MIME
encoding.

`org-mime-org-subtree-htmlize' is similar to `org-mime-org-buffer-htmlize'
but works on current subtree.  It can read following subtree properties:
MAIL_SUBJECT, MAIL_TO, MAIL_FROM, MAIL_CC, and MAIL_BCC.

Here is the sample of a subtree:
* mail one
  :PROPERTIES:
  :MAIL_SUBJECT: mail title
  :MAIL_TO: person1@gmail.com
  :MAIL_FROM: sender@gmail.com
  :MAIL_CC: person2@gmail.com
  :MAIL_BCC: person3@gmail.com
  :END:

To avoid exporting the table of contents, you can setup
`org-mime-export-options':
  (setq org-mime-export-options '(:section-numbers nil
                                  :with-author nil
                                  :with-toc nil))

Or just setup your export options in the org buffer/subtree.  These are
overridden by `org-mime-export-options' when it is non-nil.


Quick start:
Write a message in message-mode, make sure the mail body follows
org format.  Run `org-mime-edit-mail-in-org-mode' to edit mail
in a special edit with `org-mode'.
Run `org-mime-htmlize' to convert the plain text mail to html mail.
Run `org-mime-revert-to-plain-text-mail' if you want to restore to
plain text mail.

Setup (OPTIONAL):
You might want to bind this to a key with something like the
following message-mode binding

  (add-hook 'message-mode-hook
            (lambda ()
              (local-set-key (kbd "C-c M-o") 'org-mime-htmlize)))

and the following org-mode binding

  (add-hook 'org-mode-hook
            (lambda ()
              (local-set-key (kbd "C-c M-o") 'org-mime-org-buffer-htmlize)))

Extra Tips:
1. In order to embed images into your mail, use the syntax below,
[[/full/path/to/your.jpg]]

2. It's easy to add your own emphasis markup.  For example, to render text
between "@" in a red color, you can add a function to `org-mime-html-hook':

  (add-hook 'org-mime-html-hook
            (lambda ()
              (while (re-search-forward "@\\([^@]*\\)@" nil t)
                (replace-match "<span style=\"color:red\">\\1</span>"))))

3. Now the quoted mail uses a modern style (like Gmail), so mail replies
looks clean and modern. If you prefer the old style, please set
`org-mime-beautify-quoted-mail' to nil.

4. Please note this program can only embed exported HTML into mail.
   Org-mode is responsible for rendering HTML.

   For example, see https://github.com/org-mime/org-mime/issues/38
   The solution is patching org-mode,
   https://lists.gnu.org/archive/html/emacs-orgmode/2019-11/msg00016.html

5. See https://github.com/org-mime/org-mime for more tips
