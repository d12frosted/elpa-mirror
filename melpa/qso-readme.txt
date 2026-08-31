This LISP code provides some basic functions for Emacs to rapidly
capture and log amateur radio contacts (QSOs) into an ADIF file.

qso.el provides a fuction that generates a customizable, dynamic
form (qso-log-form) to log amateur radio QSOs using almost any
combination of ADIF fields in the ADIF 3.1.4 specification.
This allows the user to customize the form for use in contests or
general logging.  All customizations are accessible in the "QSO"
group, whose parent is the Emacs "Applications" group, accessed
with M-x customize.

Further processing of the logs can be done within Emacs or by
importing the ADIF file into another logging program.

Features

- Simple, customizable text interface for real-time ham radio QSO
  logging or even to rapidly convert paper log entries to an ADIF
- Runs entirely in a Linux terminal environment, allowing for its
  use in ultra-light, low-power HW/SW configurations (e.g. terminal-
  only mode on a Raspberry Pi Zero 2W)
- No mouse required (using tab or shift-tab to change fields or
  hover over buttons)
- Log entries are appended to a user-specified ADIF log file
- Any field in the ADIF 3.1.4 specification can be selected to
  appear on the form, in whatever order is desired
- Each field has an option to preserve the most recent information
  after a QSO submission
  - Example: For situations where frequency and mode unchanged
    between QSOs
  - Also useful for repeating sent information reports in contests
- Automatically populates BAND based on FREQ for commonly used
  bands, if otherwise left blank or not shown on the form
- Optional live radio synchronization through Hamlib's rigctld:
  FREQ, MODE and SUBMODE follow the radio as the operator tunes
  or changes mode, and the current reading is shown in the header
  line above the form
- Option to lookup callsign information and show the information
  (text) in another buffer (requires an internet connection)
- Callsigns can be looked up at callook.info, HamQTH or QRZ.com,
  and the fields worth keeping can be filled in automatically,
  whether or not they appear on the form
- Country, continent and CQ/ITU zones can be worked out from the
  callsign itself using a cty.dat country file, which covers the
  whole world with no network connection and no account
- Option to check the log for duplicates before recording the QSO
- Option to clear the form without saving the information (e.g.
  for incomplete QSOs)

Getting Started

 1) Execute M-x customize, select "Applications" and then select
    "QSO" to see the customization options.
 2) Enter your callsign in the QSO Operator field.
 3) Enter the path to the ADIF file you will be using
    (e.g. ~/qsolog.adi).
 4) Add, remove, or reorder the fields you wish to have on the form.
 5) Select or deselect form fields that you wish you have cleared
    after a QSO submission (especially helpful for contests).
 6) Click "Apply" or "Apply and Save" as appropriate.
 7) Execute M-x qso-log-form to bring up and begin using the log
    entry form.

Reading Frequency and Mode From the Radio (optional)

 1) Install Hamlib and start its rigctld daemon against your radio,
    for example:

      rigctld -m 3073 -r /dev/ttyUSB0 -s 38400

    Run "rigctl -l" to find the model number (-m) for your radio.
    rigctld is used rather than a direct serial connection so that
    this package can share the radio with other software (WSJT-X,
    fldigi, and so on) and so that polling never blocks Emacs.
 2) Turn on "QSO Hamlib Enable" in the QSO customization group, and
    set the host and port if rigctld is not on the default
    localhost:4532.
 3) Add FREQ, MODE and (optionally) SUBMODE to the form fields so
    that the values are visible while logging.  SUBMODE is written
    to the ADIF record whether or not it appears on the form.
 4) Within the form, C-c C-r reads the radio once and C-c C-t turns
    synchronization on or off.

While synchronization is running, a field is updated only when it is
empty or still holds the value the radio last put there, so anything
typed by the operator is never overwritten.

Looking Up Callsigns (optional)

"QSO Callsign Lookup Source" chooses where details come from:

  callook.info  United States only, no account needed.  This is the
                default, and it serves the FCC's public database.
  HamQTH        Worldwide, free, but asks you to register.
  QRZ.com       Worldwide, needs a paid XML subscription.

Most countries outside the United States do not publish operator
names and addresses at all, which is why a worldwide lookup means
using a community-maintained callbook rather than an official
register.

HamQTH and QRZ.com need a login.  Put the username in "QSO Callsign
Lookup User" and the password in ~/.authinfo.gpg, so that it is not
kept in your Emacs configuration:

  machine www.hamqth.com login MYCALL password SECRET
  machine xmldata.qrz.com login MYCALL password SECRET

"QSO Callsign Lookup Fields" chooses what to fill in.  A field is
filled whether or not it is on the form: anything not on the form is
written straight into the ADIF record when the QSO is submitted.

Country, continent and CQ/ITU zones can also be worked out from the
callsign alone, with no network connection and no account, for any
callsign in the world.  Download a country file from
https://www.country-files.com, point "QSO Country File" at it, and
leave "QSO Callsign Lookup DXCC" on.  Whatever the chosen source
reports takes precedence over this, and if the file is missing the
rest of the form carries on as usual.

Within the form, C-c C-l looks up the callsign that has been typed.
