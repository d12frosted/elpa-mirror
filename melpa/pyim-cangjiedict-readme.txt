* pyim-cangjiedict README                         :README:doc:

** 簡介(Introduction)
pyim-cangjiedict 是 pyim 的一個倉頡輸入法詞庫。

pyim-cangjiedict is a dict of Cangjie input scheme for [pyim](https://github.com/tumashu/pyim).

第一版詞庫僅支持倉頡五代，故名稱爲=pyim-cangjie5dict=，後續加入了六代詞庫，更名爲=pyim-cangjiedict=。現已加入對三代的支持。

The first version of the project only supported the Cangjie v5, so the name is =pyim-cangjie5dict=, and version 6th was subsequently added and renamed =pyim-cangjiedict=.

其中三代詞庫修改自 [[https://github.com/Arthurmcarthur/Cangjie3-Plus][Cangjie3-Plus]] 項目。

五代詞庫修改自 [[https://github.com/rime/rime-cangjie][rime-cangjie]] 項目，源於《五倉世紀》。

六代（蒼頡檢字法）詞庫修改自 [[https://github.com/rime-aca/rime-cangjie6][rime-cangjie6]] 項目。

The cangjie3dict originated from the [[https://github.com/Arthurmcarthur/Cangjie3-Plus][Cangjie3-Plus]] project,
the cangjie5dict originated from the [[https://github.com/rime/rime-cangjie][rime-cangjie]] project.
And the cangjie6dict is modified from the [[https://github.com/rime-aca/rime-cangjie6][rime-cangjie6]] project.

** 安裝和使用(Installation)
1. 配置melpa源，參考：http://melpa.org/#/getting-started
2. M-x package-install RET pyim-cangjiedict RET
3. 在emacs配置文件中（比如: ~/.emacs）添加如下代碼：
   #+BEGIN_EXAMPLE
   (require 'pyim-cangjiedict)
   (setq pyim-default-scheme 'cangjie)
   ;; 以下命令可任選其一：
   ;; (pyim-cangjie3dict-enable) ;; 啓用三代詞庫(Enable cangjie3)
   ;; (pyim-cangjie5dict-enable) ;; 啓用五代詞庫(Enable cangjie5)
   ;; (pyim-cangjie6dict-enable) ;; 啓用六代詞庫(Enable cangjie6)
   #+END_EXAMPLE
