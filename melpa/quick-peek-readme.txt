A utility library to display inline pop-ups.  Looks roughly like this:


let _ = <|>le m n                           ← <|> marks the point
------------------------------------------- ← Pop-up begins here
        le : ℕ → ℕ → ℙ
        Inductive le (n : ℕ) : ℕ → ℙ ≜
        | le_n : n ≤ n
        | le_S : ∀ m : ℕ, n ≤ m → n ≤ S m
------------------------------------------- ← Pop-up ends here
        && le n m                           ← Buffer text continues here

See `quick-peek-show' and `quick-peek-hide' for usage instructions.
