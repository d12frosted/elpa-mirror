`company-wordfreq' is a company backend intended for writing texts in a human
language.  The completions it proposes are words already used in the current
(or another open) buffer and matching words from a word list file.  This
word list file is supposed to be a simple list of words ordered by the
frequency the words are used in the language.  So the first completions are
words already used in the buffer followed by matching words of the language
ordered by frequency.

`company-wordfreq' does not come with the word list files directly, but it
can download the files for you for many languages from
<https://github.com/hermitdave/FrequencyWords>.  I made a fork of that repo
just in case the original changes all over sudden without my noticing.

The directory where the word list files reside is determined by the variable
`company-wordfreq-path', default `~/.emacs.d/wordfreq-dicts'.  Their
names must follow the pattern `<language>.txt' where language is the
`ispell-local-dictionary' value of the current language.

You need =grep= in your =$PATH= as =company-wordfreq= uses it to grep into
the word list files.  Should be the case by default on any UNIX like
systems.  On windows you might have to tweak it somehow.

`company-wordfreq' is supposed to be the one and only company backend and
`company-mode' should not transform or sort its candidates.  This can be
achieved by setting the variables `company-backends' and
`company-transformers' buffer locally in `text-mode' buffers by

    (add-hook 'text-mode-hook (lambda ()
                             (setq-local company-backends '(company-wordfreq))
                             (setq-local company-transformers nil)))

Usually you don't need to configure the language picked to get the word
completions.  `company-wordfreq' uses the variable
`ispell-local-dictionary'.  It should work dynamically even if you use
`auto-dictionary-mode'.


To download a word list use

    M-x company-wordfreq-download-list

You are presented a list of languages to choose.  For some languages the
word lists are huge, which can lead to noticeable latency when the
completions are build.  Therefore you are asked if you want to use a word
list with only the 50k most frequent words.  The file will then be
downloaded, processed and put in place.
