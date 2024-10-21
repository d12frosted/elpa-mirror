Major mode for editing GLSL files.  Is is based on c-mode plus some features
and pre-specified fontifications.

Modifications from 2.5 of glsl-mode:
 * Moved most lists of GLSL syntax constants to separate file.
 * Numerous new constructs for modern GLSL and Vulkan.
 * glsl-mode is now a "proper" cc-mode, greatly improving the syntax
 * highlighting.
 * Initial work on a tree-sitter mode for GLSL.

Modifications from the 1.0 version of glsl-mode (jimhourihan):
 * Removed original optimized regexps for font-lock-keywords and
   replaced with keyword lists for easier maintenance
 * Added customization group and faces
 * Preprocessor faces
 * Updated to GLSL 4.6
 * Separate deprecated symbols
 * Made _ part of a word
 * man page lookup at opengl.org
