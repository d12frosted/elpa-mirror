The main entrypoints to this extension are two minor modes:

   M-x darkroom-mode
   M-x darkroom-tentative-mode

`darkroom-mode' makes visual distractions disappear: the
mode-line is temporarily elided, text is enlarged and margins are
adjusted so that it's centered on the window.

`darkroom-tentative-mode' is similar, but it doesn't immediately
turn-on `darkroom-mode', unless the current buffer lives in the
sole window of the Emacs frame (i.e. all other windows are
deleted). Whenever the frame is split to display more windows and
more buffers, the buffer exits `darkroom-mode'. Whenever they are
deleted, the buffer re-enters `darkroom-mode'.

Personally, I always use `darkroom-tentative-mode'.

See also the customization options `darkroom-margins' and
`darkroom-fringes-outside-margins', which affect both modes.