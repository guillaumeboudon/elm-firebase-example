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
        newMaybeDatabase =
            (Database.update databaseMsg model.database)
    in
        case databaseMsg of
            Database.ReceiveUser user ->
                ( model |> setDatabase newMaybeDatabase
                , case model.auth of
                    Auth.Authenticated authUser ->
                        Database.databaseFetchTodos authUser.uid

                    _ ->
                        Cmd.none
                )

            Database.ReceiveTodos todos ->
                ( model |> setDatabase newMaybeDatabase
                , Cmd.none
                )

            Database.SaveUser user ->
                ( model
                    |> setDatabase newMaybeDatabase
                    |> setPage (Pages.TodoPage Nothing)
                , (case model.auth of
                    Auth.NotAuthenticated _ ->
                        Cmd.none

                    Auth.Authenticated authUser ->
                        case newMaybeDatabase of
                            Nothing ->
                                Cmd.none

                            Just newDatabase ->
                                Database.databaseSaveUser authUser.uid newDatabase.user
                  )
                )

            Database.SaveTodo todo ->
                ( model
                    |> setDatabase newMaybeDatabase
                    |> setPage (Pages.TodoPage Nothing)
                , (case model.auth of
                    Auth.NotAuthenticated _ ->
                        Cmd.none

                    Auth.Authenticated authUser ->
                        case newMaybeDatabase of
                            Nothing ->
                                Cmd.none

                            Just newDatabase ->
                                Database.databaseSaveTodos authUser.uid newDatabase.todos
                  )
                )


pagesUpdate : Pages.Msg -> Model -> ( Model, Cmd Msg )
pagesUpdate pagesMsg model =
    let
        newPage =
            Pages.update pagesMsg model.page
    in
        ( model |> setPage newPage
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
