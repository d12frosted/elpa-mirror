Circadian provides automated theme switching based on daytime.

Example usage (with `use-package') - make sure to properly set your
latitude & longitude:

(use-package circadian
  :config
  (setq calendar-latitude 49.0)
  (setq calendar-longitude 8.5)
  (setq circadian-themes '((:sunrise . wombat)
                           ("8:00"   . tango)
                           (:sunset  . adwaita)
                           ("23:30"  . tango)))
  (circadian-setup))
