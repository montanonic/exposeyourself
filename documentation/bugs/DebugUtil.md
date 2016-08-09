## Odd compiler error

When using either function defined within the module within the Main update
function:

```
The type annotation for `update` does not match its definition.

60| update : Msg -> Model -> ( Model, Cmd Msg )
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
The type annotation is saying:

    elm-make: Used toSrcType on a type that is not well-formed
```
