If you find a bug, you may send an e-mail or open an issue at
https://git.daemons.it/drymer/nikola.el/
◊ Main commands:
  • `nikola-new-post': Creates a new post and opens it.
  • `nikola-new-page': Creates a new page and opens it.
  • `nikola-build': Builds the site.
  • `nikola-start-webserver': Starts nikola's webserver.
  • `nikola-stop-webserver': Stops nikola's webserver.
  • `nikola-deploy': Deploys the site.
  • `nikola-version': Shows nikola and nikola.el version.
◊ Variables:
  • `nikola-output-root-directory': Nikola's site directory.
  • `nikola-verbose': If set to *t*, it will create a buffer called
    **Nikola** with the output of all commands.  Set to *nil* by default.
  • `nikola-webserver-auto': If set to *t*, it will use `nikola auto' to
    launch the webserver.  If set to *nil*, it will use `nikola
    serve'.  Set to *nil* by default.
  • `nikola-webserver-host': Set it to *0.0.0.0* if you want to make the
    webserver accesible from outside the machine.  Set to *127.0.0.1* by
    default.
  • `nikola-webserver-port': Nikola's webserver port.  Set to *8000* by
    default.
  • `nikola-deploy-input': If *nil*, just execute plain deploy, if *t*,
    asks for user input, *any string* is passed to the deploy string
    automatically.
    This variable is intended to use with a deploy script or command that
    uses git, thus needs a commit message.  It could be used for whatever
    other reason, also.  To use the message writed on Emacs on the deploy
    order, you have to use the variable **$COMMIT**.  For example, your
    deploy command could be:
  ┌────
  │ DEPLOY_COMMANDS = {
  │      'default': [
  │          "git add .", "git commit -m \"$COMMIT\"", "git push"
  │      ]
  │  }
  └────
  Set to *nil* by default.
  • `nikola-new-post-extension': The extension of new posts. If it's a
    list, ido completion will be offered. Set to *html* by default.
  • `nikola-new-page-extension': The extension of new pages. If it's a
    list, ido completion will be offered. Set to *html* by default.
  • `nikola-deploy-input-default': If `nikola-deploy-input' is *t*, this
    variable changes the default value so you can just press RET. Set to
    *New post* by default.
◊ Hooks:
  Use them as you would usually do.
  • `nikola-build-before-hook'
  • `nikola-build-after-hook'
  • `nikola-deploy-before-hook'
  • `nikola-deploy-after-hook'
  If you only want to execute a simple script or command before or after
  building or deploying, you can set the next variables to that script's
  path or command:
  • `nikola-build-before-hook-script'
  • `nikola-build-after-hook-script'
  • `nikola-deploy-before-hook-script'
  • `nikola-deploy-after-hook-script'
  For example, to execute a script before deploying:
  ┌────
  │ (setq nikola-deploy-before-hook-script "~/scripts/pre-deploy.sh")
  └────
  For more complicated things, you should use create a function and add
  is a hook.
