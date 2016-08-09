port module Ports exposing (..)


port queryCaretPosition : () -> Cmd msg


port caretPosition : (Int -> msg) -> Sub msg


port queryCharAt : Int -> Cmd msg


port charAtUncurried : (( Int, String ) -> msg) -> Sub msg


charAt : (Int -> String -> msg) -> Sub msg
charAt f =
    charAtUncurried (uncurry f)
