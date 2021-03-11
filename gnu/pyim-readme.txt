* pyim 使用说明                                          :README:doc:
** 截图
[[./snapshots/pyim-linux-x-with-toolkit.png]]

** 简介
pyim 是 Emacs 环境下的一个中文输入法，最初它只支持全拼输入，所以当时
"pyim" 代表 "Chinese Pinyin Input Method" 的意思，后来根据同学的提议，
添加了五笔的支持，再叫 “拼音输入法” 就不太合适了，所以你现在可以将它理解
为 “PengYou input method”： 平时像朋友一样帮助你，偶尔也像朋友一样犯二 。。。

** 背景
pyim 的代码源自 emacs-eim。

emacs-eim 是 Emacs 环境下的一个中文输入法框架， 支持拼音，五笔，仓颉以及二笔等
多种输入法，但遗憾的是，2008 年之后它就停止了开发，我认为主要原因是外部中文输入法快速发展。

虽然外部输入法功能强大，但不能和 Emacs 默契的配合，这一点极大的损害了 Emacs 那种 *行云流水*
的感觉。而本人在使用（或者叫折腾） emacs-eim 的过程中发现：

1. *当 emacs-eim 词库词条超过 100 万时，选词频率大大降低，中文体验增强。*
3. *随着使用时间的延长，emacs-eim 会越来越好用（个人词库的积累）。*

于是我 fork 了 emacs-eim 输入法的部分代码, 创建了一个项目：pyim。

** 目标
pyim 的目标是： *尽最大的努力成为一个好用的 Emacs 中文输入法* ，
具体可表现为三个方面：

1. Fallback:     当外部输入法不能使用时，比如在 console 或者 cygwin 环境
   下，尽最大可能让 Emacs 用户不必为输入中文而烦恼。
2. Integration:  尽最大可能减少输入法切换频率，让中文输入不影响 Emacs
   的体验。
3. Exchange:     尽最大可能简化 pyim 使用其他优秀输入法的词库
   的难度和复杂度。

** 特点
1. pyim 支持全拼，双拼，五笔和仓颉，其中对全拼的支持最好。
2. pyim 通过添加词库的方式优化输入法。
3. pyim 使用文本词库格式，方便处理。

** 安装
1. 配置 melpa 源，参考：http://melpa.org/#/getting-started
2. M-x package-install RET pyim RET
3. 在 Emacs 配置文件中（比如: ~/.emacs）添加如下代码：
   #+BEGIN_EXAMPLE
   (require 'pyim)
   (require 'pyim-basedict) ; 拼音词库设置，五笔用户 *不需要* 此行设置
   (pyim-basedict-enable)   ; 拼音词库，五笔用户 *不需要* 此行设置
   (setq default-input-method "pyim")
   #+END_EXAMPLE

** 配置

*** 配置实例
对 pyim 感兴趣的同学，可以看看本人的 pyim 配置（总是适用于最新版的 pyim）:

#+BEGIN_EXAMPLE
(use-package pyim
  :ensure nil
  :demand t
  :config
  ;; 激活 basedict 拼音词库，五笔用户请继续阅读 README
  (use-package pyim-basedict
    :ensure nil
    :config (pyim-basedict-enable))

  (setq default-input-method "pyim")

  ;; 我使用全拼
  (setq pyim-default-scheme 'quanpin)

  ;; 设置 pyim 探针设置，这是 pyim 高级功能设置，可以实现 *无痛* 中英文切换 :-)
  ;; 我自己使用的中英文动态切换规则是：
  ;; 1. 光标只有在注释里面时，才可以输入中文。
  ;; 2. 光标前是汉字字符时，才能输入中文。
  ;; 3. 使用 M-j 快捷键，强制将光标前的拼音字符串转换为中文。
  (setq-default pyim-english-input-switch-functions
                '(pyim-probe-dynamic-english
                  pyim-probe-isearch-mode
                  pyim-probe-program-mode
                  pyim-probe-org-structure-template))

  (setq-default pyim-punctuation-half-width-functions
                '(pyim-probe-punctuation-line-beginning
                  pyim-probe-punctuation-after-punctuation))

  ;; 开启拼音搜索功能
  (pyim-isearch-mode 1)

  ;; 使用 posframe 绘制 page, (需要用户手动安装 posframe 包）。
  ;; (setq pyim-page-tooltip 'posframe)

  ;; 如果 posframe 不可用，可以试着安装 popup 包，然后设置：
  ;; ;; (setq pyim-page-tooltip 'popup)

  ;; 选词框显示5个候选词
  (setq pyim-page-length 5)

  :bind
  (("M-j" . pyim-convert-string-at-point) ;与 pyim-probe-dynamic-english 配合
   ("C-;" . pyim-delete-word-from-personal-buffer)))
#+END_EXAMPLE

*** 添加词库文件
pyim 当前的默认的拼音词库是 pyim-basedict, 这个词库的词条量
8 万左右，是一个 *非常小* 的拼音词库，词条的来源有两个：

1. libpinyin 项目的内置词库
2. pyim 用户贡献的个人词库

如果 pyim-basedict 不能满足需求，用户可以使用其他方式为 pyim 添加拼音词库，
具体方式请参考 [[如何添加自定义拼音词库]] 小结。

*** 激活 pyim

#+BEGIN_EXAMPLE
(setq default-input-method "pyim")
(global-set-key (kbd "C-\\") 'toggle-input-method)
#+END_EXAMPLE

** 使用
*** 常用快捷键
| 输入法快捷键          | 功能                       |
|-----------------------+----------------------------|
| C-n 或 M-n 或 + 或 .  | 向下翻页                   |
| C-p 或 M-p 或 - 或 ,  | 向上翻页                   |
| C-f                   | 选择下一个备选词           |
| C-b                   | 选择上一个备选词           |
| SPC                   | 确定输入                   |
| RET 或 C-m            | 字母上屏                   |
| C-c                   | 取消输入                   |
| C-g                   | 取消输入并保留已输入的中文 |
| TAB                   | 模糊音调整                 |
| DEL 或 BACKSPACE      | 删除最后一个字符           |
| C-DEL 或  C-BACKSPACE | 删除最后一个拼音           |
| M-DEL 或  M-BACKSPACE | 删除最后一个拼音           |

*** 使用双拼模式
pyim 支持双拼输入模式，用户可以通过变量 `pyim-default-scheme' 来设定：

#+BEGIN_EXAMPLE
(setq pyim-default-scheme 'pyim-shuangpin)
#+END_EXAMPLE

注意：
1. pyim 支持微软双拼（microsoft-shuangpin）和小鹤双拼（xiaohe-shuangpin）。
2. 用户可以使用函数 `pyim-scheme-add' 添加自定义双拼方案。
3. 用户可能需要重新设置 `pyim-translate-trigger-char'。

*** 使用 rime 输入法
具体安装和使用方式请查看 pyim-liberime 包的 Commentary 部分。

*** 使用五笔输入
pyim 支持五笔输入模式，用户可以通过变量 `pyim-default-scheme' 来设定：

#+BEGIN_EXAMPLE
(setq pyim-default-scheme 'wubi)
#+END_EXAMPLE

在使用五笔输入法之前，请用 pyim-dicts-manager 添加一个五笔词库，词库的格式类似：

#+BEGIN_EXAMPLE