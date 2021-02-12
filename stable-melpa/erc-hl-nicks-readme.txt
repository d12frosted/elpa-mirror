This file was originally erc-highlight-nicknames.  It was modified
to optionally ignore the uniquifying characters that IRC clients
add to nicknames

History

1.3.4

- Pull request #13 - `erc-hl-nicks-refresh-colors' to refresh faces
  Thanks thblt!

1.3.3

- Pull request #9 - switch from cl to cl-lib
  Thanks jgkamat!

1.3.2

- Pull request #6 - handle when `word-at-point' is nil
  Thanks alezost!

- Pull request #7 - remove the list membership check on autoload
  Thanks albertodonato!

1.3.1

- Fix a require issue

1.3.0 (was uploaded as 1.2.4, accidentally)

- Fix autoloads - erc-hl-nicks should require itself as needed

- reset face table is now interactive

- reworked how colors are chosen (should continue to work the same
  for everyone, though). See `erc-hl-nicks-color-contrast-strategy'
  for details.

- Added `erc-hl-nicks-bg-color' to allow terminal users to specify
  their background colors

- Added `erc-hl-nicks-alias-nick' to allow setting up several nicks
  to use the same color

- Added `erc-hl-nicks-force-nick-face' to force a nick to use a
  specific color

1.2.3 - Updated copyright date

      - Updated some formatting

      - added highlighting on erc-send-modify-hook

1.2.2 - Added dash to the list of characters to ignore

      - Fixed an issue where timestamps could prevent highlighting
        from occurring

1.2.1 - Remove accidental use of 'some' which comes from cl

1.2.0 - Added erc-hl-nicks-skip-nicks to give a way to prevent
        certain nicks from being highlighted.

      - Added erc-hl-nicks-skip-faces to give a way to prevent
        highlighting over other faces.  Defaults to:
        (erc-notice-face erc-fool-face erc-pal-face)

1.1.0 - Remove use of cl package (was using 'reduce').

      - The hook is called with a narrowed buffer, so it makes
        more sense to iterate over each word, one by one.  This
        is more efficient and has a secondary benefit of fixing a
        case issue.

      - Added an option to not highlight fools

1.0.4 - Use erc-channel-users instead of erc-server-users

      - Ignore leading characters, too.

1.0.3 - Was finding but not highlighting nicks with differing
        cases. Fixed. Ignore leading characters, too. Doc changes.

1.0.2 - Fixed a recur issue, prevented another, and fixed a
        spelling issue.

1.0.1 - tweaked so that the re-search will pick up instances of the
        trimmed nick, settled on 'nick' as the variable name
        instead of kw, keyword, word, etc

1.0.0 - initial release
