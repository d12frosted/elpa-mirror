The below is generated from a README at
https://github.com/cosmicexplorer/helm-rg.

Search massive codebases extremely fast, using `ripgrep' and `helm'.
Inspired by `helm-ag' and `f3'.

Also check out rg.el, which I haven't used much but seems pretty cool.


Usage:

*See the `ripgrep' whirlwind tour for further information on invoking
`ripgrep'.*

- Invoke the interactive function `helm-rg' to start a search with `ripgrep'
in the current directory.
    - `helm' is used to browse the results and update the output as you
type.
    - Each line has the file path, the line number, and the column number of
the start of the match, and each part is highlighted differently.
    - Use 'TAB' to invoke the helm persistent action, which previews the
result and highlights the matched text in the preview.
    - Use 'RET' to visit the file containing the result, move point to the
start of the match, and recenter.
- The text entered into the minibuffer is interpreted as a PCRE regexp which
`ripgrep' uses to search your files.
- Use 'M-d' to select a new directory to search from.
- Use 'M-g' to input a glob pattern to filter files by, e.g. `*.py'.
    - The glob pattern defaults to the value of
`helm-rg-default-glob-string', which is an empty string (matches every file)
unless you customize it.
    - Pressing 'M-g' again shows the same minibuffer prompt for the glob
pattern, with the string that was previously input.


TODO:

- make a keybinding to move by files (go to next file of results)
    - also one to move by containing directory
- make a keybinding to drop into an edit mode and edit file content inline
in results like helm-ag


License:

GPL 3.0+

End Commentary
