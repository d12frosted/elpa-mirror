Asynchronous fork of [envrc](https://github.com/purcell/envrc).

This package allows you to load environments buffer locally. The package is
named 'ben', which stands for Buffer ENvironments.

The project relies on [direnv](https://direnv.net) which allows to setup
per-directory environments through '.envrc' files.

The main feature of 'ben' is the asynchronous processing of
environments. Which prevents Emacs from freezing while loading
computationally heavy environments. This is specially the case for loading
'.envrc' files which rely on Guix, some computations can take hours to
complete. This package aims to facilitate loading such environments.

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
