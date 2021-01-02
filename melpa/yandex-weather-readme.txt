Parser for the yandex weather forecasts for the org-mode Agenda.
This script based on google-weather.el originally written by Julien Danjou.

How to use.

- Copy project files in your .emacs.d.
- Add this lines in your emacs config:

(load-file "~/.emacs.d/yandex-weather.el")
(load-file "~/.emacs.d/org-yandex-weather.el")

- Add this line in your agenda's org file.

%%(org-yandex-weather "27612")

Where '27612' is ID of your city from:
http://weather.yandex.ru/static/cities.xml

Also you can use MELPA for the installation.
