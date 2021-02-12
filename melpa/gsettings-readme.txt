This package provides helpers for Gnome GSettings.

Examples:

  (gsettings-available?)
  (gsettings-list-schemas)
  (gsettings-schema-exists? "org.gnome.desktop.interface")
  (gsettings-list-keys "org.gnome.desktop.interface")
  (gsettings-get "org.gnome.desktop.interface" "font-name")
  (gsettings-get "org.gnome.desktop.interface" "cursor-blink")
  (gsettings-get "org.gnome.desktop.interface" "cursor-size")
  (gsettings-get "org.gnome.desktop.interface" "this-fails")
  (gsettings-set-from-gvariant-string "org.gnome.desktop.interface" "cursor-blink" "false")
