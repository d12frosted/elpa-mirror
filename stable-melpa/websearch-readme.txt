Query search engines from Emacs.

The websearch package allows You to query predefined search engines
(‘websearch-custom-engines’) with interactive selection.
The query terms can either be extracted form selection, kill-ring
or typed on demand.

The `websearch' function is a interactive entry-point to select both
the terms extraction method and search engine provider.

To turn on the global mode enabling a custom key map,
activate `websearch-mode'.

‘websearch’ is inspired by ‘engine-mode’
(https://github.com/hrs/engine-mode), but the differences are big enough
for it to be it's own package.

The full set of commands you can try is:
* websearch-mode
* websearch
* websearch-browse-with
* websearch-kill-ring
* websearch-list-engines
* websearch-point
* websearch-region
* websearch-term

For more information and screenshots, see:
https://gitlab.com/xgqt/emacs-websearch/
