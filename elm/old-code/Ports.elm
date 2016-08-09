port module Ports exposing (..)


port focus : String -> Cmd msg


port focusWithDelay : String -> Cmd msg


port queryCaretPosition : Int -> Cmd msg


port getCaretPosition : (( Int, Int ) -> msg) -> Sub msg
