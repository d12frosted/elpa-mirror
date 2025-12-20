My-Whisper provides simple speech-to-text transcription using
Whisper.cpp.  It records audio via sox and transcribes it using
Whisper models, inserting the transcribed text at your cursor.

Features:
- Two transcription modes: fast (base.en) and accurate (medium.en)
- Custom vocabulary support for specialized terminology
- Automatic vocabulary length validation
- Async processing with process sentinels
- Clean temporary file management

Basic usage:
  M-x whisper-transcribe-fast  ; Fast mode (base.en model)
  M-x whisper-transcribe       ; Accurate mode (medium.en)

Configuration:
  Add to your init.el:
    (global-set-key (kbd "C-c v") #'whisper-transcribe-fast)
    (global-set-key (kbd "C-c n") #'whisper-transcribe)

See the README for installation and configuration details.
