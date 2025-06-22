
Replace holidays with holidays valid across all Australian states
and territories; e.g.:

(setq calendar-holidays australia-holidays)

Or append holidays:

(setq calendar-holidays (append calendar-holidays australia-holidays))

You can also use a more specific list tailored to your state; e.g.
for New South Wales use australia-holidays-for-nsw.
