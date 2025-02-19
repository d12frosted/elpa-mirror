                        ━━━━━━━━━━━━━━━━━━━━━━━
                                 RADIO

                               Roi Martin
                         jroi.martin@gmail.com
                        ━━━━━━━━━━━━━━━━━━━━━━━


Table of Contents
─────────────────

1. Overview
2. Installation
3. Configuration
4. Usage
5. Mode Line





1 Overview
══════════

  Radio is a GNU Emacs package that enables users to listen to Internet
  radio stations.  Its main focus is in simplicity.  It exposes the
  minimum required interface to interact with a list of radio stations
  and offloads media playing to an external program configured by the
  user.

  • Package name (NonGNU ELPA): `radio'
  • Source code repository: <https://github.com/jroimartin/radio>
  • Bug tracker: <https://github.com/jroimartin/radio/issues>


2 Installation
══════════════

  The package is available as `radio' in NonGNU ELPA.  Since the NonGNU
  package archive is enabled by default, you can easily install it by
  executing `M-x package-install RET radio'.  Alternatively, you can use
  `M-x list-packages'.


3 Configuration
═══════════════

  The following configuration variables allow to customize the behavior
  of the package:

  `radio-stations-alist'
        Alist of radio stations.

        Elements are of the form `(NAME . URL)', where `NAME' is the
        name of the radio station and `URL' is the URL of the radio
        station.

  `radio-command'
        Command used to play a radio station.

        The `:url' keyword is replaced with the URL of the radio
        station.

  The `customize' interface can be used to configure these variables.
  Specifically, the `radio' group contains all the relevant settings.

  However, if you prefer to add the configuration into your init file,
  then the following code can serve as an example:

  ┌────
  │ (customize-set-variable
  │  'radio-command
  │  '("mpv" "--terminal=no" "--video=no" :url))
  │ 
  │ (customize-set-variable
  │  'radio-stations-alist
  │  '(("First station" . "https://example.com/first.aac")
  │    ("Second station" . "https://example.com/second.aac")))
  └────

  It sets `mpv' as media player and registers two radio stations called
  “First station” and “Second station” with their respective URLs.


4 Usage
═══════

  Radio is mainly controlled by two commands:

  `radio STATION-NAME'
        Play a radio station.

        When called from Lisp, `STATION-NAME' must be the name of one of
        the stations defined in `radio-stations-alist'.

  `radio-stop'
        Stop playing current radio station.

        If no station is being played, calling this function has no
        effect.

  When invoked interactively, `radio' reads the station name from the
  minibuffer, with completion.  Modes like `fido-mode' can greatly
  improve user experience.

  For users that prefer a more visual interface, there exists a third
  command:

  `radio-list-stations'
        Display a list of all radio stations.

  It opens Radio’s tabulated view, which shows the list of configured
  radio stations as well as the play symbol next to the one being
  played.  It is controlled through the following key bindings:

  `RET'
        Play the selected radio station.
  `s'
        Stop playing the current radio station.


5 Mode Line
═══════════

  Information about the current station can be shown in the mode line by
  enabling `radio-line-mode'.

  `radio-line-mode'
        Toggle radio status display in mode line.
