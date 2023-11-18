### Description

A Robot Framework major mode for Emacs. Robot Framework is a framework for
acceptance testing.

- https://robotframework.org
- https://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html

This major mode provides the following:
- Syntax highlighting.
- Indentation.
- Alignment of keyword contents.
- Line continuation in Robot Framework syntax.
- A helper for adding necessary spaces between arguments.

#### Alignment of keyword contents

Align the contents of a keyword, test or task with `C-c C-a'. It changes the
following code:

    Example Keyword
        [Documentation]    Documents the keyword
        [Arguments]    ${arg1}    ${arg2}
        Log    ${arg1}            ${arg2}

To:

    Example Keyword
        [Documentation]    Documents the keyword
        [Arguments]        ${arg1}    ${arg2}
        Log                ${arg1}    ${arg2}

#### Line continuation

Insert a newline, indentation, ellipsis and necessary spaces at current
point with `C-c C-j'. For example (| denotes the cursor):

    Another Keyword
        [Documentation]    A very long text| that describes the keyword.

To:

    Another Keyword
        [Documentation]    A very long text
        ...    |that describes the keyword.

#### Add spacing for an argument

Robot framework separates arguments to keywords with 2 or more spaces. The
`C-c C-SPC' sets the whitespace amount around point to exactly
`robot-mode-argument-separator'. For example (| denotes the cursor):

    Example Keyword
        [Arguments]    ${first}|${second}

To:

    Example Keyword
        [Arguments]    ${first}    |${second}

### Limitations

- Currently supports only the Space separated format:
  https://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html#space-separated-format
- Does NOT support the Pipe separated format or the reStructuredText
  format.

### Notable changes

Version 0.8.0

- Add `robot-mode-retain-point-on-indent' option to retain point position
  when indenting. Currently it is disabled by default, but may be enabled
  in the future.
- Prevent indent toggling from interfering with TAB completion when
  `tab-always-indent' is set to 'complete and the above point retention is
  used.
- Fix several indent toggling bugs:
  - Set `electric-indent-inhibit'.
  - Disable when aligning by using variable `robot-mode-indent-toggle'.
- Fix syntax highlighting and indentation when a control structure word is
  the first word in a keyword.
- Fix various other syntax highlighting bugs.

Version 0.7.0

- Add control structure indentation (IF/WHILE/FOR/TRY etc.).
