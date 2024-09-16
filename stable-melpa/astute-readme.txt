Astute
======

A simple Emacs minor mode to redisplay ASCII punctuation as typographic
(or "smart") punctuation without altering file contents.

The following characters are redisplayed:

- '' -> ‘’ (single quotes)
- "" -> “” (double quotes)
- -- -> – (en dash)
- --- -> — (em dash)

Left/right quote is based on word boundary, not correct grammar. This is
intentional.
