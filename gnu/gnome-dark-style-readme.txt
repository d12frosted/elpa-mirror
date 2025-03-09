                         ━━━━━━━━━━━━━━━━━━━━━
                          GNOME-DARK-STYLE.EL
                         ━━━━━━━━━━━━━━━━━━━━━





1 Description
═════════════

  The `gnome-dark-style' package automatically synchronizes the Emacs
  theme with GNOME's color scheme. It allows users to define custom
  light and dark themes, ensuring a consistent look and feel across the
  GNOME desktop environment and GNU Emacs.


2 Features
══════════

  • Automatically switches between light and dark themes based on
    GNOME's color scheme.
  • Supports custom light and dark themes.
  • Monitors GNOME's color scheme in real-time and updates the Emacs
    theme accordingly.


3 Requirements
══════════════

  • *GNOME Shell 47.4* (tested with this version).
  • The `gsettings' command must be available on your system.


4 Installation
══════════════

4.1 GNU ELPA package
────────────────────

  The package is available as gnome-dark-style. Simply do:
  ┌────
  │ M-x package-refresh-contents
  │ M-x package-install
  └────


4.2 Manual installation
───────────────────────

  1. Clone the repository or download the `gnome-dark-style.el' file.
  2. Add the following to your Emacs configuration file `init.el':

     ┌────
     │ (add-to-list 'load-path "/path/to/gnome-dark-style")
     │ (require 'gnome-dark-style)
     └────

  3. Customize the light and dark themes using the `gnome-light-theme'
     and `gnome-dark-theme' variables.


5 Configuration
═══════════════

  You can customize the following variables:

  • `gnome-light-theme': The Emacs theme to use when GNOME's color
    scheme is set to light.
  • `gnome-dark-theme': The Emacs theme to use when GNOME's color scheme
    is set to dark.
  • `gnome-dark-style-sync': Enable or disable synchronization with
    GNOME's color scheme.

  Example configuration with use-package:

  ┌────
  │ ;; Sync Emacs theme with GNOME's color scheme
  │ (use-package gnome-dark-style
  │   ;; Uncomment and set your preferred themes
  │   ;; :custom
  │   ;; (gnome-light-theme 'ef-eagle)  ; default: nil
  │   ;; (gnome-dark-theme 'ef-owl)     ; default: wombat
  │   :config
  │   ;; Set to nil to stop monitoring and disable sync
  │   (setopt gnome-dark-style-sync t))
  └────


6 Usage
═══════

  Once installed and configured, the package will automatically switch
  between the specified light and dark themes based on GNOME's color
  scheme.


7 License
═════════

  This package is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or (at
  your option) any later version.


8 Contributing
══════════════

  Contributions are welcome! Please open an issue or submit a pull
  request on the [GitHub repository].


[GitHub repository] <https://github.com/dimagid/gnome-dark-style>


9 Acknowledgments
═════════════════

  • Thanks to GNU and the FSF for their excellent communities, software
    and documentation.
