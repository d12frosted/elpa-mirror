A mode that gives you focus in achieving your writing goals.

This mode allows you to set a writing goal and achieve it. The main
feature is to let you define a number of words and the mode
periodically prizes your efforts by printing encouragement messages
in the console. The messages shows only when your cursor is in the
buffer in which you set a writing goal. This mode also allows you
to set multiple goals in different buffers, although it is not
advised because distracting.

The aim of this mode is to give a structure in your writing. The
idea is to write everyday N (ideally 1k) words. The next day you
should edit what you wrote, and write some more.

This mode also provides editing utilities. `wwg-editing-mode' lets
you set a goal for your editing session. Once this start, `wwg'
will encourage your editing progress as `wwg-mode' does. It will
also show the parts of your text that are less readable.

Furthermore, you can see how readable your text is while you are
writing: just use `wwg-score-sentences-mode' and
`wwg-score-paragraphs-mode' according to the granularity you need.

Other utilities provide similar functionality:
- count-words: Emacs built-in to count the words in the buffer
- org-wc: this counts words in Org-Mode buffers
- wc-goal-mode and wc-mode: these keep track of how many words you wrote in the modeline

This mode differs from the above because encourages you
periodically to not surrender your writing dreams.

See documentation on https://github.com/ag91/writer-word-goals
