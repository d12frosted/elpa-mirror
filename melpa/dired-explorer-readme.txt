[en]
This mode provides "Windows / Macintosh (Mac OS X) like file selection" for dired's buffer.
Move cursor by just pressing alphabet or number key.
And also it prohibits dired from opening many buffers.
of course, at this mode, cannot use dired's default keybind like "c".
You may use keybind that made of one alphabet, use with Meta (e.g. M-d).
toggle mode by ":".
This elisp is based on the original elisp that rubikichi introduced me
to at his Emacs school "Emacs Juku". He also gave me some advice on elisp.

[ja]
WindowsやMac OS Xのデフォルトのファイラのようなファイル選択をdiredで行います。
英数字のキーを打鍵するだけで、diredでファイル／ディレクトリを選択します。
また、diredがたくさんのバッファを開きすぎることを抑止しています。
当然ながら、このモードを有効にするとデフォルトのdiredのキーバインドが使えません。
diredのアルファベット一文字のキーバインドは基本的に"M-"にあて直しています。
モードの切り替えは":"で行ってください。
このelispは、かつて、るびきちさんが彼のEmacs塾で、もとになるElispを
紹介くださったものをもとにしています。また、彼はelispにアドバイスもくださいました。
