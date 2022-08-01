R with tree-sitter

(require 'tree-sitter-ess-r)
(add-hook 'ess-r-mode-hook 'tree-sitter-ess-r-mode-activate)
or
M-x tree-sitter-ess-r-using-r-faces


Make tree-sitter to support r

Linux
1. git clone https://github.com/r-lib/tree-sitter-r.git
2. gcc ./src/parser.c ./src/scanner.cc -lstdc++ -fPIC -I./ -I./src/ -I./src/tree_sitter --shared -o r.so
3. cp ./r.so /path/to/tree-sitter-langs/langs/bin (/path/to/tree-sitter-langs/ is path of your tree-sitter-langs package)
4. mkdir /path/to/tree-sitter-langs/queries/r
5. cp ./queries/* /path/to/tree-sitter-langs/queries/r


Windows (MINGW64)
1. git clone https://github.com/r-lib/tree-sitter-r.git
2. gcc ./src/parser.c ./src/scanner.cc -lstdc++ -fPIC -I./ -I./src/ -I./src/tree_sitter --shared -o r.dll
3. cp ./r.dll /path/to/tree-sitter-langs/langs/bin (/path/to/tree-sitter-langs/ is path of your tree-sitter-langs package)
4. mkdir /path/to/tree-sitter-langs/queries/r
5. cp ./queries/* /path/to/tree-sitter-langs/queries/r
