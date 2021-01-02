dayone.el is a simple emacs extension for placing the new post from
the emacs to Day One(http://dayoneapp.com).  It can post the
region when the concerned region is selected and M-x dayone-add-note.
When the region is not selected and M-x dayone-add-note is executed,
the all contents in the buffer are posted.
M-x dayone-add-note-with-tag shall be posted by attaching the tag.
When multiple tags are attached, use the space key for separating
each tag.
As for dayone-add-note() and dayone-add-note-with-tag,, it may be
convenient if you assign it to an appropriate key or add alias.
For the Day One, the data is managed by either the iCloud or the
Dropbox. This emacs extension is supported for storing data of
Dropbox only.
