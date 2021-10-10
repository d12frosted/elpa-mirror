To be the most powerful translator on Emacs. Supports multiple translation engines such as Google, Bing, deepL.

First, Install it via MELPA or download from github. Make sure this is on your `load-path'.

Then, add following lines to your `.emacs':

  (require 'go-translate)
  (setq gts-translate-list '(("en" "zh")))
  (setq gts-default-translator
       (gts-translator
        :picker (gts-prompt-picker)
        :engines (list (gts-google-engine) (gts-google-rpc-engine))
        :render (gts-buffer-render)))

And start your translate with command `gts-do-translate'.
