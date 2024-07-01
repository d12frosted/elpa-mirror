`mowie' let's you define smart commands that cycle through the
result of point-moving commands by consecutive repetitions.  The
package also offers a few point-moving commands.

While repeating the command that you defined using `mowie', it will
skip those point-moving commands that do not provide a point which
has not been visited in the running repetition so far.  In a
similar manner, it currently also avoids the point as it was right
before the repetition started.

`mowie' strives to be minimalistic rather than being generalizable.
If you want something different, consider copying and modifying the
code to your liking, or using an alternative package.
