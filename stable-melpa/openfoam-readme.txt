┆ Open ∇             ┆ -*- mode: ∇; coding: utf-8; -*-
┆      F ield        ┆
┆      O peration    ┆
┆      A nd          ┆
┆      M anipulation ┆

This package provides major modes for editing OpenFOAM data files
and C++ code.  There are also user commands for managing OpenFOAM
case directories.

By default, verbatim text blocks in OpenFOAM data files are
indented like data which yields acceptable results for C++ code.
As an alternative, you can install the Polymode package from MELPA
stable.  Polymode provides multiple major mode support for editing
C++ code in verbatim text blocks.  OpenFOAM requires Polymode 0.2
or newer.  To actually enable Polymode, customize the variable
‘openfoam-verbatim-text-mode’.

If you think a ‘∇-mode’ command is a good idea so you can have a
fancy looking ‘mode’ variable in your OpenFOAM data files, then
just paste the following code into your Emacs initialization file:

     (defalias '∇-mode #'openfoam-mode)

OpenFOAM is cool and you should be too!
