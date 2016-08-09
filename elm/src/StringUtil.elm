module StringUtil exposing (..)

import String


{-| Converts a Char stored as a String to a proper Char. Returns Nothing if the
provided String contains anything other than a single character.
-}
toChar : String -> Maybe Char
toChar s =
    case String.uncons s of
        Just ( char, rest ) ->
            if String.isEmpty rest then
                Just char
            else
                Nothing

        Nothing ->
            Nothing
