* Description

Emacs's native auto-save feature simply
sucks. auto-save-buffers-enhanced.el provides such and other more
useful features which only require a few configurations to set up.

auto-save-buffers-enhanced.el borrows main ideas and some codes
written by Satoru Takabayashi and enhances the original one. Thanks
a lot!!!

See http://0xcc.net/misc/auto-save/

* Usage

Just simply put the code below into your .emacs:

  (require 'auto-save-buffers-enhanced)
  (auto-save-buffers-enhanced t)

You can explicitly set what kind of files should or should not be
auto-saved. Pass a list of regexps like below:

  (setq auto-save-buffers-enhanced-include-regexps '(".+"))
  (setq auto-save-buffers-enhanced-exclude-regexps '("^not-save-file" "\\.ignore$"))

If you want `auto-save-buffers-enhanced' to work only with the files under
the directories checked out from VCS such as CVS, Subversion, and
svk, put the code below into your .emacs:

  ;; If you're using CVS or Subversion or git
  (require 'auto-save-buffers-enhanced)
  (auto-save-buffers-enhanced-include-only-checkout-path t)
  (auto-save-buffers-enhanced t)

  ;; If you're using also svk
  (require 'auto-save-buffers-enhanced)
  (setq auto-save-buffers-enhanced-use-svk-flag t)
  (auto-save-buffers-enhanced-include-only-checkout-path t)
  (auto-save-buffers-enhanced t)

You can toggle `auto-save-buffers-enhanced' activity to execute
`auto-save-buffers-enhanced-toggle-activity'. For convinience, you
might want to set keyboard shortcut of the command like below:

  (global-set-key "\C-xas" 'auto-save-buffers-enhanced-toggle-activity)

Make sure that you must reload the SVK checkout paths from your
configuration file such as `~/.svk/config', in which SVK stores the
information on checkout paths, by executing
`auto-save-buffers-reload-svk' after you check new files out from
your local repository. You can set a keyboard shortcut for it like
below:

  (global-set-key "\C-xar" 'auto-save-buffers-enhanced-reload-svk)

For more details about customizing, see the section below:
