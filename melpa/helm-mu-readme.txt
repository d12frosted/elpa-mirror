Helm sources for searching emails and contacts using mu and
mu4e. Mu is an indexer for maildirs and mu4e is a mutt-like MUA for
Emacs build on top of mu. Mu is highly efficient making it possible
to get instant results even for huge maildirs. It also provides
search operators similar to Google mail, e.g:

    from:Adam to:Eve flag:attach vacation photos

See the Github page for details and install instructions:

 https://github.com/emacs-helm/helm-mu

News:
- 2022-12-17: To override mu4e’s default search function, you now
  have to use: (define-key mu4e-search-minor-mode-map "s" 'helm-mu)

- 2016-05-31: Added two new actions in helm-mu-contacts: 1. Insert
  selected contacts at point. 2) Copy selected contacts to
  clipboard.  Contacts are inserted/copied in a format that is
  suitable for address fields, i.e. with quote names and email
  addresses.
