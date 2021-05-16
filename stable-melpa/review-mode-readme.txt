"Re:VIEW" text editing mode

License:
  GNU General Public License version 3 (see COPYING) or any later version

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.


C-c C-a ユーザーから編集者へのメッセージ擬似マーカー
C-c C-k ユーザー注釈の擬似マーカー
C-c C-d DTP担当へのメッセージ擬似マーカー
C-c C-r 参照先をあとで確認する擬似マーカー
C-c !   作業途中の擬似マーカー
C-c C-t 1 作業者名の変更
C-c C-t 2 DTP担当の変更

C-c C-e 選択範囲をブロックタグで囲む。選択されていない場合は新規に挿入する。新規タブで補完可
C-c C-o 選択範囲を //beginchild 〜 //endchild で囲む
C-c C-f C-f 選択範囲をインラインタグで囲む。選択されていない場合は新規に挿入する。タブで補完可
C-c C-f b 太字タグ(@<b>)で囲む
C-c C-f C-b 同上
C-c C-f k キーワードタグ(@<kw>)で囲む
C-c C-f C-k キーワードタグ(@<kw>)で囲む
C-c C-f i イタリックタグ(@<i>)で囲む
C-c C-f C-i 同上
C-c C-f e 同上 (review-use-em tの場合は@<em>)
C-c C-f C-e 同上 (review-use-em tの場合は@<em>)
C-c C-f s 強調タグ(@<strong>)で囲む
C-c C-f C-s 同上
C-c C-f t 等幅タグ(@<tt>)で囲む
C-c C-f C-t 同上
C-c C-f u 同上
C-c C-f C-u 同上
C-c C-f a 等幅イタリックタグ(@<tti>)で囲む
C-c C-f C-a 同上
C-c C-f C-h ハイパーリンクタグ(@<href>)で囲む
C-c C-f C-c コードタグ(@<code>)で囲む
C-c C-f m 数式タグ(@<m>)で囲む
C-c C-f C-m 同上
C-c C-f C-n 出力付き索引化(@<idx>)する

C-c C-p =見出し挿入(レベルを指定)
C-c C-b 吹き出しを入れる
C-c CR  隠し索引(@<hidx>)を入力して入れる
C-c C-w 選択範囲を隠し索引(@<hidx>)にして範囲の前に入れる
C-c ,   @<br>{}を挿入
C-c <   rawのHTML開きタグを入れる
C-c >   rawのHTML閉じタグを入れる

C-c 1   近所のURIを検索してブラウザを開く
C-c 2   範囲をURIとしてブラウザを開く
C-c (   全角(
C-c 8   同上
C-c )   全角)
C-c 9   同上
C-c [   【
C-c ]    】
C-c -    全角ダーシ
C-c +    全角＋
C-c *    全角＊
C-c /    全角／
C-c =    全角＝
C-c \    ￥
C-c SP   全角スペース
C-c :    全角：
