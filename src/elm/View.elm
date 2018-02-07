module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Maybe.Extra as Maybe
import Types exposing (..)
import Modules.Auth as Auth
import Modules.Database as Database
import Modules.Pages as Pages


todoPageView : Maybe Database.Todo -> Database.Todos -> Html Msg
todoPageView maybeCurrentTodo todos =
    let
        currentTodo =
            maybeCurrentTodo |> Maybe.withDefault (Database.newTodo -1)

        newTodoPartial =
            div []
                (if currentTodo.id == todos.uid then
                    [ input [ onInput (SetPage << Pages.TodoPage << Just << (Database.setTodoTitle currentTodo)) ] []
                    , button [ onClick (DatabaseMsg (Database.SaveTodo currentTodo)) ] [ text "Save" ]
                    ]
                 else
                    [ input [ onClick (SetPage (Pages.TodoPage (Just (Database.newTodo todos.uid)))), placeholder "Add a task...", value "" ] [] ]
                )

        todoPartial todo =
            div [ style [ ( "display", "flex" ), ( "flex-direction", "row" ) ] ]
                (if currentTodo.id == todo.id then
                    [ input [ onInput (SetPage << Pages.TodoPage << Just << (Database.setTodoTitle currentTodo)), value currentTodo.title ] []
                    , button [ onClick (DatabaseMsg (Database.SaveTodo currentTodo)) ] [ text "Save" ]
                    ]
                 else
                    [ div
                        [ style
                            [ ( "width", "150px" )
                            , ( "overflow", "hidden" )
                            , ( "white-space", "nowrap" )
                            , ( "text-overflow", "ellipsis" )
                            ]
                        ]
                        [ text todo.title ]
                    , button [ onClick (SetPage (Pages.TodoPage (Just todo))) ] [ text "Edit" ]
                    , button [ onClick (DatabaseMsg (Database.DeleteTodo todo.id)) ] [ text "Delete" ]
                    ]
                )
    in
        div []
            [ h2 [] [ text "Todo" ]
            , newTodoPartial
            , div []
                (todos.todos
                    |> List.reverse
                    |> List.map todoPartial
                )
            ]


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
                , button [ onClick (DatabaseMsg (Database.SaveUser user)) ] [ text "Create user" ]
                ]

        Pages.TodoPage maybeCurrentTodo ->
            todoPageView maybeCurrentTodo (model.database |> Maybe.unwrap Database.emptyTodos .todos)


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
        , div [ style [ ( "margin", "20px 50px" ) ] ] [ contentView model ]
        ]
