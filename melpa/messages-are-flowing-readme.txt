If you're writing emails to people who might not view them on a
display with the same width as yours, you probably want to send the
messages as "flowed" (as per RFC 2646) in order to let the
recipient's device disregard the line breaks in your message and
rewrap the text for readability.  In `message-mode', you can do
that by turning on the `use-hard-newlines' minor mode.

However, you probably want some of your newlines to stay put, for
paragraph breaks, and for content where you really do want to break
the lines yourself.  You can do that with `use-hard-newlines', but
it doesn't show you where it's going to put "hard" newlines and
where it's going to put "soft" ones.

That's where `messages-are-flowing' comes in.  It marks all "hard"
newlines with a `⏎' symbol, so that you can have an idea about what
parts of your message might be reflowed when the recipient reads it.

To activate `messages-are-flowing', add the following to your .emacs:

(with-eval-after-load "message"
  (add-hook 'message-mode-hook 'messages-are-flowing-use-and-mark-hard-newlines))
