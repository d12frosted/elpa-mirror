The below is generated from a README at
https://github.com/cosmicexplorer/helm-rg.

MELPA: https://melpa.org/#/helm-rg

!`helm-rg' example usage (./emacs-helm-rg.png)

Search massive codebases extremely fast, using `ripgrep'
(https://github.com/BurntSushi/ripgrep) and `helm'
(https://github.com/emacs-helm/helm). Inspired by `helm-ag'
(https://github.com/syohex/emacs-helm-ag) and `f3'
(https://github.com/cosmicexplorer/f3).

Also check out rg.el (https://github.com/dajva/rg.el), which I haven't used
much but seems pretty cool.


Usage:

*See the `ripgrep' whirlwind tour
(https://github.com/BurntSushi/ripgrep#whirlwind-tour) for further
information on invoking `ripgrep'.*

- Invoke the interactive function `helm-rg' to start a search with `ripgrep'
in the current directory.
    - `helm' is used to browse the results and update the output as you
type.
    - Each line has the file path, the line number, and the column number of
the start of the match, and each part is highlighted differently.
    - Use `TAB' to invoke the helm persistent action, which previews the
result and highlights the matched text in the preview.
    - Use `RET' to visit the file containing the result, move point to the
start of the match, and recenter.
        - The result's buffer is displayed with
`helm-rg-display-buffer-normal-method' (which defaults to
`switch-to-buffer').
        - Use a prefix argument (`C-u RET') to open the buffer with
`helm-rg-display-buffer-alternate-method' (which defaults to
`pop-to-buffer').
- The text entered into the minibuffer is interpreted into a PCRE
(https://pcre.org) regexp to pass to `ripgrep'.
    - `helm-rg''s pattern syntax is basically PCRE, but single spaces
basically act as a more powerful conjunction operator.
        - For example, the pattern `a b' in the minibuffer is transformed
into `a.*b|b.*a'.
            - The single space can be used to find lines with any
permutation of the regexps on either side of the space.
            - Two spaces in a row will search for a literal single space.
        - `ripgrep''s `--smart-case' option is used so that case-sensitive
search is only on if any of the characters in the pattern are capitalized.
            - For example, `ab' (conceptually) searches `[Aa][bB]', but `Ab'
in the minibuffer will only search for the pattern `Ab' with `ripgrep',
because it has at least one uppercase letter.
- Use `M-d' to select a new directory to search from.
- Use `M-g' to input a glob pattern to filter files by, e.g. `*.py'.
    - The glob pattern defaults to the value of
`helm-rg-default-glob-string', which is an empty string (matches every file)
unless you customize it.
    - Pressing `M-g' again shows the same minibuffer prompt for the glob
pattern, with the string that was previously input.
- Use `<left>' and `<right>' to go up and down by files in the results.
    - `<up>' and `<down>' simply go up and down by match result, and there
may be many matches for your pattern in a single file, even multiple on a
single line (which `ripgrep' reports as multiple separate results).
    - The `<left>' and `<right>' keys will move up or down until it lands on
a result from a different file than it started on.
        - When moving by file, `helm-rg' will cycle around the results list,
but it will print a harmless error message instead of looping infinitely if
all results are from the same file.
- Use the interactive autoloaded function `helm-rg-display-help' to see the
ripgrep command's usage info.


TODO:

*items checked completed here are ready to be added to the docs above*

- [x] make a keybinding to drop into an "edit mode" and edit file content
inline in results like `helm-ag' (https://github.com/syohex/emacs-helm-ag)
    - *currently called "bounce mode"* in the alpha stage
    - [x] needs to dedup results from the same line
        - [x] should also merge the colorations
        - [x] this might be easier without using the `--vimgrep' flag (!!!)
    - [x] can insert markers on either side of each line to find the text
added or removed
    - [x] can change the filename by editing the file line
        - [x] needs to reset all the file data for each entry if the file
name is being changed!!!
    - [x] can expand the windows of text beyond single lines at a time
        - using `helm-rg--expand-match-context' and/or
`helm-rg--spread-match-context'
        - [x] and pop into another buffer for a quick view if you want
          - can use `helm-rg--visit-current-file-for-bounce'
        - [ ] can expand up and down from file header lines to add lines
from the top or bottom of the file!
        - [ ] can use newlines in inserted text
            - not for file names -- newlines are still removed there
            - would need to use text properties to move by match results
then, for everything that uses `helm-rg--apply-matches-with-file-for-bounce'
basically
    - [x] visiting the file should go to the appropriate line of the file!
- [x] color all results in the file in the async action!
    - [x] don't recolor when switching to a different result in the same
file!
    - [x] don't color matches whenever file path matches
`helm-rg-shallow-highlight-files-regexp'
- [ ] use `ripgrep' file types instead of flattening globbing out into
`helm-rg-default-glob-string'
    - user defines file types in a `defcustom', and can interactively toggle
the accepted file types
    - user can also set the default set of file types
        - as a dir-local variable!!
- [ ] add testing
  - [ ] should be testing all of our interactive functions
      - in all configurations (for all permutations of `defcustom' values)
  - [ ] also everything that's called by helm
      - does helm have any frameworks to make integration testing easier?
- [ ] publish `update-commentary.el' and the associated machinery
    - as an npm package, MELPA package, pandoc writer, *???*
- [ ] make a keybinding for running `helm-rg' on dired marked files
    - then you could do an `f3' search, bounce to dired, then immediately
`helm-rg' on just the file paths from the `f3' search, *which would be
sick*


License:

GPL 3.0+ (./LICENSE)

End Commentary
