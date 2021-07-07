This libaray provides a drop-in replacement for find-file (ie. the
"C-x f" command), that auto-completes all files in the current git,
mercurial, or other type of repository. When outside of a
repository, find-file-in-repository conveniently drops back to
using find-file, (or ido-find-file), which makes it a suitable
replacement for the "C-x f" keybinding.

It is similar to, but faster and more robust than the find-file-in-project
package. It relies on git/mercurial/etc to provide fast cached file name
completions, which means that repository features such as
.gitignore/.hgignore/etc are fully supported out of the box.

This library currently has support for:
    git, mercurial, darcs, bazaar, monotone, svn

Contributions for support of other repository types are welcome.
Please send a pull request to
https://github.com/hoffstaetter/find-file-in-repository and I will
be happy to include your modifications.

Recommended keybinding:
   (global-set-key (kbd "C-x f") 'find-file-in-repository)
