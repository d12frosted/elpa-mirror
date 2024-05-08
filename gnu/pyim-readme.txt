           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            PYIM 是一个 EMACS 中文输入法，支持全拼，双拼，五
                          笔，仓颉 和 RIME 等
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━





1 不兼容更新
════════════

1.1 <2022-06-15 Wed>  Do not require popup in pyim-page.el
──────────────────────────────────────────────────────────

  popup 是一个非 gnu elpa 包，pyim-page.el 不应该 require 它，需要用户自
  己手动require, 使用 popup tooltip 的用户需要在配置中添加：

  ┌────
  │ (require 'popup)
  └────


1.2 <2022-06-13 Mon>  pyim-dcache-backend 所需的 package 需要用户手工加载了。
─────────────────────────────────────────────────────────────────────────────

  以前 pyim 可以根据 pyim-dcache-backend 的取值自动加载需要的 package,
  这样做虽然方便，但代码特别容易出现问题，考虑到 pyim 未来支持的后端不会
  有太大变化，我删除了这个功能，为了向后兼容，pyim 目前会自动加载
  pyim-dregcache 包, 但这个兼容代码未来可能会删除，所以使用
  pyim-dregcache 的用户，建议给自己的配置中添加：

  ┌────
  │ (require 'pyim-dregcache)
  └────


1.3 <2022-05-29 Sun>  pyim-cregexp-utils, pyim-cstring-utils 和 pyim-dict-manager 需要用户手动 require.
───────────────────────────────────────────────────────────────────────────────────────────────────────

  为降低 pyim 代码的复杂度，减少 pyim 依赖包的数量，下面三个包不会自动加
  载，需要用户手动 require.

  1. pyim-cregexp-utils
  2. pyim-cstring-utils
  3. pyim-dict-manager (使用 elpa 安装词库，或者手动管理 pyim-dicts 变量
     的用户不需要这个包)


1.4 <2021-04-28 Wed>  五笔输入法和仓颉输入法的不兼容更新
────────────────────────────────────────────────────────

  五笔输入法和仓颉输入法原来使用一个标点符号作为 code-prefix, 现在使用
  "wubi/" 和"cangjie/" 这种形式的 code-prefix, 这样可以减少不同输入法误
  用同一个 code-prefix带来的词库冲突。

  五笔输入法的 scheme 设置已经移到 pyim-wbdict 包，仓颉输入法的 scheme
  设置已经移到 pyim-cangjie5dict 包。

  使用上述两个包的用户，此次变更不受影响，因为两个包使用新的
  code-prefix.

  受影响的是自己维护五笔和仓颉词库用户，这些用户需要做以下更新：
  1. 五笔用户
     1. 需要 (require 'pyim-wbdict), 加载五笔 scheme 设置。
     2. 需要将自己的五笔词库文件中的 code-prefix "." 替换为 "wubi/".
     3. 运行 `pyim-upgrade' 命令，升级 icode2word 词库缓存。
  2. 仓颉用户
     1. 需要 (require 'pyim-cangjie5dict), 加载仓颉 scheme 设置。
     2. 需要将自己的五笔词库文件中的 code-prefix "@" 替换为 "cangjie/".


2 截图
══════

  <file:./snapshots/pyim-linux-x-with-toolkit.png>


3 简介
══════

  pyim 是 Emacs 环境下的一个中文输入法，最初这个输入法只支持全拼输入，后
  来根据同学的提议，添加了五笔等输入法的支持，“pyim” 现在可以理解为：

  		       (Peng You input method)


4 背景
══════

  pyim 源于 Emacs-eim。

  Emacs-eim 是 Emacs 环境下的一个中文输入法框架， 支持拼音，五笔，仓颉，
  二笔等多种输入法，但遗憾的是，2008 年之后它就停止了开发。

  虽然外部输入法功能强大，但不能和 Emacs 默契的配合，这一点极大的损害了
  Emacs 那种*行云流水* 的感觉。而本人在使用 Emacs-eim 的过程中发现：

  1. *当 Emacs-eim 词库词条很大时，选词频率大大降低，中文体验增强。*
  2. *随着使用时间的延长，Emacs-eim 会越来越好用（个人词库的积累）。*

  于是我 fork 了 Emacs-eim 输入法的部分代码, 创建了新项目：pyim。


5 目标
══════

  pyim 的目标是： *尽最大的努力成为一个好用的 Emacs 中文输入法* ，具体可
  表现为三个方面：

  1. Fallback: 当外部输入法不能使用时，比如在 console 或者 cygwin 环境下，
     尽最大可能让 Emacs 用户不必为输入中文而烦恼。
  2. Integration: 尽最大可能减少输入法切换频率，让中文输入不影响 Emacs
     的体验。
  3. Exchange: 尽最大可能简化 pyim 使用其他优秀输入法的词库的难度和复杂
     度。


6 特点
══════

  1. pyim 支持全拼，双拼，五笔和仓颉等输入法，其中对全拼的支持最好。
  2. pyim 通过添加词库的方式优化输入法。
  3. pyim 使用文本词库格式，方便处理。
  4. pyim 可以作为 rime 的前端使用。


7 安装
══════

  1. M-x package-install RET pyim RET
  2. 在 Emacs 配置文件中（比如: ~/.emacs）添加如下代码：
     ┌────
     │ (require 'pyim)
     │ (require 'pyim-basedict) ; 拼音词库设置，五笔用户 *不需要* 此行设置
     │ (pyim-basedict-enable)   ; 拼音词库，五笔用户 *不需要* 此行设置
     │ (setq default-input-method "pyim")
     └────


8 配置
══════

8.1 配置实例
────────────

  对 pyim 感兴趣的同学，可以看看本人的 pyim 配置，但要注意不要乱抄探针配
  置。

  ┌────
  │ (require 'pyim)
  │ (require 'pyim-basedict)
  │ (require 'pyim-cregexp-utils)
  │ 
  │ ;; 如果使用 popup page tooltip, 就需要加载 popup 包。
  │ ;; (require 'popup nil t)
  │ ;; (setq pyim-page-tooltip 'popup)
  │ 
  │ ;; 如果使用 pyim-dregcache dcache 后端，就需要加载 pyim-dregcache 包。
  │ ;; (require 'pyim-dregcache)
  │ ;; (setq pyim-dcache-backend 'pyim-dregcache)
  │ 
  │ ;; 加载 basedict 拼音词库。
  │ (pyim-basedict-enable)
  │ 
  │ ;; 将 Emacs 默认输入法设置为 pyim.
  │ (setq default-input-method "pyim")
  │ 
  │ ;; 显示 5 个候选词。
  │ (setq pyim-page-length 5)
  │ 
  │ ;; 金手指设置，可以将光标处的编码（比如：拼音字符串）转换为中文。
  │ (global-set-key (kbd "M-j") 'pyim-convert-string-at-point)
  │ 
  │ ;; 按 "C-<return>" 将光标前的 regexp 转换为可以搜索中文的 regexp.
  │ (define-key minibuffer-local-map (kbd "C-<return>") 'pyim-cregexp-convert-at-point)
  │ 
  │ ;; 设置 pyim 默认使用的输入法策略，我使用全拼。
  │ (pyim-default-scheme 'quanpin)
  │ ;; (pyim-default-scheme 'wubi)
  │ ;; (pyim-default-scheme 'cangjie)
  │ 
  │ ;; 设置 pyim 是否使用云拼音
  │ ;; (setq pyim-cloudim 'baidu)
  │ 
  │ ;; 设置 pyim 探针
  │ ;; 设置 pyim 探针设置，这是 pyim 高级功能设置，可以实现 *无痛* 中英文切换 :-)
  │ ;; 我自己使用的中英文动态切换规则是：
  │ ;; 1. 光标只有在注释里面时，才可以输入中文。
  │ ;; 2. 光标前是汉字字符时，才能输入中文。
  │ ;; 3. 使用 M-j 快捷键，强制将光标前的拼音字符串转换为中文。
  │ ;; (setq-default pyim-english-input-switch-functions
  │ ;;               '(pyim-probe-dynamic-english
  │ ;;                 pyim-probe-isearch-mode
  │ ;;                 pyim-probe-program-mode
  │ ;;                 pyim-probe-org-structure-template))
  │ 
  │ ;; (setq-default pyim-punctuation-half-width-functions
  │ ;;               '(pyim-probe-punctuation-line-beginning
  │ ;;                 pyim-probe-punctuation-after-punctuation))
  │ 
  │ ;; 开启代码搜索中文功能（比如拼音，五笔码等）
  │ (pyim-isearch-mode 1)
  └────


8.2 添加词库文件
────────────────

  pyim 默认使用 pyim-basedict 词库, 这个词库的词条量8万左右，是一个 *非
  常小* 的拼音词库，源于：libpinyin 项目

  如果 pyim-basedict 不能满足需求，用户可以使用其他方式为 pyim 添加拼音
  词库，具体方式请参考 小结。


8.3 激活 pyim
─────────────

  ┌────
  │ (setq default-input-method "pyim")
  │ (global-set-key (kbd "C-\\") 'toggle-input-method)
  └────


9 使用
══════

9.1 常用快捷键
──────────────

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   输入法快捷键           功能                       
  ───────────────────────────────────────────────────
   C-n 或 M-n 或 + 或 .   向下翻页                   
   C-p 或 M-p 或 - 或 ,   向上翻页                   
   C-f                    选择下一个备选词           
   C-b                    选择上一个备选词           
   SPC                    确定输入                   
   RET 或 C-m             字母上屏                   
   C-c                    取消输入                   
   C-g                    取消输入并保留已输入的中文 
   TAB                    模糊音调整                 
   DEL 或 BACKSPACE       删除最后一个字符           
   C-DEL 或  C-BACKSPACE  删除最后一个拼音           
   M-DEL 或  M-BACKSPACE  删除最后一个拼音           
   F1,F2,F3,F4            以词定字                   
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


9.2 使用云输入法
────────────────

  pyim 可以使用搜索引擎提供的云输入法服务，比如：

  ┌────
  │ (setq pyim-cloudim 'baidu)
  │ ;; (setq pyim-cloudim 'google)
  └────


9.3 使用双拼模式
────────────────

  pyim 支持双拼输入模式，用户可以通过变量 `pyim-default-scheme' 来设定：

  ┌────
  │ (pyim-default-scheme 'pyim-shuangpin)
  └────

  注意：
  1. pyim 支持微软双拼（microsoft-shuangpin）和小鹤双拼
     （xiaohe-shuangpin）。
  2. 用户可以使用函数 `pyim-scheme-add' 添加自定义双拼方案。
  3. 用户可能需要重新设置 `pyim-outcome-trigger'。


9.4 使用 rime 输入法
────────────────────

  具体安装和使用方式请查看 pyim-liberime 包的 Commentary 部分。


9.5 使用型码输入法
──────────────────

  1. 五笔输入法可以参考： <https://github.com/tumashu/pyim-wbdict>
  2. 仓颉输入法可以参考：<https://github.com/p1uxtar/pyim-cangjiedict>
  3. 三码郑码（至至郑码）输入法可以参考：
     <https://github.com/p1uxtar/pyim-smzmdict>

  如果用户在使用型码输入法的过程中，忘记了某个字的编码，可以按 TAB 键临
  时切换到辅助输入法来输入，辅助输入法可以通过 `pyim-assistant-scheme'
  来设置。


9.6 让选词框跟随光标
────────────────────

  用户可以通过下面的设置让 pyim 在 *光标处* 显示一个选词框：

  1. 使用 popup 或者 popon 包来绘制选词框 （emacs overlay 机制）
     ┌────
     │ (require 'popup)
     │ (setq pyim-page-tooltip 'popup)
     └────

     ┌────
     │ (require 'popon)
     │ (setq pyim-page-tooltip 'popon)
     └────

  2. 使用 posframe 来绘制选词框
     ┌────
     │ (require 'posframe)
     │ (setq pyim-page-tooltip 'posframe)
     └────
     注意：pyim 不会自动安装 posframe, 用户需要手动安装这个包，
  3. 按照优先顺序自动选择一个可用的 tooltip
     ┌────
     │ (setq pyim-page-tooltip '(posframe popup minibuffer))
     └────


9.7 调整 tooltip 选词框的显示样式
─────────────────────────────────

  pyim 的选词框默认使用 *双行显示* 的样式，在一些特殊的情况下（比如：
  popup 显示的菜单错位），用户可以使用 *单行显示*的样式：

  ┌────
  │ (setq pyim-page-style 'one-line)
  └────


9.8 设置模糊音
──────────────

  可以通过设置 `pyim-pinyin-fuzzy-alist' 变量来自定义模糊音。


9.9 使用魔术转换器
──────────────────

  用户可以将待选词 “特殊处理” 后再 “上屏”，比如 “简体转繁体” 或者 “输入
  中文，上屏英文” 之类的。

  用户需要设置 `pyim-outcome-magic-converter', 比如：下面这个例子实现，
  输入 “二呆”，“一个超级帅的小伙子” 上屏 :-)

  ┌────
  │ (defun my-converter (string)
  │   (if (equal string "二呆")
  │       "“一个超级帅的小伙子”"
  │     string))
  │ (setq pyim-outcome-magic-converter #'my-converter)
  └────


9.10 切换全角标点与半角标点
───────────────────────────

  1. 第一种方法：使用命令 `pyim-punctuation-toggle'，全局切换。这个命令
     主要用来设置变量： `pyim-punctuation-translate-p', 用户也可以手动设
     置这个变量， 比如：

     ┌────
     │ (setq-default pyim-punctuation-translate-p '(yes))    ;使用全角标点。
     │ (setq-default pyim-punctuation-translate-p '(no))     ;使用半角标点。
     │ (setq-default pyim-punctuation-translate-p '(auto))   ;中文使用全角标点，英文使用半角标点。
     └────

  2. 第二种方法：使用命令 `pyim-punctuation-translate-at-point' 只切换光
     标处标点的样式。
  3. 第三种方法：设置变量 `pyim-outcome-trigger' ，输入变量设定的字符会
     切换光标处标点的样式。


9.11 手动加词和删词
───────────────────

  1. `pyim-convert-string-at-point' 金手指命令，可以比较方便的添加和删除
     词条，比如：
     1. 在 "你好" 后面输入2, 然后运行金手指命令，可以将 “你好” 加入个人
        词库。
     2. 在 “你好” 后面输入2-, 然后运行金手指命令，可以将 “你好” 从个人词
        库删除。
     3. 如果用户选择了一个词条，则运行金手指命令可以将选择的词条加入个人
        词库。
  2. `pyim-create-Ncchar-word-at-point' 这是一组命令，从光标前提取N个汉
     字字符组成字符串，并将其加入个人词库。
  3. `pyim-outcome-trigger' 以默认设置为例：在 “我爱吃红烧肉” 后输入
     “5v”，可以将“爱吃红烧肉”这个词条保存到用户个人词库。
  4. `pyim-create-word-from-selection', 选择一个词条，运行这个命令后，就
     可以将这个词条添加到个人词库。
  5. `pyim-delete-word' 从个人词库中删除当前高亮选择的词条。


9.12 pyim 输入状态指示器
────────────────────────

  pyim 输入状态指示器可以帮助用户快速了解当前 pyim 是处于英文输入状态还
  是中文输入状态，因为 pyim probe 探针功能可以让中英文输入状态动态切换，
  所以快速了解当前中英文输入状态有时候显得很重要。

  pyim 当前内置两种指示器实现方式：
  1. 改变光标颜色： pyim-indicator-with-cursor-color, 用户可以使用变量
     pyim-indicator-cursor-color 来配置两种输入状态对应的光标颜色。
  2. 使用 modeline 显示状态字符串：pyim-indicator-with-mode-line, 用户可
     以使用变量pyim-indicator-modeline-string 来配置两种状态对应的显示字
     符串。

  设置默认启用的指示器有两个，用户可以使用下面的变量调整：
  ┌────
  │ (setq pyim-indicator-list (list #'pyim-indicator-with-cursor-color #'pyim-indicator-with-modeline))
  └────

  注意事项：
  1. 用户切换 emacs 主题之后，最好重启 pyim 一下。
  2. pyim-indicator-with-cursor-color 这个 indicator 很容易和其它设置
     cursor 颜色的包冲突，因为都调用 set-cursor-color，遇到这种情况后，
     用户需要自己解决冲突，pyim-indicator 提供了一个简单的机制：
     ┌────
     │ (setq pyim-indicator-list (list #'my-pyim-indicator-with-cursor-color #'pyim-indicator-with-modeline))
     │ 
     │ (defun my-pyim-indicator-with-cursor-color (input-method chinese-input-p)
     │   (if (not (equal input-method "pyim"))
     │       (progn
     │         ;; 用户在这里定义 pyim 未激活时的光标颜色设置语句
     │         (set-cursor-color "red"))
     │     (if chinese-input-p
     │         (progn
     │           ;; 用户在这里定义 pyim 输入中文时的光标颜色设置语句
     │           (set-cursor-color "green"))
     │       ;; 用户在这里定义 pyim 输入英文时的光标颜色设置语句
     │       (set-cursor-color "blue"))))
     └────


9.13 pyim 高级功能
──────────────────

  1. 根据环境自动切换到英文输入模式，使用
     pyim-english-input-switch-functions 配置。
  2. 根据环境自动切换到半角标点输入模式，使用
     pyim-punctuation-half-width-functions 配置。
  3. 如果想在某种环境下强制输入中文，可以使用
     pyim-force-input-chinese-functions来配置，这个设置可以屏蔽掉
     pyim-english-input-switch-functions 的设置。

  注意：上述两个功能使用不同的变量设置， *千万不要搞错* 。


9.13.1 根据环境自动切换到英文输入模式
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   探针函数                           功能说明                                                                          
  ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   pyim-probe-program-mode            如果当前的 mode 衍生自 prog-mode，那么仅仅在字符串和 comment 中开启中文输入模式   
  ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   pyim-probe-org-speed-commands      解决 org-speed-commands 与 pyim 冲突问题                                          
   pyim-probe-isearch-mode            使用 isearch 搜索时，强制开启英文输入模式                                         
                                      注意：想要使用这个功能，pyim-isearch-mode 必须激活                                
  ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   pyim-probe-org-structure-template  使用 org-structure-template 时，关闭中文输入模式                                  
  ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
                                      1. 当前字符为中文字符时，输入下一个字符时默认开启中文输入                         
   pyim-probe-dynamic-english         2. 当前字符为其他字符时，输入下一个字符时默认开启英文输入                         
                                      3. 使用命令 pyim-convert-string-at-point 可以将光标前的拼音字符串强制转换为中文。 
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  激活方式：

  ┌────
  │ (setq-default pyim-english-input-switch-functions
  │               '(probe-function1 probe-function2 probe-function3))
  └────

  注意事项：
  1. 上述函数列表中，任意一个函数的返回值为 t 时，pyim 切换到英文输入模
     式。
  2. [Emacs-rime] 和 [smart-input-source] 也有类似探针的功能，其对应函数
     可以直接或者简单包装后作为 pyim 探针使用，有兴趣的同学可以了解一下。


[Emacs-rime] <https://github.com/DogLooksGood/emacs-rime>

[smart-input-source]
<https://github.com/laishulu/emacs-smart-input-source>


9.13.2 根据环境自动切换到半角标点输入模式
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   探针函数                                  功能说明                   
  ──────────────────────────────────────────────────────────────────────
   pyim-probe-punctuation-line-beginning     行首强制输入半角标点       
  ──────────────────────────────────────────────────────────────────────
   pyim-probe-punctuation-after-punctuation  半角标点后强制输入半角标点 
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  激活方式：

  ┌────
  │ (setq-default pyim-punctuation-half-width-functions
  │               '(probe-function4 probe-function5 probe-function6))
  └────

  注：上述函数列表中，任意一个函数的返回值为 t 时，pyim 切换到半角标点输
  入模式。


10 开发
═══════

  请参考 [Development.org] 文档


[Development.org] <file:Development.org>


11 试用
═══════

  在pyim项目根目录运行shell命令 `make runemacs' 试用最新的pyim。

  只有pyim和其依赖的包被载入。用户自己的emacs配置不会被载入。

  指定运行的Emacs版本用以下命令,
  ┌────
  │ EMACS=~/my-whatever-directory/bin/emacs make runemacs
  └────

  Emacs启动后 "M-x toggle-input-method" 或按 "C-\\" 打开输入法。


12 Tips
═══════

12.1 pyim 有时候会出现卡顿，如何处理。
──────────────────────────────────────

  可以将云搜词和当前 buffer 搜词功能关闭试试看。
  ┌────
  │ (setq pyim-cloudim nil)
  │ (setq pyim-candidates-search-buffer-p nil)
  └────


12.2 如何快速切换 scheme
────────────────────────

  可以试试 pyim-default-scheme 命令。


12.3 关闭输入联想词功能 (默认开启)
──────────────────────────────────

  ┌────
  │ (setq pyim-enable-shortcode nil)
  └────


12.4 形码输入法如何微调候选词序
───────────────────────────────

  ┌────
  │ (setq pyim-candidates-xingma-words-function #'my-func)
  └────


12.5 如何将个人词条相关信息导入和导出？
───────────────────────────────────────

  1. 导入使用命令： pyim-dcache-import
  2. 导出使用命令： pyim-dcache-export


12.6 pyim 出现错误时，如何开启 debug 模式
─────────────────────────────────────────

  ┌────
  │ (setq debug-on-error t)
  └────


12.7 将光标处的拼音或者五笔字符串转换为中文 (与 vimim 的 “点石成金” 功能类似)
─────────────────────────────────────────────────────────────────────────────

  ┌────
  │ (global-set-key (kbd "M-i") 'pyim-convert-string-at-point)
  └────


12.8 如何使用其它字符翻页
─────────────────────────

  ┌────
  │ (define-key pyim-mode-map "." 'pyim-page-next-page)
  │ (define-key pyim-mode-map "," 'pyim-page-previous-page)
  └────


12.9 如何用 ";" 来选择第二个候选词
──────────────────────────────────

  ┌────
  │ (define-key pyim-mode-map ";"
  │   (lambda ()
  │     (interactive)
  │     (pyim-select-word-by-number 2)))
  └────


12.10 如何添加自定义拼音词库
────────────────────────────

  pyim 默认没有携带任何拼音词库，用户可以使用下面几种方式，获取质量较好
  的拼音词库：


12.10.1 第一种方式 (Windows 用户推荐使用)
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  使用词库转换工具将其他输入法的词库转化为 pyim 使用的词库：这里只介绍
  windows 平台下的一个词库转换软件：

  1. 软件名称： imewlconverter
  2. 中文名称： 深蓝词库转换
  3. 下载地址： <https://github.com/studyzy/imewlconverter>
  4. 依赖平台： Microsoft .NET Framework (>= 3.5)

  使用方式：

  <file:snapshots/imewlconverter-basic.gif>

  如果生成的词库词频不合理，可以按照下面的方式处理（非常有用的功能）：

  <file:snapshots/imewlconverter-wordfreq.gif>

  生成词库后，

  ┌────
  │ (require 'pyim-dict-manager)
  └────

  然后运行 `pyim-dicts-manager' ，按照命令提示，将转换得到的词库文件的信
  息添加到`pyim-dicts' 中，完成后运行命令 `pyim-restart' 或者重启emacs。


12.10.2 第二种方式 (Linux & Unix 用户推荐使用)
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  E-Neo 同学编写了一个词库转换工具: [scel2pyim] , 可以将一个搜狗词库转换
  为 pyim 词库。

  1. 软件名称： scel2pyim
  2. 下载地址： <https://github.com/E-Neo/scel2pyim>
  3. 编写语言： C语言


[scel2pyim] <https://github.com/E-Neo/scel2pyim>


12.10.3 第三种方式
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  可以了解：<https://github.com/redguardtoo/pyim-tsinghua-dict>


12.11 如何手动安装和管理词库
────────────────────────────

  这里假设有两个词库文件：

  1. /path/to/pyim-dict1.pyim
  2. /path/to/pyim-dict2.pyim

  在 ~/.emacs 文件中添加如下一行配置。

  ┌────
  │ (setq pyim-dicts
  │       '((:name "dict1" :file "/path/to/pyim-dict1.pyim")
  │         (:name "dict2" :file "/path/to/pyim-dict2.pyim")))
  └────

  注意事项:
  1. 只有 :file 是 *必须* 设置的。
  2. 必须使用词库文件的绝对路径。
  3. 词库文件的编码必须为 utf-8-unix，否则会出现乱码。


12.12 Emacs 启动时加载 pyim 词库
────────────────────────────────

  ┌────
  │ (add-hook 'emacs-startup-hook
  │           (lambda () (pyim-restart-1 t)))
  └────


12.13 将汉字字符串转换为拼音字符串
──────────────────────────────────

  下面两个函数可以将中文字符串转换的拼音字符串或者列表，用于 emacs-lisp
  编程。

  1. `pyim-cstring-to-pinyin' （尽可能处理多音字，但有可能得到多个拼音）
  2. `pyim-cstring-to-pinyin-simple' （尽可能处理多音字，但是只从可能的
     拼音中获取第一个拼音）


12.14 中文分词
──────────────

  pyim-cstring-utils 包含了一个简单的分词函数：
  `pyim-cstring-split-to-list', 可以将一个中文字符串分成一个词条列表，比
  如：

  ┌────
  │ (require 'pyim-cstring-utils)
  │ (pyim-cstring-split-to-list "我爱北京天安门")
  └────

  其中，每一个词条列表中包含三个元素，第一个元素为词条本身，第二个元素为
  词条相对于字符串的起始位置，第三个元素为词条结束位置。

  另一个分词函数是 `pyim-cstring-split-to-string', 这个函数将生成一个新
  的字符串，在这个字符串中，词语之间用空格或者用户自定义的分隔符隔开。

  注意，上述两个分词函数使用暴力匹配模式来分词，所以，*不能检测出* pyim
  词库中不存在的中文词条。


12.15 获取光标处的中文词条
──────────────────────────

  pyim-cstring-utils 包含了一个简单的命令：
  `pyim-cstring-words-at-point', 这个命令可以得到光标处的 *英文* 或者 *
  中文* 词条的 *列表*，这个命令依赖分词函数：
  `pyim-cstring-split-to-list'。


12.16 让 `forward-word' 和 `back-backward’ 在中文环境下正常工作
───────────────────────────────────────────────────────────────

  中文词语没有强制用空格分词，所以 Emacs 内置的命令 `forward-word' 和
  `backward-word' 在中文环境不能按用户预期的样子执行，而是
  forward/backward “句子”，pyim自带的两个命令可以在中文环境下正常工作：

  1. `pyim-forward-word
  2. `pyim-backward-word

  用户只需将其绑定到快捷键上就可以了，比如：

  ┌────
  │ (require 'pyim-cstring-utils)
  │ (global-set-key (kbd "M-f") 'pyim-forward-word)
  │ (global-set-key (kbd "M-b") 'pyim-backward-word)
  └────


12.17 为 isearch 相关命令添加拼音搜索支持
─────────────────────────────────────────

  pyim 安装后，可以通过下面的设置开启拼音搜索功能：

  ┌────
  │ (require 'pyim-cregexp-utils)
  │ (pyim-isearch-mode 1)
  └────

  注意：这个功能有一些限制，搜索字符串中只能出现 “a-z” 和 “'”，如果有其
  他字符（比如 regexp 操作符），则自动关闭拼音搜索功能。

  开启这个功能后，一些 isearch 扩展有可能失效，如果遇到这种问题，只能禁
  用这个 Minor-mode，然后联系 pyim 的维护者，看有没有法子实现兼容。

  用户激活这个 mode 后，可以使用下面的方式 *强制关闭* isearch 搜索框中文
  输入（即使在 pyim 激活的时候）。

  ┌────
  │ (setq-default pyim-english-input-switch-functions
  │               '(pyim-probe-isearch-mode))
  └────


12.18 创建一个搜索中文的 regexp
───────────────────────────────

  ┌────
  │ (pyim-cregexp-build ".*nihao.*")
  └────


12.19 让 ivy 支持拼音搜索候选项功能
───────────────────────────────────

  ┌────
  │ (require 'pyim-cregexp-utils)
  │ (setq ivy-re-builders-alist
  │       '((t . pyim-cregexp-ivy)))
  └────


12.20 让 avy 支持拼音搜索
─────────────────────────

  ┌────
  │ (with-eval-after-load 'avy
  │   (defun my-avy--regex-candidates (fun regex &optional beg end pred group)
  │     (let ((regex (pyim-cregexp-build regex)))
  │       (funcall fun regex beg end pred group)))
  │   (advice-add 'avy--regex-candidates :around #'my-avy--regex-candidates))
  └────


12.21 让 vertico, selectrum 等补全框架，通过 orderless 支持拼音搜索候选项功能。
───────────────────────────────────────────────────────────────────────────────

  ┌────
  │ (defun my-orderless-regexp (orig-func component)
  │   (let ((result (funcall orig-func component)))
  │     (pyim-cregexp-build result)))
  │ 
  │ (advice-add 'orderless-regexp :around #'my-orderless-regexp)
  └────


12.22 让 pyim 在 Termux Emacs 中正常工作
────────────────────────────────────────

  Pyim 在 Termux Emacs 中，可能遇到类似下面的报错：

  ┌────
  │ error in process sentinel: End of file during parsing
  └────

  这可能是 Termux Emacs 中的 emacs-async 包运行不正常导致的，全拼和双拼
  的用户可以使用 pyim-dregcache 后端，因为这个后端不需要 emacs-async 提
  供的功能。

  ┌────
  │ (require 'pyim-dregcache)
  │ (setq pyim-dcache-backend 'pyim-dregcache)
  └────

  形码用户暂时没有什么好办法，可以将其他设备上的 ~/.emacs.d/pyim/dcache
  目录拷贝到Termux Emacs 对应的目录，然后设置：

  ┌────
  │ (setq pyim-dcache-auto-update nil)
  └────
