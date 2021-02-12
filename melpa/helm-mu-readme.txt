Helm sources for searching emails and contacts using mu and
mu4e. Mu is an indexer for maildirs and mu4e is a mutt-like MUA for
Emacs build on top of mu. Mu is highly efficient making it possible
to get instant results even for huge maildirs. It also provides
search operators similar to Google mail, e.g:

    from:Peter to:Anne flag:attach search term

See the Github page for details and install instructions:

 https://github.com/emacs-helm/helm-mu

News:

- 2016-05-31: Added two new actions in helm-mu-contacts: 1. Insert
  selected contacts at point. 2) Copy selected contacts to
  clipboard.  Contacts are inserted/copied in a format that is
  suitable for address fields, i.e. with quote names and email
  addresses.
