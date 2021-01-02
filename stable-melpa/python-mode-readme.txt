Includes a minor mode for handling a Python/IPython shell, and can
take advantage of Pymacs when installed.

See documentation in README.org, README.DEVEL.org

Please report bugs at
https://gitlab.com/python-mode-devs/python-mode/issues

available commands are documented in directory "doc" as
commands-python-mode.org

As for `py-add-abbrev':
Similar to `add-mode-abbrev', but uses
`py-partial-expression' before point for expansion to
store, not `word'.  Also provides a proposal for new
abbrevs.

Proposal for an abbrev is composed from the downcased
initials of expansion - provided they are of char-class
[:alpha:]

For example code below would be recognised as a
`py-expression' composed by three
py-partial-expressions.

OrderedDict.popitem(last=True)

Putting the curser at the EOL, M-3 M-x py-add-abbrev

would prompt "op" for an abbrev to store, as first
`py-partial-expression' beginns with a "(", which is
not taken as proposal.
