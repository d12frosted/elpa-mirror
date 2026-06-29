# Ruby end [![Build Status](https://travis-ci.org/rejeep/ruby-end.el.svg?branch=master)](https://travis-ci.org/rejeep/ruby-end.el)

Ruby end is a minor mode for Emacs that can be used with `ruby-mode`
to automatically close blocks by inserting `end` when typing a "block
keyword", followed by a space.

[<img src="http://img.youtube.com/vi/00O_8gTFe-k/0.jpg">](https://www.youtube.com/watch?v=00O_8gTFe-k)

## Installation
I recommend installing via ELPA, but manual installation is simple as well:

    (add-to-list 'load-path "/path/to/ruby-end")
    (require 'ruby-end)

## Usage
When `ruby-mode` is started, `ruby-end-mode` will automatically start.

In a Ruby file, try writing a block keyword, such as `class` or `def`
and then `SPC`.

For more information, see comments in `ruby-end.el`.

## Contribution
Contribution is much welcome! Ruby end is tested using [Ecukes](https://github.com/ecukes/ecukes). When
adding new features, please write tests for them!

Install [cask](https://github.com/rejeep/cask.el) if you haven't
already, then:

    $ cd /path/to/ruby-end
    $ cask

Run all tests with:

    $ make
