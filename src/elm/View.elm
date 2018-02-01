module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Types exposing (..)
import Modules.Auth as Auth
import Modules.Pages as Pages


-- activeBodyView : Auth.AuthUser -> Model -> Html Msg
-- activeBodyView authUser model =
--     case model.database of
--         Nothing ->
--             div []
--                 [ h1 [] [ text "Create user" ]
--                 , input [ type_ "text", onInput (AuthMsg << Auth.InputEmail) ] []
--                 , input [ type_ "text", onInput (AuthMsg << Auth.InputEmail) ] []
--                 ]
--
--         Just database ->
--             div []
--                 [ h1 [] [ text "Authenticated" ]
--                 , button [ onClick (AuthMsg Auth.LogOut) ] [ text "Logout" ]
--                 , p [] [ text "Data fetched" ]
--                 ]
--
--
-- bodyView : Auth.AuthUser -> Model -> Html Msg
-- bodyView authUser model =
--     case model.status of
--         Loading ->
--             div [] [ text "..." ]
--
--         Active ->
--             activeBodyView authUser model
--
--
-- preventNotAuthAccess model =
--     case model.auth of
--         Auth.NotAuthenticated _ ->
--             model |> setRoute AuthPage
--
--         _ ->
--             model
--
--
-- validatedView model =
--     case model.page of
--
--         Auth.NotAuthenticated _ ->
--
--
--         Auth.Authenticated authUser ->
--             div []
--                 [ headerView
--                 , bodyView authUser model
--                 ]


contentView : Model -> Html Msg
contentView model =
    case model.page of
        Pages.WaitingPage ->
            div [] [ text "..." ]

        Pages.AuthPage ->
            div []
                [ h2 [] [ text "Authentication" ]
                , input [ type_ "text", onInput (AuthMsg << Auth.InputEmail) ] []
                , input [ type_ "password", onInput (AuthMsg << Auth.InputPassword) ] []
                , button [ onClick (AuthMsg Auth.SignUp) ] [ text "Signup" ]
                , button [ onClick (AuthMsg Auth.LogIn) ] [ text "Login" ]
                ]

        Pages.UserCreatePage user ->
            div []
                [ h2 [] [ text "User" ]
                , input [ type_ "text", onInput (PagesMsg << Pages.InputUserFirstName), placeholder "Prénom" ] []
                , input [ type_ "text", onInput (PagesMsg << Pages.InputUserLastName), placeholder "Nom" ] []
                , button [ onClick (PagesMsg Pages.CreateUser) ] [ text "Create user" ]
                ]

        Pages.TodoPage ->
            div [] [ h2 [] [ text "Todo" ] ]


headerView : Model -> Html Msg
headerView model =
    div
        [ style
            [ ( "background-color", "#AAA" )
            , ( "display", "flex" )
            , ( "flex-direction", "row" )
            ]
        ]
        (case model.auth of
            Auth.NotAuthenticated _ ->
                [ div
                    [ style [ ( "flex", "1" ) ] ]
                    [ h1 [] [ text "Not authenticated" ] ]
                ]

            Auth.Authenticated _ ->
                [ div [ style [ ( "flex", "1" ) ] ]
                    [ h1 [] [ text "Authenticated" ] ]
                , div []
                    [ button [ onClick (AuthMsg Auth.LogOut) ] [ text "Logout" ] ]
                ]
        )


view : Model -> Html.Html Msg
view model =
    div
        [ style
            [ ( "display", "flex" )
            , ( "flex-direction", "column" )
            ]
        ]
        [ headerView model
        , contentView model
        ]
