This is a minor mode that show a modeline entry with the time
clocked today in your org-agenda-files.

The goal of this mode is to show how much you worked today, so that
you see when you worked your daily worktime.

Enable the mode with (org-clock-agenda-daytime-mode 1).

When you reach a target work time (default: 8 hours), the time
display turns green, after reaching a maximum work time (default:
10 hours) it turns red. The values and faces are are customizable
in the `org-clock' group (use M-x customize-group org-clock).

The time calculation caches results for one minute to avoid slowing
down interaction.
