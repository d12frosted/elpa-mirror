testcover-audit adds quantitative coverage statistics to Emacs'
built-in testcover.el.  It shows coverage percentage, counts of
covered, uncovered and 1value forms, and can generate per-function
and per-file reports.

The package provides the following user-facing commands:

  testcover-audit-show-stats
    Display a brief coverage summary in the echo area.

  testcover-audit-show-all-stats
    Open a detailed report buffer with color-coded overall and
    function-level statistics for the current file.
    In the report, RET on a function row opens that function's stats.

  testcover-audit-show-function-stats
    Show per-function coverage, including line-level breakdown when
    Edebug position data is available.

  testcover-audit-batch-report
    Show an aggregate table for all instrumented files, with
    per-file and low-coverage function breakdown.
    RET on a file row opens its stats; RET on a function row opens
    that function's stats.

Report buffers support j/n (down) and k/p (up) for row navigation.

  testcover-audit-scan-directory
    Collect coverage from instrumented definitions in open source buffers.

  testcover-audit-project-report
    Collect coverage from instrumented definitions in the current project.

  testcover-audit-export-org
    Export a report in Org syntax.

  testcover-audit-export-json
    Export a machine-readable JSON report.

  testcover-audit-ci-check
    Return a non-zero exit status when coverage is below a threshold.

Enable testcover-audit-mode to display the current buffer's coverage
percentage in the mode line.  Enable testcover-audit-ert-mode to
automatically generate a report after each ERT test run.

Command groups:
  - Daily use: testcover-audit-show-stats, show-all-stats,
    show-function-stats, batch-report, project-report, scan-directory
  - Export/CI: testcover-audit-export-org, export-json, ci-check
  - Tooling: testcover-audit-instrument-directory

The number of commands is manageable because each group has a clear
purpose.  For daily work, `testcover-audit-project-report' and the
`show-*' series are sufficient.

All user-facing configuration is grouped under `testcover-audit'.

The batch test runner and its module-reload helper are provided by
`testcover-audit-test.el' (see `testcover-audit-test-run').
