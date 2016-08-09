module StringUtil exposing (..)

import String


{-| Takes a String and splits off the last word from the String, returning a
tuple of the new string, and the word. If the string has any whitespace at the
end, each whitespace character will be considered a word.

I should probably write my own String iterator functions, and re-express the
code here. This will make it (1) easier to read, and (2) more performant due to
being able to short-circuit.

On second thought: some of this should just be rewritten as Native JS code. I'll
get to that later though.
-}
splitOffLastWord : String -> ( String, String )
splitOffLastWord string =
    let
        {- Folds unfortunately don't support short-circuit semantics in Elm. :( -}
        reducer char ( done, acc ) =
            if not done then
                {- accumulate characters that aren't space -}
                if char /= ' ' then
                    ( False, String.cons char acc )
                    {- until a space character is reached, at which point we're done -}
                else
                    ( True, acc )
            else
                {- in a language which supported imperative semantics, we'd use a
                   return statement here; unfortunately, we must still traverse the
                   rest of the structure in Elm.
                -}
                ( True, acc )
    in
        let
            word =
                snd <| String.foldr reducer ( False, "" ) string

            newString =
                {- remove any whitespace left after the word -}
                String.dropRight (String.length word) string
                    |> String.trimRight
        in
            ( newString, word )



{-
   {-| Take elements from the right of a String until the predicate matches. -}
   takeRightUntil : (Char -> Bool) -> String -> String
   takeRightUntil predicate string =
-}
