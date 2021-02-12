Adds AVFS (http://avf.sourceforge.net/) support for seamless archive
browsing.  This extension therefore depends on the presence of `avfsd'
on your system.  In debian-derived distributions you can usually do

    apt-get install avfs

`avfs' is probably also available for Mac OS.  You're out of luck on
Windows, sorry.

Once the daemon is installed, run it with `mountavfs' and everything
"Should Just Work^TM".

See https://github.com/Fuco1/dired-hacks for the entire collection.
