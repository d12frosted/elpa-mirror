			     ━━━━━━━━━━━━━
			      BUILDBOT.EL
			     ━━━━━━━━━━━━━


[Buildbot] is a free software continuous integration tool. buildbot.el
is an emacs interface to view build information on a Buildbot
instance. It supports [newer versions]* of Buildbot (>=0.9.0) but not
older versions (<0.9.0) and shows views for branches, revisions, builds,
steps, logs and builders.

It has been tested for the following instances (the urls are to be used
as `buildbot-host'):
• [mariadb] (works better with `(setq buildbot-api-changes-direct-filter
  t)')
• [python]
• [buildbot]
• [scummvm]
• [sagemath]
• [openwrt]
• [gentoo]
• [SDL]

*: The linked release notes describes the significant changes at 0.9.0.


[Buildbot] <https://www.buildbot.net/>

[newer versions] <https://docs.buildbot.net/latest/relnotes/0.9.0.html>

[mariadb] <https://buildbot.mariadb.org>

[python] <https://buildbot.python.org/all>

[buildbot] <https://buildbot.buildbot.net>

[scummvm] <https://buildbot.scummvm.org>

[sagemath] <http://build.sagemath.org>

[openwrt] <https://buildbot.staging.openwrt.org/images>

[gentoo] <https://gkernelci.gentoo.org>

[SDL] <https://buildbot.libsdl.org>


1 Install
═════════

1.1 From ELPA
─────────────

  Buildbot is currently available at elpa-devel:

  ┌────
  │ (add-to-list 'package-archives
  │ 	     ("elpa-devel" . "https://elpa.gnu.org/devel/"))
  │ (package-refresh-contents)
  │ (package-install 'buildbot)
  └────


1.2 Manual install
──────────────────

  Clone this repo, and add to load path (assuming you clone to
  `~/.emacs.d'):

  ┌────
  │ cd ~/.emacs.d
  │ git clone https://g.ypei.me/buildbot.el.git
  └────

  ┌────
  │ (add-to-list 'load-path "~/.emacs.d/buildbot.el")
  └────

  After that, require buildbot and set the host and builders, like so

  ┌────
  │ (require 'buildbot)
  │ (setq buildbot-default-host "https://buildbot.mariadb.org")
  └────


2 Use
═════

  Entry points:
  • `M-x buildbot-revision-open' prompts for a revision id (e.g. commit
    hash in git), and opens a view of the revision, including builds
    associated with changes associated with the revision.
  • `M-x buildbot-branch-open' prompts for a branch name, and opens up a
    view of revisions of this branch.
  • `M-x buildbot-builder-open' prompts for a builder name from a list
    of available builders, and opens up a view of recent builds by this
    builder.
  • The first time any of these commands is invoked it may take a bit
    longer than usual because it needs to make an extra call to get all
    builders.


3 TODOs
═══════

  • org link integration.
  • older buildbot api (not really sure if feasible)
  • copy url of the current view
  • highlight certain builders (e.g. mandatory for push)


4 Contact and Copyright
═══════════════════════

  `buildbot.el' is maintained by Yuchen Pei <id@ypei.org> and covered by
  [GNU AGPLv3+].  You may find the license text in a file named
  COPYING.agpl3 in the project tree.


[GNU AGPLv3+] <https://www.gnu.org/licenses/agpl-3.0.en.html>
