au-themes (named after Au - the chemical symbol for Gold, representing
autism pride and acceptance) is a collection of sensory-safe,
psycho-optically calibrated Emacs themes designed specifically for autistic
individuals and neurodivergent sensory profiles.

Autistic visual perception frequently involves hyper-reactivity to
visual stimuli, including photophobia, pattern glare, foveal visual
crowding, and rapid visual fatigue.  Each theme in this collection is
checked by an automated test suite (tests/run-all-tests.el), among
other things for:

- APCA contrast bands for body text, syntax roles and comments,
  and WCAG 2.1 contrast ratio minima
- CIEDE2000 separation between syntax roles, also under simulated
  protan, deutan and tritan colour-vision deficiency
- luminance steps between adjacent syntax tokens (isoluminance)
- flanker contrast of brackets and delimiters (visual crowding)
- glare, straylight and pupil models of the whole viewport
- melanopic and blue-light weighted output

Each check states which of its limits come from a published standard
and which are the collection's own heuristics.