w32-ime.el, formerly known as "Meadow features for NTEmacs", was part of
an IME patch for Emacs for Windows that allowed to input Japanese using
the Windows IME (Input Method Editor).  On Emacs 26.2 or later, Japanese
input using the IME is now possible even without the IME patch.  However,
some of the features of the IME patch are not implemented in current
Emacs, so it is possible to type Japanese on Emacs without the IME patch,
but it is not convenient.

w32-ime.el managed the upper layers of the IME patches and provided the
convenient features, but it is not contained in current Emacs.  It has
functions such as displaying the on/off state of the IME in the mode line
as UI/UX features.  It also has hooks to call when the IME state is
changed.  With these hooks, you can change the color and shape of the
cursor depending on the IME on/off status to be visually known to the
IME state.

To use w32-ime.el, add the following code to your init.el or .emacs

  (setq default-input-method "W32-IME")
  (w32-ime-initialize)
