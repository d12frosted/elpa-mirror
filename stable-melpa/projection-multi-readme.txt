Helpers for calling `compile-multi' with project specific targets.

This library exposes a command `projection-multi-compile' which invokes
`compile-multi' with a project specific compilation targets. This includes
targets for available commands for the current project type (configure,
compile, etc. See `projection-commands') and also for build frameworks
included in the current project. For example `projection-multi-compile'
will include tox targets when the project matches the tox project type.
This latter feature works independently of the main project type associated
with the current project. A project matching both tox and CMake will
offer both tox and CMake targets with `projection-multi-compile'.
