* pyim-wbdict README                         :README:doc:

** 简介
pyim-wbdict 是 pyim 的一个五笔词库包。
1. pyim-wbdict-v86.pyim 源于 emacs-eim 的五笔词库。
2. pyim-wbdict-v98.pyim 源于 98wubi-tables 的五笔词库。
3. pyim-wbdict-v98-morphe.pyim 源于 98wubi-tables 的五笔词库。
4. pyim-wbdict-v86-single.pyim 源于 github.com/yekingyan/rime-wubi-86-single 的五笔单字词库。

** 安装和使用
1. 配置melpa源，参考：http://melpa.org/#/getting-started
2. M-x package-install RET pyim-wbdict RET
3. 在emacs配置文件中（比如: ~/.emacs）添加如下代码：
   #+BEGIN_EXAMPLE
   (require 'pyim-wbdict)
   (setq pyim-default-scheme 'wubi)
   ;; (pyim-wbdict-v86-enable) ;86版五笔用户使用这个命令
   ;; (pyim-wbdict-v98-enable) ;98版五笔用户使用这个命令
   ;; (pyim-wbdict-v98-morphe-enable) ;98版五笔（单字）用户使用这个命令，该词库为超大字符集，部分生僻字形可能需要安装支持EXT-B的字体（如HanaMinB等）才能正确显示
   ;; (pyim-wbdict-v86-single-enable) ;86版五笔用户使用这个命令，该词库为单字词库，以尽可能不重码减少选词需要为目的
   #+END_EXAMPLE
