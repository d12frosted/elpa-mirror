This is a simple benchmark of calls to Emacs require and load functions.
It can be used to keep track of where time is being spent during Emacs
startup in order to optimize startup times.
The code is based on init-benchmarking.el by Steve Purcell.

; Installation:

Place this file in your load path and add the following code to the
beginning of your Emacs initialization script:

(require 'benchmark-init)

Data collection will begin as soon as benchmark-init has been loaded.
