1 wconf
═══════

1.1 About
─────────

  `wconf' is a minimal window configuration manager for [GNU Emacs].
  Its goal is to have several window configurations easily available, to
  switch between them, and to save them to disk and later restore them.

  For example, I might have a default "workspace" for miscellaneous
  stuff, and then I might have workspaces "UI", "MT", "DB" for a classic
  3-tier application.

  Can double as a "boss" key; not that you would ever use something like
  that yourself.


[GNU Emacs] <http://www.gnu.org/software/emacs/>


1.2 Using the Package
─────────────────────

  Make sure the files are in your `load-path', and either `(require
  'wconf)' or make sure its autoloads are known to Emacs — if you have
  installed from a package archive, that should take care of both.

  Here is an example from my configuration to show you the intended use
  of `wconf'.
  ┌────
  │ (add-hook 'desktop-after-read-hook      ;so we have all buffers again
  │ 	  (lambda ()
  │ 	    (wconf-load)
  │ 	    (wconf-switch-to-config 0)
  │ 	    (add-hook 'kill-emacs-hook
  │ 		      (lambda ()
  │ 			(wconf-store-all)
  │ 			(wconf-save))))
  │ 	  'append)
  │ 
  │ (global-set-key (kbd "C-c w s") #'wconf-store)
  │ (global-set-key (kbd "C-c w S") #'wconf-store-all)
  │ (global-set-key (kbd "C-c w r") #'wconf-restore)
  │ (global-set-key (kbd "C-c w R") #'wconf-restore-all)
  │ (global-set-key (kbd "C-c w w") #'wconf-switch-to-config)
  │ (global-set-key (kbd "C-<prior>") #'wconf-use-previous)
  │ (global-set-key (kbd "C-<next>") #'wconf-use-next)
  └────
  After `desktop' has restored all file buffers from my last session,
  `wconf-load' will get its stored configs from `wconf-file' (defaults
  to `<YOUREMACSDIR>/wconf-window-configs.el'), and I want it to
  immediately switch to the first configuration.  Then we hook into
  killing emacs to store and save all our configurations in that same
  file.  The global key bindings expose those commands that I consider
  useful in day-to-day work.


1.3 Concepts
────────────

  The main idea is +stolen from+ inspired by `workgroups'.  We keep a
  list of configuration pairs.  Each such pair consists of an /active/
  configuration (what you see when you switch to this slot of the list),
  and a /stored/ one (what you have in the back, and maybe save to disk
  at some point).  In `workgroups' parlance, these are the working and
  base configs.

  At each point in time there is (at most) one configuration current.
  You can explictly store and restore the current active configuration
  to/from the stored one, or do likewise for all configurations.  For
  example, you might decide that you have a carefully hand-crafted set
  of configurations that you always want to start from, but that you do
  not wish to change this setup, except when doing so explicitly.
  That's easy: just remove the `(wconf-store-all)' call from the above
  hook function.

  A nice feature of `wconf' is that it does not alter any hooks or
  settings outside its own small world, and I intend to keep it that
  way.  This implies that the currently active configuration is only
  updated explicitly, via one the functions/commands in the package.


1.4 Rationale, and Other Packages
─────────────────────────────────

  I used <https://github.com/tlh/workgroups.el> for several years.  It
  is a great package, which offers a lot of additional features besides
  the core business of managing window configs.  It also has some
  shortcomings, is somewhat complex (at 79k), and I occasionally
  experienced minor glitches.  Most importantly, it has been
  unmaintained for roughly 4 years now.

  <https://github.com/pashinin/workgroups2> promises to pick up where
  workgroups left, and is actively maintained.  The main difference, as
  I understand it, is the desire to restore "special" buffers as well
  (help, info, org-mode agendas, notmuch mail, you name it).  Finally
  trying it, it did not provide a lot of benefit for my personal needs,
  but added still more complexity.  The functionality that I want should
  not require 179k of elisp.

  Nowadays (at least since the GNU Emacs 24.4 release), there are proper
  lisp-reader (de)serializations for both frame and window
  configurations, and `window.el' and `frameset.el' provide functions to
  deal with them (relatively) comfortably.  Desktop already (re)stores a
  single configuration.  That's when I decided that it's time to roll my
  own: build something light on top of what's already there, in order to
  provide persistent switchable configurations.


1.5 Notes, TODO
───────────────

  I only use a single fullscreen frame all the time.  An earlier version
  of this package stored configurations as whole framesets, without any
  effort to deal with the multiple-frames case.  It has now changed to
  deal with window configurations in a single frame only.  This is much
  better defined, simpler, and no longer suffers from annoying
  flickering effects.

  Calling the package commands from different frames inside a single
  session may or may not result in the behavior you want.  In the latter
  case, feel free to open an issue and describe what happens and what
  you expected/wanted to happen.  I explicitly do /not/ guarantee that
  the code will change to suit your wishes — but if minor changes could
  render it more generally useful, I am all ears.

  I am thinking about some rescaling options to deal with restoring on
  frames of different sizes (possible due to a different screen size).
  Filtering options for what is generally (re)stored (and how) might be
  a pleasant side effect.  Don't hold your breath.
