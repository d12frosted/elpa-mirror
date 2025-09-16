python-tdd-mode provides a modern, intuitive, and responsive minor mode for
test-driven development in Python projects using Emacs.

It supports various test runners (e.g. pytest, nosetests, Django),
provides interactive commands to run tests at point, rerun last tests,
display output in a dedicated buffer, and highlight the Emacs mode-line
based on test results using dynamic fading effects.

Features:
- Run tests for current function, class, file, or project
- Configurable test runners: pytest, Django, nosetests
- Automatic test reruns on file save
- Alerts for pass/fail (with optional integration with "alert")
- Mode-line blinking with color fade feedback
- Interactive command map for test operations
- Copy test command or output to clipboard
- Intelligent test discovery using Python syntax
- Rich customization options via Emacs Customize

Usage:
Enable python-tdd-mode in a Python buffer or globally with:

   (add-hook 'python-mode-hook #'python-tdd-mode)

Bind "python-tdd-mode-command-map" to a convenient keybinding:
   (global-set-key (kbd "C-c C-t") python-tdd-mode-command-map)

Note: Removed all backticks to resolve melpazoid warnings.

See the GitHub repository for documentation, issues, and contributions.
