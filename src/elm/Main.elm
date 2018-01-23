module Main exposing (..)

import Json.Decode as JD
import Html
import Modules.Auth as Auth
import Modules.Database as Database
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
    case value |> Database.decodeDatabase of
        Err _ ->
            SetActiveStatus

        Ok database ->
            DatabaseMsg (Database.ReceiveData database)


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
                    |> setStatus Loading
                , Cmd.batch
                    [ Cmd.map AuthMsg authCmdMsg
                    , Database.databaseFetchData authUser.uid
                    ]
                )

            Auth.LoggedOut ->
                ( model
                    |> setAuth newAuth
                    |> setDatabase Nothing
                    |> setStatus Active
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
        ( model
            |> setDatabase newMaybeDatabase
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

        SetActiveStatus ->
            ( model |> setStatus Active
            , Cmd.none
            )



-- MAIN


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }
