module Main exposing (..)

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Task exposing (Task)
import Array exposing (Array)
import Keyboard
import Array.Extra as ArrayE
import History exposing (EditorHistory, PositionHistory)
import DebugUtil exposing (ifDebugLog, ifDebug)
import Ports
import Style
import StringUtil as StringU
import Update.Extra.Infix as UpdateE exposing ((:>))
import Time exposing (Time)


main =
    App.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type alias Model =
    { history : EditorHistory
    , lastPosition : Int
    }


init : ( Model, Cmd Msg )
init =
    ( Model
        History.init
        0
    , Cmd.none
    )



-- UPDATE


{-|
-}
type Msg
    = NoOp
    | CaretPosition Int
    | CharAt Int String
    | Persist (Maybe ( Int, Char, Time ))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "message" msg of
        NoOp ->
            model ! []

        CaretPosition position ->
            let
                _ =
                    Debug.log "position" position

                updatedModel =
                    { model
                        | lastPosition =
                            position
                    }
            in
                if position > 0 then
                    {- add the just-inserted or altered character to the history -}
                    updatedModel ! [ Ports.queryCharAt (position - 1) ]
                else
                    let
                        _ =
                            Debug.log
                                "CaretPosition: position was out of bounds"
                                position
                    in
                        updatedModel ! []

        CharAt index charAsString ->
            let
                char =
                    case StringU.toChar charAsString of
                        Nothing ->
                            Debug.crash
                                ("string was not a single char: \""
                                    ++ charAsString
                                    ++ "\""
                                )

                        Just char ->
                            char

                _ =
                    Debug.log "(index, char)" ( index, char )
            in
                model
                    ! [ Task.perform
                            (\_ -> NoOp)
                            (\time -> Persist (Just ( index, char, time )))
                            Time.now
                      ]

        Persist data ->
            case data of
                Nothing ->
                    model ! [ Ports.queryCaretPosition () ]

                Just ( index, char, time ) ->
                    { model
                        | history =
                            History.updateAt
                                index
                                ( char, time )
                                model
                    }
                        ! []



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.caretPosition CaretPosition
        , Ports.charAt CharAt
        , Keyboard.downs
        ]



-- VIEW


view : Model -> Html Msg
view model =
    div [ Style.textareaContainer ]
        ([ textarea
            [ onInput (always (Persist Nothing))
            , id "editor"
            , Style.textarea
            ]
            []
         ]
            ++ (model.history
                    |> Array.indexedMap
                        (\i elem ->
                            div []
                                [ text
                                    ("index: `"
                                        ++ toString i
                                        ++ "` : "
                                        ++ toString elem
                                    )
                                ]
                        )
                    |> Array.toList
               )
        )
