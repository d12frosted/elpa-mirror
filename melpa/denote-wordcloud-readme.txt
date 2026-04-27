
denote-wordcloud.el generates a cloud of all known denote keywords.

Call denote-wordcloud to display the cloud.  Keywords are
sorted alphabetically by default.  To sort them by frequency, prefix the
command call with C-u.

When clicked, a keyword from the cloud performs a search for files that
contain it using denote-dired.  If a keyword is contained in only a single
file, that file will be opened in another window.  The search can also be
activated by placing the cursor on a keyword and pressing RET.
