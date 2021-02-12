This Flycheck extension provides an `ats2' syntax checker.

# Setup

Add the following to your init file:

(with-eval-after-load 'flycheck
  (flycheck-ats2-setup))

The ATSHOME environment variable may need to be set from within Emacs:

(setenv "ATSHOME" "/path/to/ats2")

If you use PATSHOME instead of ATSHOME, please set PATSHOME as follows:

(setenv "PATSHOME" "/path/to/ats2")
