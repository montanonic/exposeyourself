module History exposing (..)

import Array exposing (Array)
import Array.Extra as ArrayE
import Debug
import Time exposing (Time)


type alias EditorHistory =
    Array PositionHistory


{-| The modification history for a particular position within the text.
-}
type alias PositionHistory =
    List ( Char, Time )


init : EditorHistory
init =
    Array.initialize 1 (always [])


{-| Possibly gets the PositionHistory at the given index in the
EditorHistory.
-}
getPositionHistory : Int -> { a | history : EditorHistory } -> Maybe PositionHistory
getPositionHistory index { history } =
    Array.get index history


{-|
-}
updateAt : Int -> ( Char, Time ) -> { a | history : EditorHistory } -> EditorHistory
updateAt index modification { history } =
    let
        maxIndex =
            (Array.length history) - 1
    in
        if index <= maxIndex then
            {- index is within bounds -}
            ArrayE.update index
                (\list -> modification :: list)
                history
        else if index == maxIndex + 1 then
            {- index is immediately outside the upper bound, so push a new
               element onto the history, extending it
            -}
            updateAt index modification { history = Array.push [] history }
        else
            Debug.crash
                ("Index `"
                    ++ toString index
                    ++ "` was more than 1 size larger than the maxIndex of `"
                    ++ toString maxIndex
                    ++ "` "
                )
