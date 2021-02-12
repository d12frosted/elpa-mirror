A remote web access to emacs
============================

Starts a web server allowing access to emacs through a webpage.
Take off from the terminal and make your emacs climb to the cloud.

Security
--------

There is no security in this module at all! If you plan to use this
on a non local, secure network you must secure the access yourself.
To secure you can use an SSH tunnel, an SSH SOCKS proxy or a reverse
HTTPS proxy.

Installation
------------

### Automatic package based installation

Available in the melpa repository.
If not present, add melpa to the list of archives (in your .emacs):

  (add-to-list 'package-archives
    '("melpa" . "http://melpa.milkbox.net/packages/") t)

Download and install:

  M-x package-install RET take-off RET


### Manual installaion

Make sure the web-server dependency is installed https://github.com/eschulte/emacs-web-server

In your emacs configuration file (.emacs) :

    (add-to-list 'load-path "~/.emacs.d/take-off")

Run
---

Loading take-off:

    (require 'take-off)

The following starts the web-server:

    (take-off-start <port>)

To stop the server:

    (take-off-stop)

emacs will be available at : `http://<local address>:<port>/`

Error
-----

If the error `Caught Error: (void-function symbol-macrolet)` occurs
you need to execute `(require 'cl)` before using take-off. This issue
is fixed in emacs 24.4.
