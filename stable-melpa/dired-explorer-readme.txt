[en]
Select files and directories in Dired by typing lowercase letters or digits,
as in Windows Explorer or macOS Finder.
Loading this package leaves the mode disabled and preserves Dired's keymap.
Use M-x dired-explorer-mode to toggle it in the current Dired buffer.
While enabled, lowercase letters and digits select files instead of running
their usual Dired commands.  Uppercase letters (such as M to change file
permissions) and punctuation retain their usual bindings by default.
To use Dired commands while dired-explorer-mode is enabled, bind them to
modifier-key combinations of your choice, taking care not to overwrite
existing bindings.  For example:
(define-key dired-explorer-mode-map (kbd "M-m") #'dired-mark)
The mode also binds M-g to refresh and M-o to open in another window.
This elisp is based on the original elisp that rubikichi introduced me
to at his Emacs school "Emacs Juku". He also gave me some advice on elisp.

[ja]
WindowsのExplorerやmacOSのFinderのように、小文字の英字と数字を入力して、
Diredでファイルやディレクトリを選択します。
読み込むだけではモードは有効にならず、Diredのキーマップも変更しません。
M-x dired-explorer-mode で、現在のDiredバッファでの有効・無効を切り替えます。
有効にすると、小文字の英字と数字は通常のDired操作の代わりにファイル選択に
使われます。デフォルトでは、大文字（パーミッションを変更する M など）や
記号の通常のキー操作は引き続き使えます。
dired-explorer-modeの有効時にも使いたいDired操作は、
既存の割り当てとの重複に注意して、
モディファイアキーとの組み合わせなどに設定してください。
例:
(define-key dired-explorer-mode-map (kbd "M-m") #'dired-mark)
このほか、有効時はM-gで再表示、M-oで別ウィンドウに開く操作を使えます。
このelispは、かつて、るびきちさんが彼のEmacs塾で、もとになるElispを
紹介くださったものをもとにしています。また、彼はelispにアドバイスもくださいました。
