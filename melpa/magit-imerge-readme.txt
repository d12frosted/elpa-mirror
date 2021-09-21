Magit-imerge is a Magit interface to git-imerge [*], a Git
extension for performing incremental merges.

There are four high-level git-imerge subcommands that can be used
to start an incremental merge.  Each has a corresponding command in
Magit-imerge.

  * git-imerge merge  => magit-imerge-merge
  * git-imerge rebase => magit-imerge-rebase
  * git-imerge revert => magit-imerge-revert
  * git-imerge drop   => magit-imerge-drop

All these commands are available under the `magit-imerge'
transient.  If you use `magit-imerge' regularly, you may want to
bind it in `magit-mode-map'.  One option is to free up "i" for
`magit-imerge' by moving `magit-gitignore' to another binding:

   (define-key magit-mode-map (kbd "C-c C-i") 'magit-gitignore)
   (define-key magit-mode-map "i" 'magit-imerge)

Once an incremental merge has been started with one of the commands
above, the imerge popup will display the following sequence
commands:

  * magit-imerge-continue
  * magit-imerge-suspend
  * magit-imerge-finish
  * magit-imerge-abort

One of the advantages of incremental merges is that you can return
to them at a later time.  Calling `magit-imerge-suspend' will
suspend the current incremental merge.  You can resume it later
using `magit-imerge-resume'.

[*] https://github.com/mhagger/git-imerge
