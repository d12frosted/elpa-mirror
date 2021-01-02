Lately there has been some interest in writing with only the ten
hundred most used English words.  Even the news has talked about one
thing that makes your computer take away words that aren't in the
ten hundred most used.

(Mostly the news talked about that thing because the person who
wrote it did so in part to make a point about someone called Donald
Trump, not because the thing was interesting in its own right.  But
that's okay, because the people who write the news need something
to do all day just like everyone else.)

Someone on Hacker News asked if there was a thing like that for
Emacs.  There is, sort of, but it's old and not easy to find, and it
doesn't work very well.  So I thought I'd write a new one that
everyone can find and use.  This is that thing.

It knows the ten hundred most used words, and when you type a word,
it checks to see if your word is one of them.  If not, the computer
takes away the word you typed, and suggests some words like the one
it took away but which are okay to use.  (This last part can be a
little slow, and it isn't always very helpful, so you can turn it
off if you want.) Words that start with a big letter, like names,
don't get taken away, even if they would be normally.

This thing doesn't know very much.  If you aren't typing normally,
it probably will let you get away with using words you aren't
supposed to use.  That's not nice, though, so don't do that.

; Contributing:

If you think of a way this thing can do a better job of taking away
words that aren't okay to use, let me know, or (even better) add it
to the thing and then let me know.

Here's where this thing lives:
https://github.com/aaron-em/ten-hundred-mode.el

I hope you like it!
