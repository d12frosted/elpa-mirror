
Provides two types of navigation:
1. 🏷️ navigation by name,
   e.g., switching to firefox, zotero, back to Emacs, and
2. 🔀 directional navigation,
   e.g., moving to the window to the right or below, as well as
3. ⧉ arranging desktop windows from within Emacs with keys.

That navigation works globally, also outside Emacs, requires that
the window manager forwards some keys globally to Emacs;
for KDE one can bind a one-line script that uses Emacsclient
to forward the key to Emacs, using `dwin-input-key' defined in
sect.  3. See etc/bin/dwin-firefox for an example.  See
Further Details / 1 for why we do not use tools like qdotool for
sending keys.

Emacs then can use functions provided by the window manager
to implement window navigation globally.  We captured all required
methods in a window manager proxy object `dwin-proxy' whose
methods can be called via `dwin-call'.  The proxy has to be created
once before use, e.g., during Emacs initialization, using
`dwin-setup'.  Currently only a proxy for KDE is implemented.
But it should be possible to implement further ones.
The KDE proxy uses
i) dbus calls to org.kde.kglobalaccel (KDE's shortcuts
   application), esp.  for directional navigation, and
ii) kdotool for navigation by name.
See sect. 4 below.

🏷️ Navigation by name is provided by `dwin-switch-to-app' that will
i) start an app, if it has no window yet,
ii) switch to its window, if it is not active, or
iii) switch back to Emacs, if it is already active (toggle).
For each app (firefox, zotero etc.) one needs to
i) define one Emacs command (e.g., `my/firefox'),
ii) bind it to a key in Emacs and
iii) make sure this key is forwarded globally to Emacs,
  i.e.,
  a) create a small script (e.g., etc/bin/dwin-firefox) and
  b) bind it globally to this key.
Switching back to Emacs is handled by `dwin-switch-to-emacs-or'.
It needs the same handling as the other apps above.
By default, navigation by name will switch to the first window of
an application, if it has several.  You can use a prefix arg to
switch to a specific one, e.g., C-2 M-x my/firefox or C-2 <f11> to
switch to the second one.  See sect. 5 below.

For 🔀 directional navigation, we defined a short function
`dwin-windmove-left' for each direction.  The function tries to
move inside Emacs via windmove, and if this fails, uses the
window manager to move out of Emacs.
The same method also uses the window manager to move
directional from desktop windows.  See sect.  6.

Sect.  7 contains function `dwin-grab' to ⧉ arrange desktop
windows, i.e., to resize them, reposition them etc.

See etc/example-emacs-init/init.el for an example configuration.

Known Issues and Limitations:
1. Requesting help for a **global** key binding with `describe key'
   will not work.  Emacs will get the key forwarded, but not as
   input for the already running describe-key function.  In effect,
   if you say M-x describe-key and then type a global key like
   M-left, its action is executed and help for the **next** key the
   user types is shown.  To view the help, you have to know how the
   key is called in Emacs and say M-: (describe-key (kbd
   "M-<left>")) instead.  One could instrument `dwin-input-key' to
   detect if describe-key is running by checking
   (describe-key (kbd "M-<left>")) and then run describe-key with
   the key instead of the command the key is bound to.  However, I
   found no way to cancel the already running describe-key
   command.  So the second issue will persist.

Further details:
1. Why cannot we just use ydotool to send keys to Emacs?
   Tools like ydotool seem to be able to send key events only to
   the active/focused window and would be able only to implement
   the cases where one wants to move from within Emacs, not the
   cases where one wants to move back to Emacs from other
   applications (or between other applications).  One could
   reimplement dwin in bash, then there is no need to input keys
   into Emacs anymore.

   Unfortunately sending dbus events to kwin from bash was unstable
   for me: running
     qdbus6 org.kde.kglobalaccel /component/kwin \
       org.kde.kglobalaccel.Component invokeShortcut
       "Switch Window Left"
   often (not always) yielded
     Cannot find 'org.kde.kglobalaccel.Component' in object
       /component/kwin at org.kde.kglobalaccel
   This never happened when sending the same events from Emacs.
