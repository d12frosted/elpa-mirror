A helm interface for completing by lines in project.

Run `helm-lines' to complete the current line by other lines that
exist in the current git project.

Enable `helm-follow-mode' to replace in place as you jump around
the suggestions.

The project root is defined by the result of
`helm-lines-project-root-function', and by default it is the root
of the current version-control tree.  Projectile users might like
to set this variable to `projectile-root'.

Requires `ag' [1], `pt' [2] or similar to be installed. If you prefer
something other than `ag' you need to customize the
`helm-lines-search-function' accordingly, see below.

The lines completed against are defined by the result of the
`helm-lines-search-function', and by default it is `helm-lines-search-ag'.
Users that prefer `pt' over `ag' can set this variable to
`helm-lines-search-pt'. Other engines can be supported by supplying a
custom search function. It will be called with the shell quoted query and the
shell quoted folder to search in.

  [1]: https://github.com/ggreer/the_silver_searcher
  [2]: https://github.com/monochromegane/the_platinum_searcher
