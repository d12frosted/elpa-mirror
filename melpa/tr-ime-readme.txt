Emulator of GNU Emacs IME patch for Windows (tr-ime) emulates the C
implementation part of an IME patch for GNU Emacs that allows to input
Japanese using the Windows IME (Input Method Editor).  On Emacs 26.2 or
later, Japanese input using the IME is now possible even without the IME
patch.  However, some of the features of the IME patch are not implemented
in current Emacs, so it is possible to type Japanese on Emacs without the
IME patch, but it is not convenient.

w32-ime.el in the w32-ime package manages the upper layer of the IME
patch and provides the convenient features but it could not be used on
emacs.exe without the IME patch applied.  tr-ime emulates the lower
layers of the IME patches and can interact with w32-ime.el.  So, using
tr-ime, w32-ime.el can be used on emacs.exe without the IME patch applied.

By using tr-ime and w32-ime.el together, emacs.exe without the IME patch
can use the same convenient features as the IME patched emacs.exe.  They
can display the on/off state of the IME in the mode line as UI/UX features.
They also have hooks to call when the IME state is changed.  With these
hooks, you can change the color and shape of the cursor depending on the
IME on/off status to be visually known to the IME state.

To use standard features (stable but less functionality) of the tr-ime
package, add the following code to your init.el or .emacs
It loads the tr-ime-mod DLL module if you use Emacs 27.

  (tr-ime-standard-install)
  (setq default-input-method "W32-IME")
  (w32-ime-initialize)

To use advanced features (experimental but more functionality) of the
tr-ime package, add the following code to your init.el or .emacs
It loads the tr-ime-modadv DLL module.

  (tr-ime-advanced-install)
  (setq default-input-method "W32-IME")
  (w32-ime-initialize)
