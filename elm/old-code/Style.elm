module Style exposing (..)

{-| All app styles are contained here.
-}

import Html.Attributes
import Css exposing (..)


{-| Convert from the Css package to the elm-html CSS format, in order to embed
CSS styles directly into the HTML.
-}
styles =
    Css.asPairs >> Html.Attributes.style


textAreaContainer =
    styles
        [ position absolute
        , left (pct 25)
        , top (pct 25)
        ]


textArea =
    styles
        [ width (px 400)
        , height (px 400)
        ]


textLine =
    styles
        [ width (px 900)
        , height (em 1.2)
        , fontFamily monospace
        ]
