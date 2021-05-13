* pyim-cangjie5dict README                         :README:doc:

** 简介
pyim-cangjie5dict 是 pyim 的一个倉頡五代词库，修改自 RIME 项目。源于《五倉世紀》。

** 安装和使用
1. 配置melpa源，参考：http://melpa.org/#/getting-started
2. M-x package-install RET pyim-cangjie5dict RET
3. 在emacs配置文件中（比如: ~/.emacs）添加如下代码：
   #+BEGIN_EXAMPLE
   (require 'pyim-cangjie5dict)
   (pyim-cangjie5dict-enable)
   (setq pyim-default-scheme 'cangjie)
   #+END_EXAMPLE
