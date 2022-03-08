 ros is invoked with "M-x org-ros", then it waits for your selection, takes a
screenshot and saves it as orgfileopened.org_YYYYMMDD_hhmmss.png.

 It then adds a link to your org file and turns ON display-inline-images
showing you the recently screenshoted image.

 By default it tries to use system "scrot" software (you need to install it
on your system), and if it fails "screencapture" is used (for MacOS users
it is installed by default). You can change this defaults and its switches
by editing org-ros-* variables.

 Track updates, contact the author, see contributors and a demo on Github.
