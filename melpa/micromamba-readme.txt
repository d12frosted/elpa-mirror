mamba is a reimplementation of the conda package manager in C++.
mamba is notably much faster and essentially compatible with conda,
so it also works with conda.el.  micromamba, however, implements
only a subset of mamba commands, and as such requires a separate
integration.

The package has two entrypoints:
- `micromamba-activate' - activate the environment
- `micromamba-deactivate' - deactivate the environment

Also see the README at
<https://github.com/SqrtMinusOne/micromamba.el> for more
information.
