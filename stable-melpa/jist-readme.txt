
Yet another [Gist][] client for Emacs.

### Features:

+ Allows to create gists.
+ Allows to delete/clone/star/unstar a gist.
+ List your owned/starred gists.
+ List public gists.
+ List public gists from another github user.

### Configuration:

To create anonymous gists is not necessary any configuration, but if you want
to create gists with your github account you need to obtain a `oauth-token`
with gist scope in https://github.com/settings/applications, and set it
through any of the following methods:

+ Add `(setq jist-github-token "TOKEN")` to your `init.el`.
+ Add `oauth-token` to your `~/.gitconfig`: `git config --global github.oauth-token MYTOKEN`

### Usage:

> **Warning**: By default, the functions `jist-region' and `jist-buffer'
> create **anonymous** gists.  To create gists with you configured account
> use `jist-auth-region' and `jist-auth-buffer'.

+ Create a gist from an active region:

                            | public | anonymous
  ------------------------- | ------ | ---------
  `jist-auth-region'        |        |
  `jist-auth-region-public' | x      |
  `jist-region'             |        | x
  `jist-region-public'      | x      | x

+ Create a gist of the contents of the current buffer:

                            | public | anonymous
  ------------------------- | ------ | ---------
  `jist-auth-buffer'        |        |
  `jist-auth-buffer-public' | x      |
  `jist-buffer'             |        | x
  `jist-buffer-public'      | x      | x

You can set the variable `jist-enable-default-authorized' to non nil to
always use your configured account when creating gists.

#### Tips:

+ In the current gist API the values of `gist_pull_url' and `git_push_url'
  use the HTTP protocol, but it's inconvenient to use the HTTP for pushes.
  To use the SSH protocol for pushes in cloned gists you need to add the
  following to your git-config(1):

        [url "git@gist.github.com:/"]
            pushInsteadOf = "https://gist.github.com/"

#### Related Projects:

+ [gist.el](https://github.com/defunkt/gist.el)
+ [yagist.el](https://github.com/mhayashi1120/yagist.el)

### TODO:

+ [ ] List Gist forks.
+ [ ] Allow gist edition with `org-mode'.
+ [ ] Handle nicely 422 errors.  See: https://developer.github.com/v3/#client-errors
+ [ ] Add pagination support with rfc5988 link headers.  See:
  - [Github api pagination](https://developer.github.com/v3/#pagination)
  - [Traversing with Pagination](https://developer.github.com/guides/traversing-with-pagination/).
  - [rfc5988](https://www.rfc-editor.org/rfc/rfc5988.txt)

[Gist]: https://gist.github.com/
