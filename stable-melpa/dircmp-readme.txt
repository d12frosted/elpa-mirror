Add to your Emacs startup file:

    (require 'dircmp)

Then:

    M-x compare-directories RET dir1 RET dir2 RET

The author uses dircmp-mode with git-difftool's directory diff:

    git difftool -d

You can configure Emacs with dircmp-mode as your default Git difftool
by adding to your .gitconfig:

    [difftool "emacs"]
      cmd = /path/to/dircmp-mode/emacs-git-difftool.sh \"$LOCAL\" \"$REMOTE\"
      prompt = false
    [diff]
      tool = emacs

git-difftool first learned to do directory diffs in Git 1.7.11. With
earlier versions of Git, you can add git-diffall from
<https://github.com/thenigan/git-diffall> and use dircmp-mode as your
git-diffall tool:

    git diffall -x /path/to/dircmp-mode/emacs-git-difftool.sh
