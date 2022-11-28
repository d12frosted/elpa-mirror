h5dump (https://docs.hdfgroup.org/hdf5/develop/_view_tools_view.html) is a
tool for creating a textual representation of HDF5 files and appears
similar to JSON.  The mode currently enables `hs-minor-mode' for braced
blocks and basic font locking of non-data tokens.

h5dump output is not useful for data transfer but rather as a summary of
the group hierarchy within a given HDF5 file, along with a programming
language-independent way of inspecting the raw contents of datasets.  When
datasets get large, understanding the hierarchy while still viewing some
data can be difficult, so hideshow can be used to selectively hide groups
and datasets.

A future goal is to have tree-sitter integration
(https://github.com/berquist/tree-sitter-h5dump) for complete font locking.
