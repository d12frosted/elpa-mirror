This package gives an overview of the current regex search
candidates.  The search regex can be split into groups with a
space.  Each group is highlighted with a different face.

It can double as a quick `regex-builder', although only single
lines will be matched.

It also provides `ivy-mode': a global minor mode that uses the
matching back end of `swiper' for all matching on your system,
including file matching. You can use it in place of `ido-mode'
(can't have both on at once).