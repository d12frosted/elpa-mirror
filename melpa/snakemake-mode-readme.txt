Snakemake mode provides support for editing Snakemake [1] files.  It
builds on Python mode to provide fontification, indentation, and
imenu indexing for Snakemake's rule blocks.

See also snakemake.el, which is packaged with snakemake-mode.el and
provides an interface for running Snakemake commands.

If Snakemake mode is installed from MELPA, no additional setup is
required.  It will be loaded the first time a file named 'Snakefile'
is opened.

Otherwise, put snakemake-mode.el in your `load-path' and add

    (require 'snakemake-mode)

to your initialization file.

snakemake-mode.el also includes support for highlighting embedded R
code.  See the snakemake-mode-setup-mmm function documentation for how.

[1] https://snakemake.github.io/
