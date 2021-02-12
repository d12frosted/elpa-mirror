`easy-repeat' enables you to easily repeat the previous command by using the
last short key, for example, 'C-x o' 'o' 'o' 'o'...  will switch windows
and 'M-x next-buffer RET' 'RET' 'RET' 'RET'... will switch buffers.

## Setup

    (add-to-list 'load-path "/path/to/easy-repeat.el")
    (require 'easy-repeat)

## Usage
Modify `easy-repeat-command-list' to choose which commands you want to repeat
easily.

To use: M-x easy-repeat-mode RET

## TODO
- [ ] Set up a timer to free repeat key
- [x] Allow shorter key, e.g., use single 'a' to repeat 'C-M-a'
