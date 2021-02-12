; Eloud is a lightweight, interactive screen reader.  It uses the espeak speech synthesizer as a backend.

Installation

1. Install espeak

First, install espeak.  On Ubuntu or Debian, use:

    sudo apt-get install espeak

On OSX, use:

    brew install espeak

Or find the compiled version at http://espeak.sourceforge.net/download.html

2. Install the package

Clone this repo:

    cd ~
    git clone https://github.com/smythp/eloud.git

Add the load path to your .emacs:

    (add-to-list 'load-path "~/eloud/")

Finally, set the path to espeak by adding this to your .emacs:

    (setq eloud-espeak-path "~/eloud/")
Quick install

    cd ~
    git clone https://github.com/smythp/eloud.git
    (add-to-list 'load-path "~/eloud/")
    (setq eloud-espeak-path "/usr/bin/espeak")
