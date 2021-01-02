
-*- mode: org -*-

* HyperEstraier Interface for Gnus nnir Method.

This file provides a Gnus nnir interface for [[http://fallabs.com/hyperestraier/index.html][HyperEstraier]].
HyperEstraier is powerful, fast, multi-lingual, mail-friendly search engine.
You can use this search engine with `nnmh', `nnml', and `nnmaildir'.

** Indexing

You can create the index by the following command.

: % mkdir ~/News/casket                              # if necessary
: % estcmd gather -cl -fm -cm ~/News/casket ~/Mail   # for nnml/nnmh

Sometimes, it is recommended to optimize the index.

: % estcmd optimize ~/News/casket

You may choose any directory for index or target.

: % mkdir ~/.index                                   # if necessary
: % estcmd gather -cl -fm -cm ~/.index ~/Maildir     # for nnmaildir

Target directory can be specified by `nnir-est-prefix' or directory
property of `nnmaildir'.
Index directory can be specified by `nnir-est-index-directory'.

** Emacs Setup

In .emacs, you should set as the following. (`gnus-select-method' is
used in the following examples, but you can specify it in
`gnus-secondary-select-methods`, too.)

First of all, you should choose which method to use HyperEstraier.

: (require 'nnir-est)
: (setq nnir-method-default-engines
:        '((nnmaildir . est)
:          (nnml . est)
:          (nntp . gmane)))

If you are using `nnml', specifying mail directory may be sufficient.

: ;; nnml/nnmh
: (setq gnus-select-method '(nnml ""))
: (setq nnir-est-prefix "/home/john/Mail/")

Or you can specify it as attribute.

: (setq gnus-select-method '(nnml "" (nnir-est-prefix "/home/john/Mail/")))

If `directory' attribute is specified, it will be used for prefix.
Otherwise, `nnir-est-prefix' will be used.

: ;; nnmaildir
: (setq gnus-select-method '(nnmaildir "" (directory "~/Maildir"))
:                            (nnir-est-index-directory "~/.index"))


* Query Format

In `gnus-group-make-nnir-group' query, you can specify following
attributes in addition to query word.

- @cdate>, @cdate< :: Mail date
- @author= :: sender
- @size>, @size< :: mail size
- @title= :: mail subject

You can also specify 'AND', 'NOT', 'ANDNOT' or 'OR' for content query word.
Queries are case-insensitive.

For example, the following query will search for the mails whose subject
include 'foobar' and 'foo' in the content, but not 'bar'.

: @title=foobar foo ANDNOT bar

The following query will search for the mails whose date is between
2013/01/01 and 2013/01/03.

: @cdate>2013/01/01 @cdate<2013/01/03
