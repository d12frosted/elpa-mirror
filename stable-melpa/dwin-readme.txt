
dwin enables interaction with desktop windows, i.e., windows of
external applications such as Firefox or okular, managed
by an external X11 window manager or Wayland compositor
(the latter currently only for KDE KWin).

Provides three types of desktop window interactions:
1. ⧉ arranging desktop windows from within Emacs with keys,
   e.g., move windows around, resize them etc.,
2. 🏷️ navigation by name,
   e.g., switching to firefox, zotero, back to Emacs, and
3. 🔀 directional navigation,
   e.g., moving to the window to the right or below.

Install from MELPA with

   (use-package dwin
     :config
     (dwin-setup))

⧉ arrange desktop windows with `dwin-grab', i.e., move them
around, resize them, etc.

🏷️ Navigation by name is done with `dwin-switch-to-app' that will
i) start an app, if it has no window yet,
ii) switch to its window, if it is not active, or
iii) switch back to Emacs, if it is already active (toggle).
For the latter, switching back to Emacs from outside Emacs,
a shortcut command for toggling the application has to be
bound desktop global by the window manager / compositor,
e.g., via

  (defun my/firefox (&optional prefix)
    (interactive (list current-prefix-arg))
    (dwin-switch-to-app "firefox" prefix))
  (dwin-keymap-desktopglobal-set "<f11>" #'my/firefox)

By default, navigation by name will switch to the first window of
an application, if it has several.  You can use a prefix arg to
switch to a specific one, e.g., C-2 M-x my/firefox or C-2 <f11> to
switch to the second one.

To switch back from outside Emacs to Emacs from any other window,
bind `dwin-switch-to-emacs-or' to a desktop global key:

  (dwin-keymap-desktopglobal-set "C-<f11>" #'dwin-switch-to-emacs-or)


🔀 Directional navigation between desktop windows and Emacs
windows is accomplished by `dwin-windmove-left' that has to be
bound to desktop global keys the same way as above:

 (dwin-keymap-desktopglobal-set "M-<left>"  #'dwin-windmove-left)
 (dwin-keymap-desktopglobal-set "M-<right>" #'dwin-windmove-right)
 (dwin-keymap-desktopglobal-set "M-<up>"    #'dwin-windmove-up)
 (dwin-keymap-desktopglobal-set "M-<down>"  #'dwin-windmove-down)

These functions try to move inside Emacs via windmove, and if
this fails, use the window manager to move out of Emacs.
The same method also uses the window manager to move
directional from desktop windows to other desktop windows
or back to Emacs.

How it is implemented

dwin enables Emacs to use functions provided by the window manager
to implement window interactions.  We captured all required
methods in a window manager proxy object `dwin-proxy' whose
methods can be called via `dwin-call'.  The proxy has to be created
once before use, e.g., during Emacs initialization, using
`dwin-setup'.  Currently two proxies are implemented:
- one for generic X11 window managers and
- one for KDE/KWin on Wayland or X11.
It should be possible to implement further ones.
The X11 proxy uses xdotool.
The KDE proxy uses
i) dbus calls to org.kde.kglobalaccel (KDE's shortcuts
   application), esp.  for directional navigation, and
ii) kdotool for navigation by name.
See file dwin-kwin.el.

That navigation works globally, also outside Emacs, requires that
the window manager forwards some keys globally to Emacs;
for KDE one can bind a one-line script _emacs-key that uses
Emacsclient to forward the key to Emacs, using `dwin-input-key'.
The KWin keybinding is accomplished by
`dwin-sync-desktopglobal-keys' (which is triggered automatically
when you set desktop global keys with `dwin-keymap-desktopglobal-set').
It assembles a brief .desktop application file and puts it into
KWin's application directory ~/.local/share/applications, where
KWin will take it up automatically.

See etc/example-emacs-inits/01-dwin-via-package/init.el for an
example configuration.

Custom variables are in dwin-core.el.

More information on the dwin webpage: https://github.com/lsth/dwin
