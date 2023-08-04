<!-- markdown-link-check-disable -->
[![MELPA](http://melpa.org/packages/elpa-clone-badge.svg)](http://melpa.org/#/elpa-clone)
[![MELPA Stable](http://stable.melpa.org/packages/elpa-clone-badge.svg)](http://stable.melpa.org/#/elpa-clone)
[![CI](https://github.com/dochang/elpa-clone/actions/workflows/ci.yml/badge.svg)](https://github.com/dochang/elpa-clone/actions/workflows/ci.yml)
[![CircleCI](https://dl.circleci.com/status-badge/img/gh/dochang/elpa-clone/tree/master.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/dochang/elpa-clone/tree/master)
[![GitHub](https://img.shields.io/github/license/dochang/elpa-clone)](https://github.com/dochang/elpa-clone/blob/master/LICENSE)
[![Say Thanks!](https://img.shields.io/badge/say-thanks-green)](https://saythanks.io/to/dochang)
<!--
See the following issues for details.

<https://github.com/BlitzKraft/saythanks.io/issues/60>
<https://github.com/BlitzKraft/saythanks.io/issues/103>
-->
<!-- markdown-link-check-enable -->

Mirror an ELPA archive into a directory.

Prerequisites:

- Emacs 24.4 or later
- cl-lib
- rsync (optional, but recommended)

Installation:

`elpa-clone` is available on [MELPA] and [el-get].

[MELPA]: https://melpa.org/
[el-get]: https://github.com/dimitri/el-get

To install `elpa-clone' from git repository, clone the repo, then add the
repo dir into `load-path'.

Usage:

To clone an ELPA archive `http://host/elpa' into `/path/to/elpa', invoke
`elpa-clone':

    (elpa-clone "http://host/elpa" "/path/to/elpa")

`elpa-clone' can also be invoked via `M-x'.

You can customize download interval via `elpa-clone-download-interval'.  But
note that the *real* interval is `(max elpa-clone-download-interval 5)'.

### Prefer rsync

Some ELPA archives can more efficiently be cloned using rsync:

    (elpa-clone "elpa.gnu.org::elpa/" "/path/to/elpa")
    (elpa-clone "rsync://melpa.org/packages/" "/path/to/elpa")
    (elpa-clone "rsync://stable.melpa.org/packages/" "/path/to/elpa")

Currently, only the following archives support rsync:

- GNU ELPA
- MELPA
- MELPA Stable

By default, `elpa-clone` selects the appropriate sync method based on the
upstream url, but you can also specify the method you want:

    (elpa-clone "foo/" "bar/" :sync-method 'rsync)
    (elpa-clone "foo::bar/" "/path/to/elpa" :sync-method 'local)
    (elpa-clone "rsync://foo/bar/" "/path/to/elpa" :sync-method 'url)

Available methods are:

- `rsync`: use rsync (recommended)
- `url`: use the `url` library
- `local`: treat upstream as a local directory
- `nil`: choose a method based on upstream

Note:

`elpa-clone' will **NOT** overwrite existing packages but will clean
outdated packages before downloading new packages.  If a package file is
broken, remove the file and call `elpa-clone' again.

License:

GPLv3
