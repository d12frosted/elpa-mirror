
Command line utility sass is required, see http://sass-lang.com/
To install sass:
gem install sass

Also make sure sass location is in emacs PATH, example:
(setq exec-path (cons (expand-file-name "~/.gem/ruby/1.8/bin") exec-path))
or customize `scss-sass-command' to point to your sass executable.
