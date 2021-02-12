Send region or buffer to a format server (will setup localhost:58000 by default), with below formatters:
 - [standard](http://standardjs.com)  # zero config
 - [jsbeautify](https://github.com/beautify-web/js-beautify)  # little config
 - [esformatter](https://github.com/millermedeiros/esformatter)  # total config
 - [airbnb](https://github.com/airbnb/babel-preset-airbnb)  # **Airbnb** style formatter
 - [stylefmt](https://github.com/morishitter/stylefmt)  # css

## Install

1. You need NodeJS >= 6 in your system path

2. `js-format.el` is available via MELPA and can be installed via

    M-x package-install js-format

 If failed, ensure you have

    (add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/"))
    ;; or (add-to-list 'load-path "folder-of-js-format.el")

 line in your package config.

3. It should auto setup for the first time of use, according to different style package's setup command.

## Usage

After `(require 'js-format)`, below function can be used:

`js-format-setup` to switch and setup style (buffer local).
With C-u prefix, you can also setup the server (buffer local).
To make different mode using different format style, you can add below:

 ;; automatically switch to JSB-CSS style using jsbeautify-css as formatter
 (after-load 'css-mode
   (add-hook 'css-mode-hook
         (lambda()
           (js-format-setup "jsb-css"))))

The style name is from "styles.json" file, you can change the key to any.

`js-format-mark-statement` to mark current statement under point (only in `js2-mode').

`js-format-region` to try mark current statement, pass it to `js-format-server', then get
 back the result code to replace the statement.

`js-format-buffer` to format the whole buffer.

You may also want to bind above func to keys:

    (global-set-key (kbd "M-,") 'js-format-mark-statement)
    (global-set-key (kbd "C-x j j") 'js-format-region)
    (global-set-key (kbd "C-x j b") 'js-format-buffer)
    (global-set-key (kbd "C-x j s") 'js-format-setup)

## Add new format style guide

1. Create a folder, with name say "my-style"
2. Add package.json file, to specify an entry file in "main", or will use "index.js" if not specified.
3. Entry file should have `function format(code, cb){}` exported as a node module.
4. Add a style name and the folder into "styles.json" file to register the new style.

## Why use NodeJS Server instead of `call-process' etc.?

At first I'm using `call-process' to run a JS code, but every time
there's a lag, since starting a new node is a heavy operation, and
the output/input pipe not easily controlled if run as deamon, with
need of formatting region constantly, or even, auto formatting when
press RETURN, that lag is fatal.

Using server instead, giving a fast response from socket, and you
can format remotely (setup a format server in your workplace).

NodeJS is a good choise for using NPM, with rich module to import,
and easy to write a new style with javascript.
