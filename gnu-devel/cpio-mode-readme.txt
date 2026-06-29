# -*- mode: org; encoding: utf-8 -*-
#	$Id: README,v 1.14 2019/01/07 07:44:34 doug Exp $	

# 
# Copyright © 2019 Free Software Foundation, Inc.
# All rights reserved.
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 

* Caveat
This is currenty beta code.
Please don't do anything critical with it.

That said, the current version /does/ create a backup
of every archive that it is applied to.
It is your responsibility to remove those archives.
They are marked with a date time stamp in the form YYYYmmddHHMMSS.mmm.
* Intent

The intents of cpio-mode are the following:
• It should be as much like dired as possible.¹
  (The current keymap effectively duplicated dired's.)
• It should be easy to add new archive formats to it.
  That is, in particular, it should admit, for any inode-like archive format,
  an absract interface that leaves the the UI intact
  and independent of the underlying format.
  This should, for example, allow 
  for converting between and among archive formats nearly trivially.

It should also allow for dired-like functions.
Specifically, those things that dired within emacs allows.
That includes things like
• Adding/deleting entries
• Editing entries
• Changing an entry's attributes (chown, chgrp, chmod, etc.).

Note that, if you can write the archive,
then all those operations will succeed in the archive.
And they will be carried in the saved archive.
They may, however, not apply to files extracted from the archive
if you do not have sufficient permissions to perform those operations
on the corresponding files.
chown(1), for example, may require that you be root.
________________
¹Yes, this is a terrible requirement.
 However, it does allow for incremental development relatively easily.

* Adding a new archive type

To add a new archive type a devloper should be able to do so
merely by being able to parse an entry and
write a parsed entry back to a file.
 
Right now (2018 Jun 09), the cpio-mode package supports the above
for the bin, crc, newc and odc formats of cpio archives.²
However, the internal structure of cpio-mode implements
all of the manipulation code in terms of parsed headers
(which look much like inodes), so adding new formats should be
relatively easy.
See the documentation in cpio-mode.el
for a slightly more detailed description of this structure.

You should be able to add a new format if
1. it has entry headers that have an inode-like format;
2. the end of a [padded] entry header is the start of the entry contents.

If you need to extend the inode-like format (for example the crc format),
then you can simply add the extensions to the attributes
of the entries in the catalog.
This will likely require updating the various build-catalog functions
and the make-header-string functions.
________________
² For archives without device entries, this means
that hpbin and hpodc are also supported.

* Other code

Some more generic code is delivered with cpio-mode.

** cpio-generic.el

This file contains truly generic lisp code.
For the most part, it employs the prefix cg-
to keep its names distinct.
Some names begin cpio-.

** cpio-modes.el

This file contains generic code pertaining to file modes,
both numeric and symbolic.

Constants corresponding to mode bits are named with lispish versions
of the names given in /usr/include/linux/stat.h.
The same goes for the predicates about a file's (entry's) type.

Otherwise, the prefix cpio- is used.

** cpio-affiliated-buffers.el

This file contains a package called Affiliated Buffers
that should be independent.
(And one day it will be published that way.)

The idea behind cpio-affiliated-buffers.el is
that there's a reference buffer and that reference buffer can have
buffers affiliated with it.
Killing the reference buffer should kill all the affiliated buffers.
An affiliated buffer can have buffers affiliated with it.
Affiliated buffers don't typically have anything to do with each other,
and cpio-affiliated-buffers.el includes no way to create such relationships.

cpio-mode uses the following sort of structure of buffer affiliation:

archive
   ├─ cpio-dired buffer
   ├─ entry
   ├─ entry
   └─ ...

In theory it could be a full tree.
For example, if one of the entries were itself a cpio archive,
then its entries could also be included:

archive
   ├─ cpio-dired buffer
   ├─ entry
   ├─ an entry that is a cpio archive.
   │    ├─ its cpio-dired-buffer
   │    ├─ one of its entries
   │    ├─ another such entry
   │    └─ ...
   ├─ entry
   └─ ...

* Testing

cpio-mode includes a few ERT tests.
All the testing is sunny day day testing.
Rarely are any error conditions tested.

** Dependencies
For any testing to succeed set your umask to 022,
otherwise all of the data in the tests are incorrect.

Since the automated tests explicitly invoke cpio-mode 
as does the function (cdmt-reset),
you cannot use any automatic invocation of cpio-mode.
One way of doing this is to invoke »emacs -Q«.
(You'll also need »-eval "(setq load-path (add-to-list 'load-path \".\"))"«.
until I figure out the right way to handle loading.)
Thus, a good invocation is
    »emacs -Q -eval "(setq load-path (add-to-list 'load-path \".\"))"«
Some recommendations for automatic invocation of cpio-mode can be found
in the comments near the top of cpio-mode.el.

And, of course, you must run ./configure
before trying to run automated tests.

** Internals
- cpio-generic-tests.el provides basic testing of some of the funciton
  implemented in cpio-generic.el.

- cpio-modes-test.el provides basic testing of some of the function
  implemented in cpio-modes.el.

- cab-test.el provides basic testing of cpio-affiliated-buffers.el.
  (Yes, cpio-affiliated-buffers.el still has bugs.)

- cpio-newc-test.el provides basic testing of some of the function
  implemented in cpio-newc.el.

The following files contain tests that exercise cpio function
through the dired-style interface.
    * cpio-dired-bin-test.el
    * cpio-dired-crc-test.el
    * cpio-dired-odc-test.el
    * cpio-dired-test.el -- tests of the newc format.

The general form of a check is the following:
    1. Do something.
    2. Compare the dired-style buffers.
    3. Compare the archive buffers.
    4. Compare the catalogs.
Occasionally, there are other things, like checking for modification,
or visibility of a window.
Some tests use a "large" cpio archive (one with 26·5 = 130 entries).
Those are not fast, so be patient if you're going to run them.

All dired tests are based on cpio-dired-test.el and,
yes, there's duplicated code.
Some of this should be cleaned up once development seems stable.

* Cruft

There's a fair amount of cruft in the code at the moment.
If I've done my job correctly, it is at least separate
from the main body of code (like on a different page).
Some is tools that have been built to help with development;
some is just hacks.
