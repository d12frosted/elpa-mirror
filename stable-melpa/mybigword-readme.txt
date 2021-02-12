This program extract big words from text.
The words whose Zipf frequency less than `mybigword-upper-limit' are
big words.

Zipf scale was proposed by Marc Brysbaert, who created the SUBTLEX lists.
Zipf frequency of a word is the base-10 logarithm of the number of times it
appears per billion words.

A word with Zipf value 6 appears once per thousand words,for example, and a
word with Zipf value 3 appears once per million words.

Reasonable Zipf values are between 0 and 8, but the minimum Zipf value
appearing here is 1.0.

We use 0 as the default Zipf value for words that do not appear in the given
word list,although it should mean one occurrence per billion words."

Thanks to https://github.com/LuminosoInsight/wordfreq for providing the data.

Usage,

  Run `mybigword-show-big-words-from-file'
  Run `mybigword-show-big-words-from-current-buffer'


Customize `mybigword-excluded-words' or `mybigword-personal-excluded-words' to
exclude words.

Tips,

  1. Customize `mybigword-default-format-function' to format the word for display.
  If it's `mybigword-format-with-dictionary', the `dictionary-definition' is used to
  find the definitions of all big words.

  Sample to display the dictionary definitions of big words:

    (let* ((mybigword-default-format-function 'mybigword-format-with-dictionary))
      (mybigword-show-big-words-from-current-buffer))

  You can also set `mybigword-default-format-header-function' to add a header before
  displaying words.

  Customize `mybigword-hide-word-function' to hide word for display


  2. Parse the *.srt to play the video containing the word in org file
  Make sure the org tree node has the property SRT_PATH.
  Mplayer is required to play the video.  See `mybigword-mplayer-program' for details.

  Sample of org file:
   * Star Trek s06e26
     :PROPERTIES:
     :SRT_PATH: ~/Star.Trek.DS9-s06e26.Tears.of.the.Prophets.srt
     :END:
   telepathic egotist

  Move focus over the word like "egotist".  Run "M-x mybigword-play-video-of-word-at-point".
  Then mplayer plays the corresponding video at the time the word is spoken.
  If video is missing, the mp3 with similar name is played.
  See `mybigword-video2mp3' on how to generate mp3 from video files.

  Please note `mybigword-play-video-of-word-at-point' can be used in other major modes.
  See `mybigword-default-media-info-function' for details.


  3. Use `mybigword-pronounce-word' to pronounce the word at point.
  The word's audio is downloaded from https://dictionary.cambridge.org
  The audio download url could be customized in `mybigword-default-audio-url-function'.

  4. Use `mybigword-show-image-of-word' to show images of the word at point
  in external browser.  Please note `browse-url-generic' is used in this
  command.
