helm-github-stars provides capabilities to fetch your starred
repositories from github and select one for browsing.

Install:

    M-x package-install helm-github-stars

Usage:

Copy helm-github-stars.el in your load-path and put this in your ~/.emacs.d/init.el:

    (require 'helm-github-stars)
    ;; Setup your github username:
    (setq helm-github-stars-username "USERNAME")

Type M-x helm-github-stars to show starred repositories.

At the first execution of helm-github-stars, list of repositories is
fetched from github and saved into a cache file.
Default cache location: $HOME/.emacs.d/hgs-cache.
To refresh cache and open helm interface run helm-github-stars-fetch.

You can customize cache file path:

    (setq helm-github-stars-cache-file "/cache/path")

For a clean look, repositories's description is aligned by default, you can
customize this behavior via helm-github-stars-name-length, it's default
value is 30.
You can disable this by setting helm-github-stars-name-length to nil:

    (setq helm-github-stars-name-length nil)

If you want to be able to show your private repositories, customize
helm-github-stars-token:

    (setq helm-github-stars-token "TOKEN")
