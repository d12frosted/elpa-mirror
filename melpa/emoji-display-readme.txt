Emacs 23 or later is required.
Get emoji images from FireMobileSimulator or EmojiPrint.
  FireMobileSimulator http://firemobilesimulator.org/
  EmojiPrint          http://www.takaaki.info/addon/emojiprint/

1. Place .el files to a loadable directory, and byte-compile as needed.
2. Set emoji-display-image-directory variable appropriately or place
image directory to the same directory of .el files.
3. Add your ~/.emacs as below code.

(require 'emoji-display)
(emoji-display-mode)

Known problems
* Resources are exhausted on MS Windows.
* Some animated images are corrupted.
