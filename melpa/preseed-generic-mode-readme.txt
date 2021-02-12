{{{ Introduction

Preface

     This package provides a major mode for Debian preseed files.
     It provides basic font-locking for preseed files, built upon generic-mode.

}}}
{{{ Installation

 Installation

     To install the Preseed-Generic mode

     o  Put this file (preseed-generic-mode.el) on your Emacs
        `load-path' (or extend the load path to include the
        directory containing this file) and optionally byte compile it.
     o  Or install it directly from the MELPA repository


}}}
{{{ DOCUMENTATION

 Usage

     To use the Preseed-Generic mode, put somewhere in your init file,

         ;; for Debian preseed files
         (require 'preseed-generic-mode)

     To have the preseed files opened with syntax highlighting
     automatically turn on, put the following at the top of the files:

         # -*- Preseed-Generic -*-

}}}
