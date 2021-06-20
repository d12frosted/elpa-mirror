Run and render SwiftUI blocks using org babel.

Install with:

  (require 'ob-swiftui)
  (ob-swiftui-setup)

Relevant header arguments:

`:results' window

  Runs SwiftUI in a separate window (default and can be omitted).

`:results' file

  Runs SwiftUI in the background and saves an image snapshot to
  a file.

`:view' FooView

  If `view:' is given, use FooView as the root view.  Otherwise,
  generate a root view and embed source block in body.

Examples:

  Use generated root view and render in external window (default):

    #+begin_src swiftui
      Rectangle()
        .fill(Color.yellow)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    #+end_src

    is equivalent to:

    #+begin_src swiftui :results window :view none
      Rectangle()
        .fill(Color.yellow)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    #+end_src

  Using your own root view:

    #+begin_src swiftui :results window :view FooView
      struct FooView: View {
        var body: some View {
          VStack(spacing: 10){
            BarView()
            BazView()
          }
        }
      }

      struct BarView: View {
        var body: some View {
          Rectangle()
            .fill(Color.yellow)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      }

      struct BazView: View {
        var body: some View {
          Rectangle()
            .fill(Color.blue)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      }
    #+end_src

; Requirements:

Depends on `swift-mode' for editing Swift code.
