* pyim-wbdict README                         :README:doc:

** 简介
pyim-wbdict 是 pyim 的一个五笔词库，词库源于 emacs-eim.

** 安装和使用
1. 配置melpa源，参考：http://melpa.org/#/getting-started
2. M-x package-install RET pyim-wbdict RET
3. 在emacs配置文件中（比如: ~/.emacs）添加如下代码：
   #+BEGIN_EXAMPLE
   (require 'pyim-wbdict)
   (pyim-wbdict-gb2312-enable) ; gb2312 version
   ;; (pyim-wbdict-gbk-enable) ; gbk version
   #+END_EXAMPLE
