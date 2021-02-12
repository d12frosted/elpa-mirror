A company back-end for PHP.

(add-hook 'php-mode-hook
          '(lambda ()
            (require 'company-php)
            (company-mode t)
            (add-to-list 'company-backends 'company-ac-php-backend)))

Many options available under Help:Customize
Options specific to ac-php are in
  Convenience/Completion/Auto Complete
  Convenience/Completion/Company

Known to work with Linux and macOS.  Windows support is in beta stage.
For more info and examples see URL `https://github.com/xcwen/ac-php' .

Bugs: Bug tracking is currently handled using the GitHub issue tracker
(see URL `https://github.com/xcwen/ac-php/issues')
