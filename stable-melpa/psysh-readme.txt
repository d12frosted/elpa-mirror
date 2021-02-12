## Installation

### A: The easy way

    $ wget psysh.org/psysh
    $ chmod +x psysh

And copy or make symlink to your $PATH dir.


### B: The other easy way

Get Composer.  See https://getcomposer.org/download/

    $ composer g require psy/psysh:@stable


### C: Project local REPL

Set `psysh-comint-buffer-process' (buffer local variable).

    (setq psysh-comint-buffer-process "path/to/shell.php")

`shell.php' is for example:

    #!/usr/bin/env php
    <?php
    // ↓Namespace for your project
    namespace Nyaan;

    // load Composer autoload file
    require_once __DIR__ . '/vendor/autoload.php';
    // load other initialize PHP files
    // require_once …

    echo __NAMESPACE__ . " shell\n";

    $sh = new \Psy\Shell();

    // Set project namespace in REPL
    if (defined('__NAMESPACE__') && __NAMESPACE__ !== '') {
        $sh->addCode(sprintf("namespace %s;", __NAMESPACE__));
    }

    $sh->run();

    // Termination message
    echo "Bye.\n";

See also https://cho-phper.hateblo.jp/entry/2015/11/10/031000 *(Japanese)*
