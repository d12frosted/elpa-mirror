This package is a thin wrapper around Alectryon's editor support
(https://github.com/cpitclaudel/alectryon).  The idea is to easily switch
between a code-first and a text-first view of a literate file.

Concretely, Alectryon converts back and forth between this:

    =============================
     Writing decision procedures
    =============================

    Here's an inductive type:

    .. coq::

       Inductive Even : nat -> Prop :=
       | EvenO : Even O
       | EvenS : forall n, Even n -> Even (S (S n)).

    .. note::

       It has two constructors:

       .. coq:: unfold out

          Check EvenO.
          Check EvenS.

… and this:

    (*|
    =============================
     Writing decision procedures
    =============================

    Here's an inductive type:
    |*)

    Inductive Even : nat -> Prop :=
    | EvenO : Even O
    | EvenS : forall n, Even n -> Even (S (S n)).

    (*|
    .. note::

       It has two constructors:

       .. coq:: unfold out
    |*)

    Check EvenO.
    Check EvenS.
