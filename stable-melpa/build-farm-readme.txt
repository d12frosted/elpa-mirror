This package provides Emacs interface for Hydra and Cuirass (Nix and
Guix build farms):

  https://hydra.nixos.org            (Hydra)
  https://hydra.gnu.org              (Hydra)
  https://berlin.guixsd.org          (Cuirass)

Set `build-farm-url' variable to choose what build farm you wish to
use.

The entry point for the available features is "M-x build-farm".  It
provides a Magit-like interface for the commands to display builds,
jobsets, evaluations and projects.

Alternatively, you can use the following M-x commands directly:

- `build-farm-latest-builds'
- `build-farm-queued-builds'
- `build-farm-build'
- `build-farm-jobsets'
- `build-farm-projects'
- `build-farm-project'
- `build-farm-latest-evaluations'

You can press RET in a list (of builds, etc.) to see more info on the
current entry.  You can also select several entries in the list (with
"m" key) and press RET to "describe" them.
