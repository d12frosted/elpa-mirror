Org-Babel support for evaluating asymptote source code.

This differs from most standard languages in that

1) there is no such thing as a "session" in asymptote

2) we are generally only going to return results of type "file"

3) we are adding the "file" and "cmdline" header arguments, if file
   is omitted then the -V option is passed to the asy command for
   interactive viewing