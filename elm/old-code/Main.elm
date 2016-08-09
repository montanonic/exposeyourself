module Main exposing (..)

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onSubmit, on, keyCode)
import Array exposing (Array)
import Array.Extra as ArrayE
import Debug
import Dict exposing (Dict)
import Task exposing (Task)
import Time exposing (Time)
import Json.Decode as Json
import Ports
import String
import Style
import History exposing (EditorHistory, LineHistory)
import ArrayUtil as ArrayU
import StringUtil as StringU
import Update.Extra.Infix as UpdateE exposing ((:>))
import Platform.Cmd exposing ((!))


main =
    App.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


{-|

The `currentLine` field is required for properly subscribing to events which
send messages that must be line-aware. See the current subscription for more
context.

`debug` is used to conditionally run code that is useful for debugging, but that
shouldn't run in a normally-functioning app. Since Elm doesn't support macros,
there is a small runtime cost associated with checking to see if the debug field
is True, but the cost really ought to be trivial.
-}
type alias Model =
    { history : EditorHistory
    , debug : Bool
    }


ifDebug : Model -> (a -> a) -> a -> a
ifDebug model debugFunction val =
    if model.debug then
        debugFunction val
    else
        val


ifDebugLog : Model -> String -> a -> a
ifDebugLog model logMsg val =
    ifDebug model (Debug.log logMsg) val


init : ( Model, Cmd Msg )
init =
    ( Model
        History.init
        True
    , Cmd.none
    )


lineCharLimit : Int
lineCharLimit =
    20



-- UPDATE


{-|

Persist and NewLine both require knowledge of the LineIndex they are being
called on, as their behaviour is completely local to the current line.

PersistWithTime is called by the Persist message, and is what actually Persists
the data itself. The indirection is required because we need to query for the
current time when the Persist command is called, and as a side-effect, it is a
Command, which means we have to call the command, and then on the next event
loop we'll be able to use the current time in a message. Elm does not let us
perform side-effects in our code; it does the side-effects in its runtime and
sends us back the pure result.

CaretPosition is the location of the cursor caret along the editor line
currently in focus upon querying it.

-}
type Msg
    = NoOp
    | Persist LineIndex Content
    | PersistWithTime LineIndex Content Time
    | EnterToNewLine LineIndex (Maybe CaretPosition)
    | PersistNewLine LineIndex (Maybe ( Content, Content )) Time
    | Move Direction LineIndex
    | GetCaretPosition LineIndex CaretPosition
    | DeleteLine LineIndex
    | WrapWords LineIndex
    | WrapWordsThenPersist LineIndex Content
    | WrapWordsThenPersistWithTime LineIndex Content Time


type alias Content =
    String


type alias LineIndex =
    Int


type alias CaretPosition =
    Int


type Direction
    = Up
    | Down


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        {- this message is current fired `onInput` within the editor lines. the
           actual persistance part is handled by PersistWithTime (since we need Elm
           to fetch the current time before storing it). so the only change this
           makes to the model is simply keeping the values in `editorLines` up to
           date with the current models.
        -}
        Persist lineIndex text ->
            ( model
            , taskPerformSucceed (PersistWithTime lineIndex text) Time.now
            )
                |> ifDebugLog model "command to PersistWithTime"

        {- with the new model, diffing might be cheap enough to do entirely in
           Elm, and if so, the diffing should happen right here
        -}
        PersistWithTime lineIndex text time ->
            ( { model
                | history =
                    History.updateAt lineIndex
                        ( time, text )
                        model.history
              }
            , Cmd.none
            )
                |> ifDebugLog model "persisted with time"

        {-
           This message creates a new line, and moves all the content on the
              current line following the cursor position into the new line, and out of
              the current line. It then places the focus onto the new line, as user's
              would expect for the return/enter button in a text-editor.
        -}
        EnterToNewLine index caretPosition ->
            case caretPosition of
                {- If no caretPosition was supplied, query the current position.
                   See the CaretPosition message and `getCaretPosition` subscription
                   event, along with the port code in `main.html`.
                -}
                Nothing ->
                    ( model
                    , Ports.queryCaretPosition index
                    )

                Just position ->
                    let
                        _ =
                            ifDebugLog model "Just: index" index

                        currentContent =
                            History.currentContentAt index model.history
                                |> Maybe.withDefault ""
                                |> ifDebugLog model "currentContent"

                        {- split content at caret -}
                        ( newContent, nextLineContent ) =
                            ( String.left position currentContent
                            , String.dropLeft position currentContent
                            )
                                |> ifDebugLog model "( newContent, nextLineContent )"
                    in
                        ( { model
                            | history =
                                model.history
                                    |> History.insertLineAt (index + 1)
                                    |> ifDebugLog model "history-add-new-line"
                          }
                        , taskPerformSucceed
                            (PersistNewLine
                                index
                                {- has anything changed? -}
                                (if currentContent /= newContent then
                                    Just ( newContent, nextLineContent )
                                 else
                                    Nothing
                                )
                            )
                            Time.now
                        )

        PersistNewLine index maybeModifications now ->
            ( (case maybeModifications of
                Just ( thisLineContent, nextLineContent ) ->
                    { model
                        | history =
                            model.history
                                |> History.updateAt index ( now, thisLineContent )
                                |> History.updateAt (index + 1) ( now, nextLineContent )
                                |> ifDebugLog model "history-final"
                    }

                {- if no changes were made, don't update the history -}
                Nothing ->
                    model
                        |> ifDebugLog model "history-final"
              )
            , Ports.focusWithDelay ("#line-" ++ toString (index + 1))
            )

        GetCaretPosition currentLine caretPosition ->
            let
                _ =
                    ifDebugLog model "CaretPosition" caretPosition

                _ =
                    ifDebugLog model "CaretPosition: currentLine" currentLine
            in
                update (EnterToNewLine currentLine (Just caretPosition)) model

        Move direction lineIndex ->
            let
                focus index =
                    Ports.focus ("#line-" ++ (toString index))
            in
                case direction of
                    Up ->
                        ( model
                        , focus (lineIndex - 1)
                        )

                    Down ->
                        ( model
                        , focus (lineIndex + 1)
                        )

        DeleteLine index ->
            let
                content =
                    History.currentContentAt index model.history
            in
                if index /= 0 && content == Just "" then
                    ( { model
                        | history = History.deleteLineAt index model.history
                      }
                    , Ports.focus ("#line-" ++ (toString (index - 1)))
                    )
                else
                    ( model, Cmd.none )

        WrapWords index ->
            let
                content =
                    History.currentContentAt index model.history
                        |> Maybe.withDefault ""
                        |> ifDebugLog model "content"
            in
                if
                    (String.length content
                        |> ifDebugLog model "content length"
                    )
                        == lineCharLimit
                then
                    if
                        (String.length (String.trimRight content)
                            |> ifDebugLog model "timmed content"
                        )
                            == lineCharLimit
                    then
                        {- the line is at max capacity, with no whitespace at the end,
                           so we pop off the last word from the string and insert it
                           into the next line, creating a new line if none exists, and
                           cascading the changes down to further lines if adding the new
                           word causes more overflows
                        -}
                        let
                            ( contentSansWord, word ) =
                                StringU.splitOffLastWord content
                                    |> ifDebugLog model "( contentSansWord, word )"

                            {- get the content of the next line, if any -}
                            maybeNextLineContent =
                                History.currentContentAt (index + 1) model.history
                                    |> ifDebugLog model "maybeNextLineContent"

                            {- push the word onto the next line's content if it exists,
                               otherwise set a boolean flag telling us to create a new
                               line
                            -}
                            ( newLineIsNeeded, newNextLine ) =
                                case maybeNextLineContent of
                                    Nothing ->
                                        ( True, word )
                                            |> ifDebugLog model "( newLineIsNeeded, newNextLine )"

                                    Just nextLineContent ->
                                        ( False, word ++ " " ++ (String.trimLeft nextLineContent) )
                                            |> ifDebugLog model "( newLineIsNeeded, newNextLine )"

                            {- update the history to drop the word from the current line -}
                            ( newModel, cmd ) =
                                update (Persist index contentSansWord) model
                                    |> ifDebugLog model "( newModel, cmd )"
                        in
                            if newLineIsNeeded then
                                {- insert a new line and persist it with the word
                                   to wrap it
                                -}
                                { newModel
                                    | history =
                                        History.insertLineAt (index + 1) newModel.history
                                }
                                    ! [ cmd ]
                                    :> update (Persist (index + 1) newNextLine)
                                    |> ifDebugLog model "new line was needed"
                            else
                                {- add the word to the next line, wrapping that line
                                   if it overflows, and so on
                                -}
                                newModel
                                    ! [ cmd ]
                                    :> update (WrapWordsThenPersist (index + 1) newNextLine)
                                    |> ifDebugLog model "new line was not needed"
                    else
                        {- the line is at max capacity, with whitespace at the end,
                           so we trim the right-most whitespace
                        -}
                        ( { model
                            | history =
                                History.unsafeModifyCurrentContentAt
                                    index
                                    (String.trimRight content)
                                    model.history
                                    |> Maybe.withDefault model.history
                          }
                        , Cmd.none
                        )
                            |> ifDebugLog model "line was at max capacity"
                else
                    {- line is not at capacity, so no wrapping needed -}
                    ( model
                    , Cmd.none
                    )
                        |> ifDebugLog model "line was not at max capacity"

        WrapWordsThenPersist index content ->
            ( model
            , taskPerformSucceed
                (WrapWordsThenPersistWithTime index content)
                Time.now
            )

        WrapWordsThenPersistWithTime index content time ->
            model
                |> update (PersistWithTime index content time)
                :> update (WrapWords index)

        NoOp ->
            ( model
            , Cmd.none
            )


{-| Some Tasks explicitly cannot fail, but the Task.perform function always
requires a failure case. This function provides a dummy failure response for such
cases.
-}
taskPerformSucceed : (a -> msg) -> Task Never a -> Cmd msg
taskPerformSucceed =
    Task.perform never


never : Never -> a
never n =
    never n



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Ports.getCaretPosition (uncurry GetCaretPosition)



-- VIEW


onKeydown : (Int -> msg) -> Attribute msg
onKeydown tagger =
    on "keydown" (Json.map tagger keyCode)


{-| Keys are named using the conventions here:
https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/key

All of the values are contained in `keyCodes`, so if anything you need is
missing, add it there. If you use a code that does not exist, the result will
default to 0.
-}
key : String -> Int
key keyName =
    Dict.get keyName keyCodes
        |> Maybe.withDefault 0


keyCodes : Dict String Int
keyCodes =
    Dict.fromList
        [ ( "Backspace", 8 )
        , ( "Enter", 13 )
        , ( "ArrowUp", 38 )
        , ( "ArrowDown", 40 )
        ]


editorBehaviors : LineIndex -> Attribute Msg
editorBehaviors lineIndex =
    onKeydown
        (\k ->
            if k == key "Enter" then
                EnterToNewLine lineIndex Nothing
            else if k == key "Backspace" then
                DeleteLine lineIndex
            else if k == key "ArrowUp" then
                Move Up lineIndex
            else if k == key "ArrowDown" then
                Move Down lineIndex
            else
                NoOp
        )


{-| Need to create the appearance of a textarea by using a bunch of "lines",
   which will each actually be input fields. These will be components, and have to
   support dynamically adding/removing, and actions like pressing return behaving
   as they would in a standard editor. This is *very clearly* a hack, but that's
   what the entirety of the web seems to be. :)
-}
view : Model -> Html Msg
view model =
    div []
        [ div [] (renderEditor model.history)
        , renderHistory model.history
        ]


{-| The visually rendered editor is simply the most recent version of the each
line's history within the EditorHistory structure. Each line within the editor
must keep track of its index, as this allows it to send messages specific to
itself.
-}
renderEditorLine : LineIndex -> LineHistory -> Html Msg
renderEditorLine lineIndex lineHistory =
    input
        ((if lineIndex == 0 then
            [ placeholder "Expose Yourself" ]
          else
            []
         )
            ++ [ onInput (WrapWordsThenPersist lineIndex)
               , editorBehaviors lineIndex
               , value (History.currentLineContent lineHistory)
               , id ("line-" ++ toString lineIndex)
               , maxlength lineCharLimit
               , Style.textLine
               , type' "text"
               , attribute "inputmode" "latin-prose"
               ]
        )
        []


renderEditor : EditorHistory -> List (Html Msg)
renderEditor editorHistory =
    Array.indexedMap renderEditorLine editorHistory
        |> Array.toList


{-| Solely useful for debugging.
-}
renderHistory : EditorHistory -> Html Msg
renderHistory editorHistory =
    div []
        [ text
            (Array.map
                (List.map
                    (\( time, content ) -> content)
                )
                editorHistory
                |> Array.toList
                |> toString
            )
        ]
