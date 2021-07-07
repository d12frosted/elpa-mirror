#+title: Read Me

[[./screenshot.png]]

* Making Org-mode Beautiful
** This theme is dedicated to my wife Shell
  Who—in her beauty, her love, and her love for beauty—has shown me
  that form can enhance function.
* Mission
  - Make org mode headlines easy to read.  In any theme.
  - Make it look more like a published book and/or desktop app, less
    like angry fruit salad.
  - Make it awesome to live in an org buffer.
* Usage
  Load this theme over top your existing theme, and you should be
  golden.  If you find any incompatibilities, let me know with what
  theme and I will try and fix it.

  When loading a whole new theme overtop, org-beautify-theme will
  still be active with the old theme.  Just unload org-beautify-theme
  and then reload it, and everything will be fine again.

  If you still get really ugly headlines, customize the
  ~org-beautify-theme-use-box-hack~ variable and set it to nil (false).

* Changelog
   - v0.4 :: [2017-09-08]
     - Add org-beautify-theme-use-box-hack to allow the user to
       fix ugly boxes.
   - v0.3.2 :: [2017-08-29]
     - Update License
   - v0.3.1 :: [2016-10-19]
     - Fix load path issues (Thanks PierreTechoueyres!)
     - reverse chronological changelog, because ah-doy!
   - v0.2 :: [2016-08-08]
     - Better repository Location
     - Fix so that you can load the theme properly.
   - v0.1.2 :: [2014-01-06]
     - Add Verdana font to fall back on
   - v0.1.1 :: [2014-01-06]
     - Fix checkboxes
   - v0.1 :: First Release
     - Make the colors suck a lot less, and the buffers look a lot nicer.
