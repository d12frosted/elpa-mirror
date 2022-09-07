org-unique-id is a utility package for org-mode users that are
tired dealing with random org IDs for their headers’ anchor that
change on each org to HTML exports among others.  This package
creates meaningful custom IDs for org headers that won’t change
unless the user modifies or removes them manually.

In order to be enabled, this package’s `org-unique-id-maybe'
function must be hooked to `before-save-hook', and the string
\\='unique-id:t\\=' must be present in an \\='#+OPTIONS:\\=' line
in the buffer.

If the \\='unique-id:t\\=' string is found, then it will create a
slug of the current header (and if there are, its parent headers)
and it will add a unique string suffix generated with a UUID
generator to ensure all IDs are unique.

Here is an example of an org-mode file without the
\\='unique-id:t\\=' option after save:

    #+title: Test file
    * Test level 1
    ** Test level 2
    * Test level 1

And here is the same org-mode file but with the option atop its
content:

    ,#+title: Test file
    ,#+options: unique-id:t
    ,* Test level 1
    :PROPERTIES:
    :CUSTOM_ID: Test-level-1-zmb40t305kj0
    :END:
    ,** Test level 2
    :PROPERTIES:
    :CUSTOM_ID: Test-level-1-Test-level-2-spn40t305kj0
    :END:
    ,* Test level 1
    :PROPERTIES:
    :CUSTOM_ID: Test-level-1-1nx40t305kj0
    :END:

Of course the last part of the custom ID might differ for you, but
once it is generated, org-unique-id will not modify it or
regenerate it unless you delete it yourself, hence ensuring a
constant ID for your org exports.
