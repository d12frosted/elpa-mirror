This tool will let you use git attributes
(https://git-scm.com/docs/gitattributes) in Emacs buffers.

In example the following will get the value of a `foo' git
attribute for the file associated with the current buffer:

  (git-attr-get "foo")

The `git-attr-get' function will return

  * t for git attributes with the value `set'
  * nil for git attributes with the value `unset'
  * 'undecided for git attributes that are `unspecified'
  * and the value if the git attribute is set to a value
