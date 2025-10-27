This package provides Text-to-Speech (TTS) functionality for Emacs, enabling
users to convert textual content into audio playback. It supports streaming
TTS by splitting text into sentences and processing them sequentially,
allowing for smooth audio generation and playback without blocking Emacs.

To use this package, first ensure the required external dependencies are
available: a TTS backend server (by default, Kokoro running in a Podman
container) and an audio player (by default, ffplay). Start the backend server
using `tts-kokoro-start-server', which launches a local Kokoro TTS service on
the configured port (`tts-kokoro-port' - default 8880).  Select text in a
buffer and call `tts-read' to initiate TTS playback; it handles the entire
region or buffer if no region is active. You may also provide a string
argument to it instead.  Stop ongoing playback with `tts-stop'.  Customize
voices and speed using `tts-kokoro-set-voice' and `tts-kokoro-set-speed';
prefix arguments make settings buffer-local.  Customize the port via
`tts-kokoro-port'.  Logs and process outputs appear in the *tts-log* buffer
for debugging.  If `tts-enable-automode' is non-nil (the default), `tts-mode'
will be automatically enabled when starting playback to display a header-line
with progress and controls. Otherwise, you can manually enable `tts-mode' if
desired.

To extend this package, add new backends by defining generation functions
(e.g., like `tts--kokoro-generate-audio') and updating
`tts-backend-generate-function-alist'. Similarly, for frontends, define
playback functions (e.g., like `tts--ffplay-play-audio') and update
`tts-frontend-play-function-alist'. Ensure new backends and frontends
implement the expected callback interface for asynchronous processing.  For
backend-specific UI controls in the header line, define a UI function (e.g.,
like `tts--kokoro-ui-controls') and update
`tts-backend-ui-controls-function-alist'. For preprocessing, define
transformation functions (e.g., like `tts--preprocess-org-links') and add
them to `tts-preprocessing-functions'.  These apply per sentence before TTS
generation.

You can find more information about Kokoro in this URL:
https://huggingface.co/hexgrad/Kokoro-82M
And its packaging into a container is provided by:
https://github.com/remsky/Kokoro-FastAPI
