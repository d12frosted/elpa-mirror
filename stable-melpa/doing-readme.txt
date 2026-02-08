doing.el is an Org-mode based activity log inspired by Brett Terpstra's
"doing" CLI tool.  It provides a frictionless way to capture what you're
working on, with automatic time tracking and reporting.

Key features:
- Fast, low-friction capture of activities
- Automatic time tracking via timestamps
- Time totals and reports
- Context-aware auto-tagging

Quick start:
- M-x doing-now     Start a new activity
- M-x doing-finish  Finish current activity
- M-x doing-current Show what you're doing

Storage model:
- today.org   — entries from today
- week.org    — entries from current week
- archive/    — past weeks (YYYY-WNN.org)
