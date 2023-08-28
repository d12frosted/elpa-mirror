                ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                 CAMERA - TAKE PICTURE WITH YOUR CAMERA
                ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This package allows you to take photos using your camera/webcam from
Emacs.


1 Installation
══════════════

  `camera' isn't available on any ELPA right now.  So, you have to
  follow one of the following methods:


1.1 Quelpa
──────────

  ┌────
  │ (quelpa '(camera :fetcher git
  │ 		 :url "https://codeberg.org/akib/emacs-camera.git"))
  └────


1.2 Straight.el
───────────────

  ┌────
  │ (straight-use-package
  │  '(camera :type git :repo "https://codeberg.org/akib/emacs-camera.git"))
  └────


1.3 Manual
──────────

  Download the `camera.el' file and put it in your `load-path'.


2 Usage
═══════

  Open camera with `M-x camera' and take photos with `SPC' or `M-x
  camera-capture'.
