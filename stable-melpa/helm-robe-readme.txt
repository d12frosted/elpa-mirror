helm-robe.el provides function for setting `robe-completing-read-func'.

You can use its function for robe completing with following configuration

(custom-set-variables
 '(robe-completing-read-func 'helm-robe-completing-read))
