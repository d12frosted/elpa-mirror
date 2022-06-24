Provides a transient for Rust's cargo.

Usage:
M-x cargo-transient

Supported cargo commands:
- build
- check
- clean
- clippy
- doc
- fmt
- run
- test

Not all commands and arguments are supported. If cargo-transient is
missing support for something you need, please open a pull request
or file an issue at
<https://github.com/peterstuart/cargo-transient/>.

By default, all commands will share the same compilation buffer,
but that can be changed by customizing
`cargo-transient-compilation-buffer-name-function'.

See the info node `(transient)Top' for information on using
transients.
