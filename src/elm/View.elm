module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Types exposing (..)
import Modules.Auth as Auth


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
            case model.database of
                Nothing ->
                    div []
                        [ h1 [] [ text "Authenticated" ]
                        , h2 [] [ text "Signed up user" ]
                        , button [ onClick (AuthMsg Auth.LogOut) ] [ text "Logout" ]
                        ]

                Just database ->
                    div []
                        [ h1 [] [ text "Authenticated" ]
                        , h2 [] [ text "Logged in user" ]
                        , button [ onClick (AuthMsg Auth.LogOut) ] [ text "Logout" ]
                        ]
