This package provides support for the Bazel build system.  See
https://bazel.build/ for background on Bazel.

The package provides four major modes for editing Bazel-related files:
‘bazel-build-mode’ for BUILD files, ‘bazel-workspace-mode’ for WORKSPACE
files, ‘bazelrc-mode’ for .bazelrc configuration files, and
‘bazel-starlark-mode’ for extension files written in the Starlark language.
These modes also extend Imenu and ‘find-file-at-point’ to support
Bazel-specific syntax.

If Buildifier is available, the ‘bazel-mode-flymake’ backend for Flymake
provides on-the-fly syntax checking for Bazel files.  You can also run
Buildifier manually using the ‘bazel-buildifier’ command to reformat a Bazel
file buffer.

The Bazel modes integrate with Xref to provide basic functionality to jump to
the definition of Bazel targets.

To simplify running Bazel commands, the package provides the commands
‘bazel-build’, ‘bazel-test’, ‘bazel-coverage’ and ‘bazel-run’, which execute
the corresponding Bazel commands in a compilation mode buffer.  In a buffer
that visits a test file, you can also have Emacs try to detect and execute
the test at point using ‘bazel-test-at-point’.

When editing a WORKSPACE file, you can use the command
‘bazel-insert-http-archive’ to quickly insert an http_archive rule.

You can customize some aspects of this package using the ‘bazel’
customization group.  If you set the user option ‘bazel-display-coverage’ to
a non-nil value and then run ‘bazel coverage’ (either using the ‘compile’ or
‘bazel-coverage’ command), the package will display code coverage status in
buffers that visit instrumented files, using the faces ‘bazel-covered-line’
and ‘bazel-uncovered-line’ for covered and uncovered lines, respectively.
