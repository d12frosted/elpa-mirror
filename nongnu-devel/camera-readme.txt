                ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                 CAMERA - TAKE PICTURE WITH YOUR CAMERA
                ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This package allows you to take photos using your camera/webcam from
Emacs.


1 Installation
══════════════

1.1 NonGNU ELPA
───────────────

  Camera is available on NonGNU ELPA.  If you don't have the archive
  setup, put something like the following in your init file:

  ┌────
  │ (add-to-list 'package-archives
  │ 	     '("nongnu" . "https://elpa.nongnu.org/nongnu/"))
  └────


1.2 Quelpa
──────────

  ┌────
  │ (quelpa '(camera :fetcher git
  │ 		 :url "https://codeberg.org/akib/emacs-camera.git"))
  └────


1.3 Straight.el
───────────────

  ┌────
  │ (straight-use-package
  │  '(camera :type git :repo "https://codeberg.org/akib/emacs-camera.git"))
  └────


1.4 Manual
──────────

  Download the `camera.el' file and put it in your `load-path'.


2 Usage
═══════

  Open camera with `M-x camera' and take photos with `SPC' or `M-x
  camera-capture'.
