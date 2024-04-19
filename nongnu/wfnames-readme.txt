                               ━━━━━━━━━
                                WFNAMES
                               ━━━━━━━━━


Allows editing filenames.


1 Features
══════════

  Allows editing lists of absolute files, this allows editing the
  directory parts as well.

  Modified lines are highlighted, maybe in a different color when about
  to overwrite an existing file.

  File completion is provided.

  Not tighted to a directory, allows editing files from various
  directories.

  Do not provide edition of permissions and will not.


2 Motivation
════════════

  Wdired must be patched to allow editing a list of absolute filenames
  in Emacs versions before Emacs-29.  Also Wdired depends on a default
  directory which is not relevant and prone to errors when editing
  absolute filenames that come from various directories.  Using this
  package in Helm allows getting rid of Wdired advices (that have been
  merged in Emacs-29+).


3 Install
═════════

  This package have no user interface, but you can easily use it with
  [Helm] package by customizing `helm-ff-edit-marked-files-fn' variable.
  If you are not using [Helm] you will have to define yourself a
  function that call `wfnames-setup-buffer' with a list of files as
  argument.


[Helm] <https://github.com/emacs-helm/helm>


4 Usage
═══════

  Once in the Wfnames buffer, edit your filenames and hit `C-c C-c' to
  save your changes. You have completion on filenames and directories
  with `TAB' but if you are using [Iedit] package and it is in action
  use `M-TAB'.


[Iedit] <https://github.com/victorhge/iedit>
