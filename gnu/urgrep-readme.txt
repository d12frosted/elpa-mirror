# Urgrep - Universal Recursive Grep

[![GNU ELPA version][elpa-image]][elpa-link]

**Urgrep** is an Emacs package to provide a universal frontend for *any*
grep-like tool, as an alternative to the built-in `M-x rgrep` (and other similar
packages). Currently, [`ugrep`][ugrep], [`ripgrep`][ripgrep], [`ag`][ag],
[`ack`][ack], [`git grep`][git-grep], and [`grep`][grep]/[`find`][find] are
supported.

## Why Urgrep?

#### One package, many tools

No matter which tool you prefer, you can use it with Urgrep. If a new tool comes
along, you won't need to find a new Emacs package for it.

#### Rich minibuffer interface

Easily manipulate per-search options with Isearch-like key bindings within the
Urgrep minibuffer prompt.

#### Seamless support for Tramp

Each host can use a different set of tools depending on what the system has
installed without any special configuration.

## Using Urgrep

The primary entry point to Urgrep is the interactive function `urgrep`. This
prompts you for a query to search for in, by default, the root directory of the
current project (or the `default-directory` if there is no project). By
prefixing with <kbd>C-u</kbd>, this will always start the search within the
`default-directory`. With <kbd>C-u</kbd> <kbd>C-u</kbd>, Urgrep will first
prompt you for the search directory. Within the search prompt, there are several
Isearch-like key bindings to let you modify the search's behavior:

| Key binding                 | Action                                   |
|:----------------------------|:-----------------------------------------|
| <kbd>M-s</kbd> <kbd>h</kbd> | Describe key bindings                    |
| <kbd>M-s</kbd> <kbd>r</kbd> | Toggle regexp search                     |
| <kbd>M-s</kbd> <kbd>c</kbd> | Toggle case folding                      |
| <kbd>M-s</kbd> <kbd>H</kbd> | Toggle searching in hidden files         |
| <kbd>M-s</kbd> <kbd>f</kbd> | Set wildcards to filter files¹           |
| <kbd>M-s</kbd> <kbd>C</kbd> | Set number of lines of context²          |
| <kbd>M-s</kbd> <kbd>B</kbd> | Set number of lines of leading context²  |
| <kbd>M-s</kbd> <kbd>A</kbd> | Set number of lines of trailing context² |
| <kbd>M-s</kbd> <kbd>t</kbd> | Set the search tool                      |

> 1. Prompts with a recursive minibuffer<br>
> 2. With a numeric prefix argument, set immediately; otherwise, use a recursive
>    minibuffer

In addition to the above, you can call `urgrep-run-command`, which works like
`urgrep` but allows you to manually edit the command before executing it.

### Modifying your search

After performing a search, you can adjust an existing query with <kbd>C-u</kbd>
<kbd>g</kbd>, reopening the original search prompt. You can also adjust some of
the search options, such as case folding, immediately:

| Key binding  | Action                            |
|:-------------|:----------------------------------|
| <kbd>c</kbd> | Toggle case folding               |
| <kbd>H</kbd> | Toggle searching in hidden files  |
| <kbd>C</kbd> | Expand lines of context¹          |
| <kbd>B</kbd> | Expand lines of leading context¹  |
| <kbd>A</kbd> | Expand lines of trailing context¹ |

> 1. Expand by one line by default, or by *N* lines with a prefix argument

### Configuring the tool to use

By default, Urgrep tries all search tools it's aware of to find the best option.
To improve performance, you can restrict the set of tools to search for by
setting `urgrep-preferred-tools`:

```elisp
(setq urgrep-preferred-tools '(git-grep grep))
```

If a tool is installed in an unusual place on your system, you can specify this
by providing a cons cell as an element in `urgrep-preferred-tools`:

```elisp
(setq urgrep-preferred-tools '((ag . "/home/coco/bin/ag")))
```

This also works with connection-local variables:

```elisp
(connection-local-set-profile-variables 'urgrep-ripgrep
 '((urgrep-preferred-tools . (ripgrep))))

(connection-local-set-profiles
 '(:application tramp :machine "imagewriter") 'urgrep-ripgrep)
```

### Using with wgrep

[wgrep][wgrep] provides a convenient way to edit results in grep-like buffers.
Urgrep can hook into wgrep to support this as well. To enable this, just load
`urgrep-wgrep.el`.

### Using with Xref

[Xref][xref] lets you search through your projects to find strings, identifiers
etc. You can make Xref use Urgrep to generate its search command by loading
`urgrep-xref.el`.

### Using with `outline-minor-mode`

Inside of Urgrep buffers, you can enable `outline-minor-mode`. This will let you
toggle the visibility of each file's results.

### Using with Eshell

In Eshell buffers, you can call `urgrep` much like you'd call any command-line
recursive grep command. The following options are supported:

| Option                      | Action                                      |
|:----------------------------|:--------------------------------------------|
| `-G`, `--basic-regexp`      | Pattern is a basic regexp                   |
| `-E`, `--extended-regexp`   | Pattern is an extended regexp               |
| `-P`, `--perl-regexp`       | Pattern is a Perl-compatible regexp         |
| `-R`, `--default-regexp`    | Pattern is a regexp with the default syntax |
| `-F`, `--fixed-strings`     | Pattern is a string                         |
| `-s`, `--case-sensitive`    | Search case-sensitively                     |
| `-i`, `--ignore-case`       | Search case-insensitively                   |
| `-S`, `--smart-case`        | Ignore case if pattern is all lower-case    |
| `--group` / `--no-group`    | Enable/disable grouping results by file     |
| `--hidden` / `--no-hidden`  | Enable/disable searching hidden files       |
| `-Cn`, `--context=n`        | Show *n* lines of context                   |
| `-Bn`, `--before-context=n` | Show *n* lines of leading context           |
| `-An`, `--after-context=n`  | Show *n* lines of trailing context          |

## Programmatic interface

In addition to interactive use, Urgrep is designed to allow for programmatic
use, returning a command to execute with the specified query and options:
`urgrep-command`. This takes a `query` as well as several optional keyword
arguments. For more information, consult the docstring for `urgrep-command`.

## Contributing

This project [assigns copyright][fsf-copyright] to the Free Software Foundation,
so if you'd like to contribute code, please make sure you've filled out the
assignment form and that it's up to date. In any case, before submitting
patches, it's probably best to [file an issue][new-issue] first so that we
can discuss the best way to do things.

[elpa-image]: https://elpa.gnu.org/packages/urgrep.svg
[elpa-link]: https://elpa.gnu.org/packages/urgrep.html
[ugrep]: https://github.com/Genivia/ugrep
[ripgrep]: https://github.com/BurntSushi/ripgrep
[ag]: https://github.com/ggreer/the_silver_searcher
[ack]: https://beyondgrep.com/
[git-grep]: https://git-scm.com/docs/git-grep
[grep]: https://www.gnu.org/software/grep/
[find]: https://www.gnu.org/software/findutils/
[wgrep]: https://github.com/mhayashi1120/Emacs-wgrep
[xref]: https://www.gnu.org/software/emacs/manual/html_node/emacs/Xref.html
[fsf-copyright]: https://www.gnu.org/prep/maintain/html_node/Copyright-Papers.html
[new-issue]: https://github.com/jimporter/urgrep/issues/new
