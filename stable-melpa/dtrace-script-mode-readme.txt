dtrace-script-mode: Mode for editing DTrace D language.

You can add the following to your .emacs:

(autoload 'dtrace-script-mode "dtrace-script-mode" () t)
(add-to-list 'auto-mode-alist '("\\.d\\'" . dtrace-script-mode))

When loaded, runs all hooks from dtrace-script-mode-hook
You may try

(add-hook 'dtrace-script-mode-hook 'imenu-add-menubar-index)
(add-hook 'dtrace-script-mode-hook 'font-lock-mode)

Alexander Kolbasov <akolb at sun dot com>



The dtrace-script-mode inherits from C-mode.
It supports imenu and syntax highlighting.


$Id: dtrace-script-mode.el,v 1.4 2007/07/17 22:10:23 akolb Exp $

; This file is NOT part of GNU Emacs

Copyright (c) 2007, Alexander Kolbasov
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above
   copyright notice, this list of conditions and the following
   disclaimer in the documentation and/or other materials provided
   with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
OF THE POSSIBILITY OF SUCH DAMAGE.
