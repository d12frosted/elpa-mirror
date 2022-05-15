* sql-trino.el

  + What is it?

    Emacs comes with a SQL interpreter which is able to open a
    connection to databases and present you with a prompt you are
    probably familiar with (e.g. `mysql>', `pgsql>', `trino>',
    etc.). This mode gives you the ability to do that for Trino.


  + How do I get it?

    The canonical repository for the source code is
    <https://github.com/regadas/sql-trino>.

    The recommended way to install the package is to utilize Emacs's
    `package.el' along with MELPA. To set this up, please follow MELPA's
    [getting started guide], and then run `M-x package-install
    sql-trino'.


    [getting started guide] <https://melpa.org/#/getting-started>


  + Requirements

    Download the [Trino CLI], rename it to `trino' and put it in your
    `$PATH'.


    [Trino CLI]
    <https://repo1.maven.org/maven2/io/trino/trino-cli/378/trino-cli-378-executable.jar>


  + How do I use it?

    Within Emacs, run `M-x sql-trino'. You will be prompted by a
    minibuffer for a server. Enter a server and you should be greeted by
    a SQLi buffer with a `trino>' prompt.

    From there you can either type queries in this buffer, or open a
    `sql-mode' buffer and send chunks of SQL over to the SQLi buffer
    with the requisite key-chords.


  + Contributing

    Please open GitHub issues and pull requests.
