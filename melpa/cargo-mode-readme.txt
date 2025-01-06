Add a hook to the mode that you're using with Rust, for example, `rust-mode`:

(add-hook 'rust-mode-hook 'cargo-minor-mode)


; C-c a e - `cargo-execute-task` - List all available tasks and execute one of them.  As a bonus, you'll get a documentation string because `cargo-mode.el` parses shell output of `cargo --list` directly.
; C-c a t - `cargo-mode-test` - Run all tests in the project (`cargo test`).
; C-c a l - `cargo-mode-last-command` - Execute the last executed command.
; C-c a b - `cargo-mode-build` - Build the project (`cargo build`).
; C-c a o - `cargo-mode-test-current-buffer` - Run all tests in the current buffer.
; C-c a f - `cargo-mode-test-current-test` - Run the current test where pointer is located.
; C-c a c - `cargo-mode-clippy` - Run Clippy in the project (`cargo clippy`).
;
; Use `C-u` to add extra command line params before executing a command.
