                           ━━━━━━━━━━━━━━━━━
                            SYSTEM PACKAGES
                           ━━━━━━━━━━━━━━━━━


<https://gitlab.com/jabranham/system-packages/badges/master/pipeline.svg>

This is a collection of functions to make handling installed system
packages more convenient through Emacs.


1 Installation
══════════════

  System packages is available on [GNU ELPA]. You can get it by doing
  M-x package-install RET system-packages RET.

  Users of Debian ≥10 and derivatives can install it with the following:
  ┌────
  │ sudo apt install elpa-system-packages
  └────


[GNU ELPA] <https://elpa.gnu.org/packages/system-packages.html>


2 Configuration
═══════════════

  The package attempts to guess which package manager you use.  If it
  guesses wrong (or you'd like to set it manually), you may modify the
  variable `system-packages-package-manager'.

  We also attempt to guess whether or not to use sudo with appropriate
  commands (like installing and uninstalling packages). Some package
  managers (like homebrew) warn not to use sudo, others (like `apt')
  need sudo privileges. You may set this manually by configuring
  `system-packages-use-sudo'.

  Other package customization options can be accessed with M-x
  `customize-group RET system-packages RET'.


3 Supported package managers
════════════════════════════

  Currently, `system-packages' knows about the following package
  managers.  You can see exactly what commands are associated with
  `system-packages' commands by checking
  `system-packages-supported-package-managers'.  The default package
  manager that we use is the first one found from this list:

  • guix
  • nix
  • brew
  • macports
  • pacman
  • apt
  • aptitude
  • emerge
  • zypper
  • dnf
  • xbps


4 Usage
═══════

  The package doesn't presume to set keybindings for you, so you may set
  those up yourself or simply call functions with `M-x'. All commands
  start with `system-packages'


5 Adding other package managers
═══════════════════════════════

  It is straightforward to add support for package managers.  First, add
  the commands to `system-packages-supported-package-managers' like so:

  ┌────
  │ (add-to-list 'system-packages-supported-package-managers
  │ 	     '(pacaur .
  │ 		      ((default-sudo . nil)
  │ 		       (install . "pacaur -S")
  │ 		       (search . "pacaur -Ss")
  │ 		       (uninstall . "pacaur -Rs")
  │ 		       (update . "pacaur -Syu")
  │ 		       (clean-cache . "pacaur -Sc")
  │ 		       (log . "cat /var/log/pacman.log")
  │ 		       (change-log . "pacaur -Qc")
  │ 		       (get-info . "pacaur -Qi")
  │ 		       (get-info-remote . "pacaur -Si")
  │ 		       (list-files-provided-by . "pacaur -Ql")
  │ 		       (owning-file . "pacaur -Qo")
  │ 		       (owning-file-remote . "pacaur -F")
  │ 		       (verify-all-packages . "pacaur -Qkk")
  │ 		       (verify-all-dependencies . "pacaur -Dk")
  │ 		       (remove-orphaned . "pacaur -Rns $(pacman -Qtdq)")
  │ 		       (list-installed-packages . "pacaur -Qe")
  │ 		       (list-installed-packages-all . "pacaur -Q")
  │ 		       (list-dependencies-of . "pacaur -Qi")
  │ 		       (noconfirm . "--noconfirm"))))
  └────

  Any occurrences of `%p' in a command will be replaced with the package
  name during execution, otherwise the package name is simply appended
  to the command.

  You may also need to adjust `system-packages-package-manager' and
  `system-packages-use-sudo' accordingly:

  ┌────
  │ (setq system-packages-use-sudo t)
  │ (setq system-packages-package-manager 'pacaur)
  └────


6 See also
══════════

  Helm users might like [helm-system-packages]


[helm-system-packages]
<https://github.com/emacs-helm/helm-system-packages>
