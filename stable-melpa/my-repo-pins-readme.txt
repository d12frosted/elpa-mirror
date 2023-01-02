Open source developers often have to jump between projects, either
to read code, or to craft patches. My Repo Pins reduces the
friction so that it becomes trivial to do so.

The idea of the plugin is based on this idea; if the repository
URLs can be translated to a filesystem location, the local disk can
be used like a cache. My Repo Pins lazily clones the repo to the
filesystem location if needed, and then jumps into the project in
one single command. You don't have to remember where you put the
project on the local filesystem because it's always using the same
location. Something like this:

~/code-root
├── codeberg.org
│   └── Freeyourgadget
│       └── Gadgetbridge
└── github.com
    ├── BaseAdresseNationale
    │   └── fantoir
    ├── mpv-player
    │   └── mpv
    └── NinjaTrappeur
        ├── cinny
        └── my-repo-pins

The main entry point of this package is the my-repo-pins command.
Using it, you can either:

- Open Dired in a local project you already cloned.
- Query remote forges for a repository, clone it, and finally open
  Dired in the clone directory.
- Clone a git clone URL and open Dired to the right directory.

The minimal configuration consists in setting the directory in
which you want to clone all your git repositories via the
my-repo-pins-code-root variable.

Let's say you'd like to store all your git repositories in the
~/code-root directory. You'll want to add the following snippet in
your Emacs configuration file:

   (require 'my-repo-pins)
   (setq my-repo-pins-code-root "~/code-root")

You can then call the M-x my-repo-pins command to open a
project living in your ~/code-root directory or clone a new
project in your code root.

Binding this command to a global key binding might make things a
bit more convenient. I personally like to bind it to M-h. You can
add the following snippet to your Emacs configuration to set up
this key binding:

   (global-set-key (kbd "M-h") 'my-repo-pins)

The my-repo-pins-open-function variable can be customized if you
would prefer to land in some other program than Dired.  Good
candidates might be the builtin 'vc-dir or 'magit-status if you use
the popular Magit package:

   (setq my-repo-pins-open-function 'vc-dir)
