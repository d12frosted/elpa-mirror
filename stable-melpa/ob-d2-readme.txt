Org-Babel support for evaluating d2 diagram scripting source code.

d2 differs from most standard languages in that:

1) there is no such thing as a "session" in d2

2) we are only going to return results of type "file"

3) you can specify `:flags' headers to be passed to the `d2' command

4) there are no variables (at least for now)
