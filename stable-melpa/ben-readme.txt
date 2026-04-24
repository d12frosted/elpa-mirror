Asynchronous fork of [envrc](https://github.com/purcell/envrc).

This package allows you to load environments buffer locally.  The package is
named 'ben', which stands for Buffer ENvironments.

The project relies on [direnv](https://direnv.net) which allows to setup
per-directory environments through '.envrc' files.

The main improvement of 'ben' over 'envrc' is the asynchronous processing of
environments, which prevents Emacs from freezing.  This is especially useful
while loading computationally heavy environments, such when loading '.envrc'
files that rely on Guix.  In these cases, computations can take hours to
complete.  This package aims to facilitate loading such environments in the
background.

The main additions of the fork are:

- Controlling the synchronousity of the environment loading mechanism through
the `ben-async-processing' boolean variable.

- Enhanced mode-line lighter for showcasing `none', `loading', `on' and
  `deny' status.

- Process manager using tabulated list mode.

- Minibuffer support which can be controlled through the
  `ben-disable-in-minibuffer' boolean variable.

Enable `ben-global-mode' late in your startup files.  For
interaction with this functionality, see `ben-mode-map', and the
commands `ben-reload', `ben-allow' and `ben-deny'.

In particular, you can enable keybindings for the above commands by
binding your preferred prefix to `ben-command-map' in
`ben-mode-map', e.g.

   (with-eval-after-load 'ben
     (define-key ben-mode-map (kbd "C-c e") 'ben-command-map))

For more information about 'ben', please see the README.org file.
