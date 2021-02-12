
Magit-tbdiff provides a Magit interface to git-tbdiff [1] and
git-range-diff, subcommands for comparing two versions of a topic
branch.

There are three commands for creating range diffs:

  * `magit-tbdiff-ranges' is the most generic of the three
    commands.  It reads two ranges that represent the two series to
    be compared.

  * `magit-tbdiff-revs' reads two revisions.  From these (say, "A"
    and "B"), it constructs the two series as B..A and A..B.

  * `magit-tbdiff-revs-with-base' is like the previous command, but
    it also reads a base revision, constructing the range as
    <base>..A and <base>..B.

These commands are available in the transient `magit-tbdiff', which
in turn is available in the Magit diff transient, bound by default
to "i" (for "interdiff" [2]).  So, with the default keybindings,
you can invoke the tbdiff transient with "di".

As of v2.19.0, Git comes with the "range-diff" subcommand, an
analog of tbdiff.  The option `magit-tbdiff-subcommand' controls
which subcommand is used.

When Magit-tbdiff is installed from MELPA, no additional setup is
needed beyond installing git-tbdiff [1].  The tbdiff transient will
be added under the Magit diff transient, and Magit-tbdiff will be
loaded the first time that the tbdiff transient is invoked.

[1] https://github.com/trast/tbdiff

[2] When I selected that key, I didn't know what an interdiff was
    and that what tbdiff refers to as an "interdiff" isn't
    technically one.  Sorry.

    https://public-inbox.org/git/nycvar.QRO.7.76.6.1805062155120.77@tvgsbejvaqbjf.bet/#t
