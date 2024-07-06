Major mode for editing OpenGLSL grammar files, usually files ending with
`.vert', `.frag', `.glsl', `.geom'.  Is is based on c-mode plus some
features and pre-specified fontifications.

Modifications from the 1.0 version of glsl-mode (jimhourihan):
 * Removed original optimized regexps for font-lock-keywords and
   replaced with keyword lists for easier maintenance
 * Added customization group and faces
 * Preprocessor faces
 * Updated to GLSL 4.6
 * Separate deprecated symbols
 * Made _ part of a word
 * man page lookup at opengl.org

This package provides the following features:
 * Syntax coloring (via font-lock) for grammar symbols and
   builtin functions and variables for up to GLSL version 4.6
 * Indentation for the current line (TAB) and selected region (C-M-\).
 * Switching between file.vert and file.frag
   with S-lefttab (via ff-find-other-file)
 * interactive function glsl-find-man-page prompts for glsl built
   in function, formats opengl.org url and passes to browse-url
