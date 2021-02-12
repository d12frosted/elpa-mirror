
Put this file into your load-path and the following into your ~/.emacs:

(register-input-method
 "chinese-wbim" "euc-cn" 'chinese-wbim-use-package
 "五笔" "汉字五笔输入法" "wb.txt")
