module Main exposing (..)

import Json.Decode as JD
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Modules.Auth as Auth
import Types exposing (..)


-- INIT


init : ( Model, Cmd Msg )
init =
    initialModel
        ! []



-- SUBSCRIPTIONS


decodeAuthLoggedIn : JD.Value -> Msg
decodeAuthLoggedIn value =
    case Auth.decodeAuthUser value of
        Nothing ->
            NoOp

        Just user ->
            AuthMsg (Auth.LoggedIn user)


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Auth.authLoggedIn decodeAuthLoggedIn
        , Auth.authLoggedOut (always (AuthMsg Auth.LoggedOut))
        ]



-- UPDATE


authUpdate : Auth.Msg -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
authUpdate authMsg ( model, cmdMsg ) =
    let
        ( newAuth, authCmdMsg ) =
            Auth.update authMsg model.auth
    in
        ( model
            |> setAuth newAuth
        , Cmd.batch
            [ cmdMsg
            , Cmd.map AuthMsg authCmdMsg
            ]
        )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        AuthMsg authMsg ->
            model
                ! []
                |> authUpdate authMsg



-- VIEW


view : Model -> Html.Html Msg
view model =
    case model.auth of
        Auth.NotAuthenticated authDetails ->
            div []
                [ h1 [] [ text "Not Authenticated" ]
                , input [ type_ "text", onInput (AuthMsg << Auth.InputEmail) ] []
                , input [ type_ "password", onInput (AuthMsg << Auth.InputPassword) ] []
                , button [ onClick (AuthMsg Auth.SignUp) ] [ text "Signup" ]
                , button [ onClick (AuthMsg Auth.LogIn) ] [ text "Login" ]
                ]

        Auth.Authenticated authUser ->
            div []
                [ h1 [] [ text "Authenticated" ]
                , button [ onClick (AuthMsg Auth.LogOut) ] [ text "Logout" ]
                ]



-- MAIN


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }
