
* INTRODUCTION:
  msvc parse the project file or the solution file of Visual Studio.
  msvc-mode becomes effective when you open the file belonging to a project.
  This mode provides the following features.

* FEATURES:
  - Visual Studio project file manager
    backend: msvc + ede
  - coexistence of different versions
    2019/2017/2015/2013/2012/2010
  - code completion (auto / manual)
    backend: ac-clang
    ac-sources: ac-clang or semantic
  - syntax check (auto / manual)
    backend: msbuild or ac-clang
  - jump to declaration or definition. return from jumped location.
    backend: ac-clang
  - jump to include file. return from jumped include file.
    backend: semantic
  - build Solution or Project on Emacs
    backend: msbuild
  - jump to error buffer from build report
    look like a grep buffer
  - launch Visual Studio from Solution or Project
    backend: Windows file association

* REQUIRED ENVIRONMENT
  - Microsoft Windows 64/32bit
    10/8/7/Vista
  - Microsoft Visual Studio Community/Professional/Enterprise
    2019/2017/2015/2013/2012/2010
  - Shell 64/32bit
    CYGWIN/MSYS/CMD(cmdproxy)
    CYGWIN's bash recommended

* REQUIRED EMACS LISP PACKAGE
  - ac-clang
    ac-clang provide code completion and arguments expand.
    This program consists of the client(elisp) and server(binary).
    The server is executable file, and a self-build is necessary.
    The server achieve code completion using libclang of LLVM.
    For ac-clang information and detailed usage,
    refer to header document of ac-clang.el or the project page.
    [https://github.com/yaruopooner/ac-clang]

* TESTED SDK:
  completion test, syntax check test
  - Windows SDK 7.1/7.0A
  - Direct X SDK(June 2010)
  - STL,std::tr1



Usage:
* DETAILED MANUAL:
  For more information and detailed usage, refer to the project page:
  [https://github.com/yaruopooner/msvc]

* INSTALLATION:
  If you use auto-complete by ac-clang, you will need an external program.
  It's necessary to download or self-build the external program.

  - download
    [https://github.com/yaruopooner/ac-clang/releases]
  - self-build
    [https://github.com/yaruopooner/llvm-build-shells]

* SETUP:
  (require 'msvc)

  (setq w32-pipe-read-delay 0)
  (when (msvc-initialize)
    (msvc-flags-load-db :parsing-buffer-delete-p t)
    (add-hook 'c-mode-common-hook #'msvc-mode-on t))

  For more samples, please refer the following URL.
  [https://github.com/yaruopooner/msvc/tree/master/minimal-config-sample]
  If you want to test a sample, please checkout.
  $ git clone https://github.com/yaruopooner/msvc.git
  Look at the file in 'msvc/minimal-config-sample' directory.

* REGISTRATION OF PROJECT OR SOLUTION
  (msvc-activate-projects-after-parse :solution-file "d:/DirectXSamples/SubD11/SubD11_2010.sln"
                                      :project-file "d:/DirectXSamples/SubD11/SubD11_2010.vcxproj"
                                      :platform "x64"
                                      :configuration "Release"
                                      :product-name "2019"
                                      :toolset 'x86_amd64
                                      :md5-name-p nil
                                      :force-parse-p nil
                                      :allow-cedet-p t
                                      :allow-ac-clang-p t
                                      :allow-flymake-p t
                                      :cedet-root-path "d:/DirectXSamples/SubD11"
                                      :cedet-spp-table nil
                                      :flymake-manually-p nil)

  When the project is active , buffer with the appropriate project name will be created.
  The project buffer name is based on the following format.
  *MSVC Project <`db-name`>*
  msvc-mode will be applied automatically when source code belonging to the project has been opened.
  msvc-mode has been applied buffer in the mode line MSVC`product-name`[platform|configuration] and will be displayed.
  You can activate a lot of projects.

* REQUIRED PROPERTIES
  - :solution-file
     If you don't use :project-file,
     all projects that are included in the Solution is parsed, it will be activated.
  - :project-file
     If you don't use :solution-file,
     Only the specified project is parsed, it will be activated.
     Feature associated with the Solution you will not be able to run.
  - :solution-file & :project-file
     You have the same effect as if you had specified a :solution-file only,
     but only a designated project will be parsed and activated.
     In the case that there are many projects in solution, this way is recommended.
  - :platform
     Must be a platform that exists in the project file.
  - :configuration
     Must be a configuration that exists in the project file.

* OPTIONAL PROPERTIES
  - :product-name
    Specifies the product-name of Visual Studio to be used.
    If you do not specify or nil used, the value used is `msvc-env-default-use-product-name'.
  - :toolset
    Specifies the toolset of Visual Studio to be used.
    If you do not specify or nil used, the value used is `msvc-env-default-use-toolset'.
  - :md5-name-p
    nil recommended.
    If value is t, generate a database directory and file name by MD5.
    This attribute solves a database absolute path longer than MAX_PATH(260 bytes).
  - :force-parse-p
    nil recommended. force parse and activate.
    It is primarily for debugging applications.
  - :allow-cedet-p
    t recommended. use the CEDET.
    In the case of nil you will not be able to use the jump to include files.
  - :allow-ac-clang-p
    t recommended.
    If value is t, use the ac-clang.
    If value is nil, use the semantic.
  - :allow-flymake-p
    t recommended. use the flymake. syntax check by MSBuild.
  - :cedet-root-path
    It is referenced only when the allow-cedet-p t.
    You specify the CEDET ede project base directory *.ede.
    File is generated in the specified directory.
    It is most likely not a problem in the directory where the project file is located.
    However, if the location of the source code is not a project file placement directory
    at the same level or descendants you will need to be careful.
    In this case you will need to specify a common parent directory such that the same hierarchy or descendants.
  - :cedet-spp-table
    nil recommended.
    It is referenced only when the allow-cedet-p t.
    Word associative table that you want to replace when the semantic is to parse the source.
    It is a table replacing define which cannot parsed a semantic.
    If semantic.cache can not be created successfully requires this setting.
    The following description sample
      :cedet-spp-table '(
                         ("ALIGN"              . "")
                         ("FORCE_INLINE"       . "")
                         ("NO_INLINE"          . "")
                         ("THREAD_LOCAL"       . "")
                         ("DLL_IMPORT"         . "")
                         ("DLL_EXPORT"         . "")
                         ("RESTRICT"           . ""))
    For details, refer to CEDET manual.
  - :flymake-back-end
    nil recommended.
    specifiable : `msbuild' `clang-server' `nil'
    refer to `msvc--flymake-back-end'
  - :flymake-manually-p
    nil recommended.
    If value is t, manual syntax check only.
  - :flymake-manually-back-end
    nil recommended.
    specifiable : `msbuild' `clang-server' `nil'
    refer to `msvc--flymake-manually-back-end'

* DEFAULT KEYBIND(msvc on Source Code Buffer)
  - start auto completion
    code completion & arguments expand
    `.` `->` `::`
  - start manual completion
    code completion & arguments expand
    `<TAB>`
  - jump to definition / return from definition
    this is nestable jump.
    target is type, function, enum, macro, include, misc.
    visit to definition file / return from definition file.
    `M-.` / `M-,`
  - visit to include file / return from include file(CEDET)
    `M-i` / `M-I`
  - goto error line prev / next
    `M-[` / `M-]`
  - manual syntax check
   `<f5>`
  - build solution
   `C-<f5>`

* DEFAULT KEYBIND(msvc on Project Buffer)
  - jump to buffer
    `RET` `mouse-1`
  - refer to buffer
    `C-z`

* DEFAULT KEYBIND(msvc on Build Report)
  - goto error line prev / next
    `[` / `]`
  - refer error line & buffer prev / next
    `M-[` / `M-]`
  - jump to buffer
    `RET` `mouse-1`
  - refer to buffer
    `C-z`
