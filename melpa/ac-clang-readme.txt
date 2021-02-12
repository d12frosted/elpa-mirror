
* INTRODUCTION:
  This program fork from auto-complete-clang-async.el
  ac-clang provide code completion and arguments expand.
  This program consists of the client(elisp) and server(binary).
  The server is executable file, and a self-build is necessary.
  The server achieve code completion using libclang of LLVM.

* FEATURES:
  - Basic(same auto-complete-clang-async)
    Code Completion by libclang.
    Auto Completion support.
    Uses a "completion server" process to utilize libclang.
    C/C++/Objective-C mode support.
    Jump to definition or declaration. return from jumped location.
    Jump is an on-the-fly that doesn't use the tag file.
    Also provides flymake syntax checking.
    A few bugfix and refactoring.

  - Extension
    "completion server" process is 1 process per Emacs. (original version is per buffer)
    Template Parameters expand.
    Manual Completion.
    Display Brief Comment of completion candidate.
    libclang CXTranslationUnit Flags support.
    libclang CXCodeComplete Flags support.
    Multibyte support.
    Jump to inclusion-file. return from jumped location.
    IPC packet format can be specified.
    Debug Logger Buffer.
    Performance Profiler.
    more a few modified. (client & server)

  - Optional
    CMake support.
    clang-server.exe and libclang.dll built with Microsoft Visual Studio 2017/2015/2013.
    x86_64 Machine Architecture + Windows Platform support. (Visual Studio Predefined Macros)

* EASY INSTALLATION(Windows Only):
  - Visual C++ Redistributable Packages for Visual Studio 2017/2015/2013
    Must be installed if don't have a Visual Studio 2017/2015/2013.

    - 2017
      [https://www.visualstudio.com/downloads/?q=#other]
    - 2015
      [http://www.microsoft.com/download/details.aspx?id=53587]
    - 2013/2012/2010/2008
      [http://www.standaloneofflineinstallers.com/2015/12/Microsoft-Visual-C-Redistributable-2015-2013-2012-2010-2008-2005-32-bit-x86-64-bit-x64-Standalone-Offline-Installer-for-Windows.html]

  - Completion Server Program
    Built with Microsoft Visual Studio 2017/2015/2013.
    [https://github.com/yaruopooner/ac-clang/releases]
    1. download clang-server.zip
    2. clang-server.exe and libclang.dll is expected to be available in the PATH or in Emacs' exec-path.

* STANDARD INSTALLATION(Linux, Windows):
  Generate a Unix Makefile or a Visual Studio Project by CMake.

  - Self-Build step
    1. LLVM
       checkout, apply patch, generate project, build
       It is recommended that you use this shell.
       [https://github.com/yaruopooner/llvm-build-shells.git]

    2. Clang Server
       generate project, build

    see clang-server's reference manual.
    ac-clang/clang-server/readme.org

* NOTICE:
  - LLVM libclang.[dll, so, ...]
    This binary is not official binary.
    Because offical libclang has mmap lock problem.
    Applied a patch to LLVM's source code in order to solve this problem.

    see clang-server's reference manual.
    ac-clang/clang-server/readme.org



Usage:
* DETAILED MANUAL:
  For more information and detailed usage, refer to the project page:
  [https://github.com/yaruopooner/ac-clang]

* SETUP:
  (require 'ac-clang)

  ;; Windows Only
  (when (eq system-type 'windows-nt)
    (setq w32-pipe-read-delay 0))

  (when (ac-clang-initialize)
    (add-hook 'c-mode-common-hook '(lambda ()
                                     (setq clang-server-cflags CFLAGS)
                                     (ac-clang-activate-after-modify))))

* DEFAULT KEYBIND
  - start auto completion
    code completion & arguments expand
    `.` `->` `::`
  - start manual completion
    code completion & arguments expand
    `<tab>`
  - jump to inclusion-file, definition, declaration / return from it
    this is nestable jump.
    `M-.` / `M-,`
