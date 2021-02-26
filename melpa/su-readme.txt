This package facilitates automatic privilege escalation for file
permissions using TRAMP.

You can install the package by either cloning it yourself, or by
doing M-x package-install RET su RET.

After that, you can enable it by putting the following in your init
file:

    (su-mode +1)

When `su-mode' is enabled, you will be able to edit files which you
lack permissions to write. `su-mode' will automatically switch the
visited path to a TRAMP path encoding the correct privelege
escalation just before you save the file. See the README for more
info.
