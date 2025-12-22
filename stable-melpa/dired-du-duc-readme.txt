This adapts Dired-Du to use "duc".  Get duc:

  https://duc.zevv.nl/
  https://github.com/zevv/duc

Enable with

  (global-dired-du-duc-mode)

You'll also want to remove any call to `dired-du-mode' in your initfiles.

The global mode does three things:

1. Regularly run "duc index" on `dired-du-duc-directories'.

2. Asynchronously run "duc index" each time a Dired buffer is opened.

3. Turn `dired-du-duc-mode' on in relevant buffers when duc is ready.
   Option `dired-du-duc-mode-predicate' can be configured to enable it
   always if you are fine with the slow "du" as a fallback.
