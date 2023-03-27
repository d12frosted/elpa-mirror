
The list of public Latvian holidays (day offs) and commemoration days.

Informational sources:
https://likumi.lv/doc.php?id=72608
https://lv.wikipedia.org/wiki/Vispārējie_latviešu_Dziesmu_un_Deju_svētki

; Installation:

Replace holidays:

(setq calendar-holidays latvian-holidays)

Or append holidays:

(setq calendar-holidays (append calendar-holidays latvian-holidays))

You could also append commemoration and celebration days:

(setq calendar-holidays (append latvian-holidays latvian-holidays-commemoration-days)

or:

(setq calendar-holidays (append calendar-holidays latvian-holidays latvian-holidays-commemoration-days))
