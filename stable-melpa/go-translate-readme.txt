First, Install it via MELPA or download from github.
Make sure this is on your `load-path'.

Then add following lines to your `.emacs':

(require 'google-translate)
(setq gts-translate-list '(("en" "zh")))
(setq gts-default-translator
     (gts-translator
      :picker (gts-prompt-picker)
      :engines (list (gts-google-engine) (gts-google-rpc-engine))
      :render (gts-buffer-render)))

Now you can start your translation with `gts-do-translate' command.
