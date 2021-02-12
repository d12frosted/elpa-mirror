A **minimalists'** Emacs extension to search http://www.bing.com/dict.
Support English to Chinese and Chinese to English.

极简主义者的 Emacs 必应词典。 支持中英互译。

## Setup

You can install via [melpa](http://melpa.org).

If installing this package manually:

    (add-to-list 'load-path "/path/to/bing-dict.el")
    (require 'bing-dict)

## Usage
You can call `bing-dict-brief` to get the explanations of you query. The results
will be shown in the echo area.

Here is the screenshot:

![bing-dict-screenshot1](./screenshot1.png)

You should probably give this command a key binding:

    (global-set-key (kbd "C-c d") 'bing-dict-brief)

## Customization
You can set the value of `bing-dict-add-to-kill-ring` to control whether the
result should be added to the `kill-ring` or not. By default, the value is
`nil`. If set to `t`, the result will be added to the `kill-ring` and you are
able to use `C-y` to paste the result.

Also, sometimes synonyms and antonyms could be useful, set
`bing-dict-show-thesaurus` to control whether you need them or not. The value of
`bing-dict-show-thesaurus` could be either `nil`, `'synonym`, `'antonym` or
`'both`. The default value is `nil`. Setting the vaule to `'synonym` or
`'antonym` only shows the corresponding part, and setting it to `'both` will
show both synonyms and antonyms at the same time:

    (setq bing-dict-show-thesaurus 'both)

The variable `bing-dict-pronunciation-style` controls how the pronunciation is
shown. By default, its value is `'us` and the pronunciation is shown using
"American Phonetic Alphabet" (APA). You can choose the "International Phonetic
Alphabet" (IPA) by setting its value to `'uk` (In fact, any value other than
`'us` will work):

    (setq bing-dict-pronunciation-style 'uk)

You can also build your own vocabulary by saving all your queries and their
results into `bing-dict-vocabulary-save` (which points to
                                                `~/.emacs.d/var/bing-dict/vocabulary.org` by default):

(setq bing-dict-vocabulary-save t)

By setting `bing-dict-vocabulary-file`, you can change where all the queries and
results are saved:

(setq bing-dict-vocabulary-file "/path/to/your_vocabulary.org")

screenshot:

![bing-dict-screenshot2](./screenshot2.png)

Use the following configuration if you want bing-dict.el to cache all your
queries and results:

(setq bing-dict-cache-auto-save t)

You can customize the value of `bing-dict-cache-file` to change the location
where bing-dict.el stores the cache. The default value is
`~/.emacs.d/var/bing-dict/bing-dict-save.el`.


## Command Line Usage

Add the following script to your `PATH` to look up a word from the command line:

```
#!/path/to/emacs --script
(add-to-list 'load-path "/path/to/bing-dict.el")
(require 'bing-dict)
(defun main ()
  (bing-dict-brief (format "%s" command-line-args-left) t))
(main)
```

## For Features Requests
This extension aims for a quick search for a word. Currently this extension only
parses several sections in the search results and show a brief message in the
echo area using `bing-dict-brief`. I don't plan to write parsers for all the
sections of the search results. At least, for `bing-dict-brief`, it should not
present too much information which may not fit into the echo area.

If you want to view the complete results of your query word, there are two
options: using the external browser to do this or contributing to the repo by
adding more parsers. For the first option, the following code could partly
achieve the goal:

    (browse-url
     (concat "http://www.bing.com/dict/search?mkt=zh-cn&q="
           (url-hexify-string
            (read-string "Query: "))))

If you prefer to browse inside Emacs, use `eww` instead:

```
(eww-browse-url
  (concat "http://www.bing.com/dict/search?mkt=zh-cn&q="
          (url-hexify-string
           (read-string "Query: "))))
```

Or open the web page in other window:

```
(switch-to-buffer-other-window
 (eww-browse-url
  (concat "http://www.bing.com/dict/search?mkt=zh-cn&q="
          (url-hexify-string
           (read-string "Query: ")))))
```

For the second option, you're welcome to contribute to this extension by adding
more parsers. For example, you could try to add a parser for the "Sample
Sentences" section. If you're able to write parsers to parse many sections,
which turns out to be too large to be shown in the echo area, you should
probably define a new command, maybe called `bing-dict-complete`. I'm totally OK
with new commands that could present more results, as long as `bing-dict-brief`
remains its original simplicity.
