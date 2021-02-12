Functions implementation status

FUNCTION NAME                                   STATUS
BACKEND PROPERTIES
* revision-granularity                          OK
- update-on-retrieve-tag                        OK
STATE-QUERYING FUNCTIONS
* registered (file)                             OK
* state (file)                                  OK
- dir-status-files (dir files update-function)  OK
- dir-extra-headers (dir)                       OK
- dir-printer (fileinfo)                        OK
- status-fileinfo-extra (file)                  OK
* working-revision (file)                       OK
* checkout-model (files)                        OK
- mode-line-string (file)                       OK
STATE-CHANGING FUNCTIONS
* create-repo (backend)                         OK
* register (files &optional comment)            OK
- responsible-p (file)                          OK
- receive-file (file rev)                       NO no specific actions
- unregister (file)                             OK
* checkin (files comment &optional rev)         OK
* find-revision (file rev buffer)               OK
* checkout (file &optional rev)                 OK
* revert (file &optional contents-done)         OK
- merge-file (file rev1 rev2)                   NO not needed
- merge-branch ()                               OK
- merge-news (file)                             NO not needed
- pull (prompt)                                 OK
- steal-lock (file &optional revision)          NO not needed
- modify-change-comment (files rev comment)     NO hg can modify only last comment
- mark-resolved (files)                         OK
- find-admin-dir (file)                         NO is this .hg dir?
HISTORY FUNCTIONS
* print-log (files buffer &optional shortlog start-revision limit)  OK
* log-outgoing (backend remote-location)        OK
* log-incoming (backend remote-location)        OK
- log-search (buffer pattern)                   OK
- log-view-mode ()                              OK
- show-log-entry (revision)                     OK
- comment-history (file)                        NO
- update-changelog (files)                      NO
* diff (files &optional rev1 rev2 buffer async) OK
- revision-completion-table (files)             OK branches and tags instead of revisions
- annotate-command (file buf &optional rev)     OK
- annotate-time ()                              OK
- annotate-current-time ()                      NO
- annotate-extract-revision-at-line ()          OK
- region-history (FILE BUFFER LFROM LTO)        OK experimental option "line-range" added in mercurial 4.4
- region-history-mode ()                        NO
- mergebase (rev1 &optional rev2)               TODO
TAG SYSTEM
- create-tag (dir name branchp)                 OK
- retrieve-tag (dir name update)                OK
MISCELLANEOUS
- make-version-backups-p (file)                 NO
- root (file)                                   OK
- ignore (file &optional directory)             OK find-ignore-file
- ignore-completion-table                       OK find-ignore-file
- previous-revision (file rev)                  OK
- next-revision (file rev)                      OK
- log-edit-mode ()                              OK
- check-headers ()                              NO
- delete-file (file)                            OK
- rename-file (old new)                         OK
- find-file-hook ()                             OK
- extra-menu ()                                 OK shelve, addremove
- extra-dir-menu ()                             OK extra-status-menu same as extra-menu
- conflicted-files (dir)                        OK with no respect to DIR
- repository-url (file-or-dir)                  OK

VC backend to work with hg repositories through hg command server.
https://www.mercurial-scm.org/wiki/CommandServer

The main advantage compared to vc-hg is speed.
Because communicating with hg over pipe is much faster than starting hg for each command.

Also there are some other improvements and differences:

- graph log is used for branch or root log

- Conflict status for a file
Files with unresolved merge conflicts have appropriate status in `vc-dir'.
Also you can use `vc-find-conflicted-file' to find next file with unresolved merge conflict.
Files with resolved merge conflicts have extra file info in `vc-dir'.

- hg summary as `vc-dir' extra headers
hg summary command gives useful information about commit, update and phase states.

- Current branch is displayed on mode line.
It's not customizable yet.

- Amend and close branch commits
While editing commit message you can toggle --amend and --close-branch flags.

- Merge branch
vc-hgcmd will ask for branch name to merge.

- Default pull arguments
You can customize default hg pull command arguments.
By default it's --update.  You can change it for particular pull by invoking `vc-pull' with prefix argument.

- Branches and tags as revision completion table
Instead of list of all revisions of file vc-hgcmd provides list of named branches and tags.
It's very useful on `vc-retrieve-tag'.
You can specify -C to run hg update with -C flag and discard all uncommitted changes.

- Filenames in vc-annotate buffer is omitted
They are mostly useless in annotate buffer.
To find out right filename to annotate vc-hgcmd uses `status --rev <rev> -C file'.

- `previous-revision' and `next-revision' respect files
Keys `p' and `n' in annotation buffer works correctly.

- Create tag
vc-hgcmd creates tag on `vc-create-tag'
If `vc-create-tag' is invoked with prefix argument then named branch will be created.

- Predefined commit message
While committing merge changes commit message will be set to 'merged <branch>' if
different branch was merged or to 'merged <node>'.

Additionally predefined commit message passed to custom function
`vc-hgcmd-log-edit-message-function' so one can change it.
For example, to include current task in commit message:

    (defun my/hg-commit-message (original-message)
      (if org-clock-current-task
          (concat org-clock-current-task " " original-message)
        original-message))

    (custom-set-variables
     '(vc-hgcmd-log-edit-message-function 'my/hg-commit-message))

- Interactive command `vc-hgcmd-runcommand' that allow to run custom hg commands

- It is possible to answer to hg questions, e.g. pick action during merge

- Option to display shelves in `vc-dir'

- View changes made by revision; diff to parents
Additional bindings in `log-view-mode':
 - `c c' view change made by revision at point (-c option to hg diff command)
 - `c 1' view diff between revision at point and its first parent
 - `c 2' view diff between revision at point and its second parent
`C c', `C 1' and `C 2' shows corresponding diffs for whole changeset.

- View log for revset
Command `vc-hgcmd-print-log-revset' allows to print log for
revset, e.g. "branch(branch1) or branch(branch2)"
