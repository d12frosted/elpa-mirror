# The Emacs mail reader VM (a.k.a. ViewMail)

VM is a mail reader that runs under GNU Emacs and XEmacs. It was
written as an alternative to the Emacs RMAIL mail reader by Kyle
Jones. VM is highly configurable and easy to use. It supports POP and
IMAP mail servers, understands MIME, and handles mail folders in the
standard UNIX mailbox format and the BABYL format used by the RMAIL
mailer. It has a powerful virtual folder facility to facilitate
searching as well as more advanced handling of multiple mail folders.
This site exists to continue VM development community project.

VM is available from 
  <https://gitlab.com/emacs-vm/vm>

## Version Information

The VM versions 8.3.0 and up are designed to work with:

- Gnu Emacs versions 28.1 or higher
- XEmacs version (not currently tested with XEmacs)

## Installation

VM releases are avaliable through a non-gnu ELPA package:

```
   M-x package-install <ret> vm <ret>
```

If you wish to build from source, see [INSTALL](INSTALL)
for instructions.

If you are new to VM, see example.vm for example configuration
settings (to be put into a `~/.vm` file). Read more in the VM manual
in _info_ format.

## Bugs

The preferred way to report bugs is to file issues at
  <https://gitlab.com/emacs-vm/vm/-/issues>

Alternatively, bugs can be reported report in VM using the VM function.

```
M-x vm-submit-bug-report
```

However, this function currently sends an e-mail to a mailing list,
which makes the issue hard to track, hence the Gitlab issue tracker
normally is a better option.

The mail message includes your VM configuration information. If you are
creating an issue, this information maybe pasted into the GitLab issue.

Please include information about how to reproduce the problem. Please
report any problems or bugs, otherwise they cannot be fixed!

If you are not sure that the problem is a bug or that it could be of
general importance to other users, you are welcome to discuss it on
the mailing lists, [see below](#communication).

## Communication

Communication is done on four mailing lists (VM **is** a mail reader
after all):

- [viewmail-info](https://lists.nongnu.org/mailman/listinfo/viewmail-info)
  for general discussion of VM features and issues.
- [viewmail-dev](https://lists.nongnu.org/mailman/listinfo/viewmail-dev)
  for VM development discussions. Developers and users interested in
  development are both welcome.
- [viewmail-bugs](https://lists.nongnu.org/mailman/listinfo/viewmail-bugs)
  for reporting bugs in VM. Bugs reported using `vm-submit-bug-report`
  go here.
- [viewmail-maintainers](https://lists.nongnu.org/mailman/listinfo/viewmail-maintainers)
  aimed at at VM maintainers and packagers. The list is public but of
  limited interest outside its target audience.

## See also

[CONTRIBUTING](CONTRIBUTING.md) for information on how to get involved
in the project.

[HISTORY](HISTORY.md) for some notes on the history of the project.
