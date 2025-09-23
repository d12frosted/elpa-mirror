This package provides enhanced Go test running capabilities using tree-sitter
for accurate syntax parsing. It intelligently detects test functions and
subtests at point, allowing you to run specific tests with a single command.

Features:
- Automatic detection of test functions and table-driven subtests
- Tree-sitter powered parsing for reliable syntax understanding
- DWIM (Do What I Mean) test execution
- Support for customizable subtest field names
- Navigation between subtests with next/previous commands
- Imenu integration for quick navigation to any test or subtest

Usage:
Place your cursor on a test function or within a subtest case and run:
M-x gotest-ts-run-dwim

Navigate between subtests:
M-x gotest-ts-next-subtest  ; Go to next subtest
M-x gotest-ts-prev-subtest  ; Go to previous subtest

Quick navigation with imenu:
M-x imenu  ; Shows all tests and subtests in a menu
Or use imenu-list for a sidebar view of all tests

For table-driven tests like:
  func TestExample(t *testing.T) {
      tests := []struct {
          name string
          input int
          want int
      }{
          {name: "case 1", input: 1, want: 2},
          {name: "case 2", input: 2, want: 4},
      }
      // ...
  }

The package will automatically detect if you're on a specific test case
and run only that subtest, or run the entire function if you're elsewhere.

Setup:
(require 'gotest-ts)
(gotest-ts-setup-keybindings)  ; Optional keybindings
(add-hook 'go-ts-mode-hook #'gotest-ts-imenu-setup)  ; Enable imenu
