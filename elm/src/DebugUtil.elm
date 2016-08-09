module DebugUtil exposing (..)

import Debug


ifDebug : { a | debug : Bool } -> (a -> a) -> a -> a
ifDebug { debug } debugFunc val =
    if debug then
        debugFunc val
    else
        val


{-| If a `debug` flag within the model is set to true, log the given value with
the given message, and return the value.
-}
ifDebugLog : { a | debug : Bool } -> String -> a -> a
ifDebugLog model logMsg val =
    if model.debug then
        Debug.log logMsg val
    else
        val
