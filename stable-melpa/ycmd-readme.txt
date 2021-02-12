
Description:

ycmd is a modular server that provides completion for C/C++/ObjC
and Python, among other languages. This module provides an emacs
client for that server.

ycmd is a bit peculiar in a few ways. First, communication with the
server uses HMAC to authenticate HTTP messages. The server is
started with an HMAC secret that the client uses to generate hashes
of the content it sends. Second, the server gets this HMAC
information (as well as other configuration information) from a
file that the server deletes after reading. So when the code in
this module starts a server, it has to create a file containing the
secret code. Since the server deletes this file, this code has to
create a new one for each server it starts. Hopefully by knowing
this, you'll be able to make more sense of some of what you see
below.

For more details, see the project page at
https://github.com/abingham/emacs-ycmd.

Installation:

Copy this file to to some location in your emacs load path. Then add
"(require 'ycmd)" to your emacs initialization (.emacs,
init.el, or something).

Example config:

  (require 'ycmd)
  (ycmd-setup)

Basic usage:

First you'll want to configure a few things. If you've got a global
ycmd config file, you can specify that with `ycmd-global-config':

  (set-variable 'ycmd-global-config "/path/to/global_conf.py")

Then you'll want to configure your "extra-config whitelist"
patterns. These patterns determine which extra-conf files will get
loaded automatically by ycmd. So, for example, if you want to make
sure that ycmd will automatically load all of the extra-conf files
underneath your "~/projects" directory, do this:

  (set-variable 'ycmd-extra-conf-whitelist '("~/projects/*"))

Now, the first time you open a file for which ycmd can perform
completions, a ycmd server will be automatically started.

When ycmd encounters an extra-config that's not on the white list,
it checks `ycmd-extra-conf-handler' to determine what to do. By
default this is set to `ask', in which case the user is asked
whether to load the file or ignore it. You can also set it to
`load', in which case all extra-confs are loaded (and you don't
really need to worry about `ycmd-extra-conf-whitelist'.) Or you can
set this to `ignore', in which case all extra-confs are
automatically ignored.

Use `ycmd-get-completions' to get completions at some point in a
file. For example:

  (ycmd-get-completions buffer position)

You can use `ycmd-display-completions' to toy around with completion
interactively and see the shape of the structures in use.
