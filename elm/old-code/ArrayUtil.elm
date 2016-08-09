module ArrayUtil exposing (..)

import Array exposing (Array)


{-| Insert an element at the zero-based (0 == first element) index in the array,
pushing the current element at that index (and all after it, if any) up one
position. If the index is out of bounds of the Array, the element will be pushed
to the end of the Array.

to test the function out, add something like this to the view:

`div [] [ text << String.concat << Array.toList
    <| Array.map toString (arrayInsertAt 1 9 (Array.fromList [ 1, 2, 3 ])) ]`
-}
insertAt : Int -> a -> Array a -> Array a
insertAt index elem arr =
    let
        len =
            Array.length arr
    in
        if index < 0 || index >= len then
            Array.push elem arr
        else
            let
                ( a1, a2 ) =
                    ( Array.slice 0 index arr, Array.slice index len arr )
            in
                {- push the elem to the end of a1 then append the new a1 with a2,
                   resulting in insertion at the index
                -}
                Array.append (Array.push elem a1) a2


{-| Gets the last element of an array, returning Nothing if the array was empty.
-}
last : Array a -> Maybe a
last arr =
    Array.get (Array.length arr - 1) arr
