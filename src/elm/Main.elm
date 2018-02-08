module Main exposing (..)

import Json.Decode as JD
import Html
import Modules.Auth as Auth
import Modules.Database as Database
import Modules.Pages as Pages
import Types exposing (..)
import View exposing (..)


-- INIT


init : ( Model, Cmd Msg )
init =
    initialModel
        ! []



-- SUBSCRIPTIONS


decodeAuthLoggedIn : JD.Value -> Msg
decodeAuthLoggedIn value =
    case value |> Auth.decodeAuthUser of
        Err _ ->
            NoOp

        Ok user ->
            AuthMsg (Auth.LoggedIn user)


decodeDatabaseReceiveData : JD.Value -> Msg
decodeDatabaseReceiveData value =
    case value |> Database.extractDataAndTarget of
        Nothing ->
            SetPage (Pages.UserCreatePage Database.emptyUser)

        Just ( dataTarget, data ) ->
            case dataTarget of
                Database.UserTarget ->
                    case data |> JD.decodeValue Database.userDecoder of
                        Err _ ->
                            SetPage (Pages.UserCreatePage Database.emptyUser)

                        Ok user ->
                            DatabaseMsg (Database.ReceiveUser user)

                Database.TodosTarget ->
                    case data |> JD.decodeValue Database.todosDecoder of
                        Err _ ->
                            SetPage (Pages.TodoPage Nothing)

                        Ok todos ->
                            DatabaseMsg (Database.ReceiveTodos todos)

                _ ->
                    NoOp


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Auth.authLoggedIn decodeAuthLoggedIn
        , Auth.authLoggedOut (always (AuthMsg Auth.LoggedOut))
        , Database.databaseReceiveData decodeDatabaseReceiveData
        ]



-- UPDATE


authUpdate : Auth.Msg -> Model -> ( Model, Cmd Msg )
authUpdate authMsg model =
    let
        ( newAuth, authCmdMsg ) =
            Auth.update authMsg model.auth
    in
        case authMsg of
            Auth.LoggedIn authUser ->
                ( model
                    |> setAuth newAuth
                    |> setPage (Pages.TodoPage Nothing)
                , Cmd.batch
                    [ Cmd.map AuthMsg authCmdMsg
                    , Database.databaseFetchUser authUser.uid
                    ]
                )

            Auth.LoggedOut ->
                ( model
                    |> setAuth newAuth
                    |> setDatabase Nothing
                    |> setPage Pages.AuthPage
                , Cmd.map AuthMsg authCmdMsg
                )

            _ ->
                ( setAuth newAuth model
                , Cmd.map AuthMsg authCmdMsg
                )


databaseUpdate : Database.Msg -> Model -> ( Model, Cmd Msg )
databaseUpdate databaseMsg model =
    let
        database =
            case model.database of
                Nothing ->
                    Database.emptyDatabase

                Just database ->
                    database

        newDatabase =
            Database.update databaseMsg database
    in
        case model.auth of
            Auth.NotAuthenticated _ ->
                model ! []

            Auth.Authenticated authUser ->
                case databaseMsg of
                    Database.ReceiveUser _ ->
                        ( model |> setDatabase (Just newDatabase)
                        , Database.databaseFetchTodos authUser.uid
                        )

                    Database.ReceiveTodos _ ->
                        ( model |> setDatabase (Just newDatabase)
                        , Cmd.none
                        )

                    Database.SaveUser _ ->
                        ( model
                            |> setDatabase (Just newDatabase)
                            |> setPage (Pages.TodoPage Nothing)
                        , Database.databaseSaveUser authUser.uid newDatabase.user
                        )

                    Database.SaveTodo _ ->
                        ( model
                            |> setDatabase (Just newDatabase)
                            |> setPage (Pages.TodoPage Nothing)
                        , Database.databaseSaveTodos authUser.uid newDatabase.todos
                        )

                    Database.DeleteTodo _ ->
                        ( model
                            |> setDatabase (Just newDatabase)
                            |> setPage (Pages.TodoPage Nothing)
                        , Database.databaseSaveTodos authUser.uid newDatabase.todos
                        )

                    Database.ToggleTodoState _ ->
                        ( model
                            |> setDatabase (Just newDatabase)
                            |> setPage (Pages.TodoPage Nothing)
                        , Database.databaseSaveTodos authUser.uid newDatabase.todos
                        )


pagesUpdate : Pages.Msg -> Model -> ( Model, Cmd Msg )
pagesUpdate pagesMsg model =
    ( model |> setPage (Pages.update pagesMsg model.page)
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        AuthMsg authMsg ->
            model |> authUpdate authMsg

        DatabaseMsg databaseMsg ->
            model |> databaseUpdate databaseMsg

        SetPage page ->
            ( model |> setPage page
            , Cmd.none
            )

        PagesMsg pagesMsg ->
            model |> pagesUpdate pagesMsg



-- MAIN


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }
