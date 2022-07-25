
This package displays blame information,

1) Add sideline-blame to sideline backends list,

  (setq sideline-backends-right '(sideline-blame))

2) Then enable sideline-mode in the target buffer,

  M-x sideline-mode

This package uses vc-msg, make sure your project uses one of the following
version control system:

  * Git
  * Mercurial
  * Subversion
  * Perforce
