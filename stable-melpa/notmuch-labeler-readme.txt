
By default notmuch presents email labels as plain text. This
package improves notmuch by lettings users choose how to present
each label (e.g., with a special font, with a picture, ...).
Additionally, this package transforms each label into an hyperlink
to show all emails with this label.

To configure this package, add the following to your
.emacs.d/init.el file:

(require 'notmuch-labeler)

Then, you will get hyperlinks on all your labels. Now, if you want
to change the default presentation of a label, write something like
the following.

For example, the following renames the label "unread" to "new" and
changes the label color to blue:

(notmuch-labeler-rename "unread" "new" ':foreground "blue")

This replaces the label "important" by a tag picture:

(notmuch-labeler-image-tag "important")

This simply hides the label "unread" (there is no need to show this
label because unread messages are already in bold):

(notmuch-labeler-hide "unread")
