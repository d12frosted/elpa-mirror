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
transient, which is bound to "i".  Note that this overrides the
default binding for `magit-gitignore', but this command is also
available under `magit-gitignore' ("I").

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

When Magit-imerge is installed from MELPA, no additional setup is
needed beyond installing git-imerge.  The binding for the imerge
popup will be added to `magit-mode-map', and Magit-imerge will be
loaded the first time that the imerge transient is invoked.

[*] https://github.com/mhagger/git-imerge
