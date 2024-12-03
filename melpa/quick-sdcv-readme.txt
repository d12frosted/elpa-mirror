The quick-sdcv package serves as a lightweight Emacs interface for the
sdcv command-line interface, which is the console version of the StarDict
dictionary application.

This package enables Emacs to function as an offline dictionary.

This integration allows users to access and utilize sdcv dictionary
functionalities directly within the Emacs environment, leveraging the
capabilities of sdcv to look up words and translations from various
dictionary files formatted for StarDict.

Here are the main interactive functions:

Below are the commands you can use:
- `quick-sdcv-search-at-point': Searches the word around the cursor and
  displays the result in a buffer.
- `quick-sdcv-search-input': Searches the input word and displays the result
  in a buffer.

Installation from MELPA:
------------------------
(use-package quick-sdcv
  :ensure t
  :straight (quick-sdcv
             :type git
             :host github
             :repo "jamescherti/quick-sdcv.el")
  :custom
  (quick-sdcv-dictionary-prefix-symbol "►")
  (quick-sdcv-ellipsis " ▼ "))

Usage:
------
To retrieve the word under the cursor and display its definition in a buffer:
  (quick-sdcv-search-at-point)

To prompt the user for a word and display its definition in a buffer:
  (quick-sdcv-search-input)

Links:
------
More information about quick-sdcv (Usage, Frequently Asked Questions, etc.):
https://github.com/jamescherti/quick-sdcv.el
