module Main exposing (..)

import Html


-- MODEL


type alias Model =
    { message : String }


init : ( Model, Cmd Msg )
init =
    Model "Welcome elm!" ! []



-- UPDATE


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []



-- VIEW


view : Model -> Html.Html Msg
view model =
    Html.text model.message



-- MAIN


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , subscriptions = always Sub.none
        , update = update
        , view = view
        }
