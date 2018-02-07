port module Modules.Database exposing (..)

import Json.Decode as JD
import Json.Decode.Extra exposing ((|:))
import Json.Encode as JE


-- MODEL
{- Structure -}


type alias User =
    { firstName : String
    , lastName : String
    }


type TodoState
    = Pending
    | Done


type alias Todo =
    { title : String
    , state : TodoState
    }


type alias Database =
    { user : User
    , todos : List Todo
    }



{- Initializers -}


emptyUser : User
emptyUser =
    User "" ""



{- Setters -}


setUser : User -> { a | user : User } -> { a | user : User }
setUser user database =
    { database | user = user }


setTodos : List Todo -> { a | todos : List Todo } -> { a | todos : List Todo }
setTodos todos database =
    { database | todos = todos }



-- FUNCTIONS


type DataTarget
    = UserTarget
    | TodosTarget
    | WrongTarget


decodeDataTarget : String -> DataTarget
decodeDataTarget target =
    if target == "user" then
        UserTarget
    else if target == "todos" then
        TodosTarget
    else
        WrongTarget


type alias DataContainer =
    { uid : String
    , target : String
    , data : Maybe JE.Value
    }


databaseFetchUser : String -> Cmd msg
databaseFetchUser uid =
    DataContainer uid "user" Nothing
        |> databaseFetchData


databaseFetchTodos : String -> Cmd msg
databaseFetchTodos uid =
    DataContainer uid "todos" Nothing
        |> databaseFetchData


databaseSaveUser : String -> User -> Cmd msg
databaseSaveUser uid user =
    DataContainer uid "user" (Just (user |> userEncoder))
        |> databaseSaveData


extractDataAndTarget : JD.Value -> Maybe ( DataTarget, JD.Value )
extractDataAndTarget value =
    case value |> decodeDataContainer of
        Err _ ->
            Nothing

        Ok dataContainer ->
            Just
                ( dataContainer.target |> decodeDataTarget
                , (case dataContainer.data of
                    Nothing ->
                        JE.object []

                    Just data ->
                        data
                  )
                )



-- PORTS


port databaseFetchData : DataContainer -> Cmd msg


port databaseReceiveData : (JD.Value -> msg) -> Sub msg


port databaseSaveData : DataContainer -> Cmd msg



-- UPDATE


type Msg
    = ReceiveUser User


update : Msg -> Maybe Database -> Maybe Database
update databaseMsg maybeDatabase =
    case databaseMsg of
        ReceiveUser user ->
            case maybeDatabase of
                Nothing ->
                    Just (Database user [])

                Just database ->
                    Just (database |> setUser user)



-- ENCODERS


userEncoder : User -> JE.Value
userEncoder user =
    JE.object
        [ ( "firstName", JE.string user.firstName )
        , ( "lastName", JE.string user.lastName )
        ]



-- DECODERS


userDecoder : JD.Decoder User
userDecoder =
    JD.succeed User
        |: (JD.field "firstName" JD.string)
        |: (JD.field "lastName" JD.string)


todoStateDecoder : String -> JD.Decoder TodoState
todoStateDecoder value =
    case value of
        "pending" ->
            JD.succeed Pending

        "done" ->
            JD.succeed Done

        _ ->
            JD.fail "bad todo state"


todoDecoder : JD.Decoder Todo
todoDecoder =
    JD.succeed Todo
        |: (JD.field "title" JD.string)
        |: (JD.field "states" (JD.andThen todoStateDecoder JD.string))


todosDecoder : JD.Decoder (List Todo)
todosDecoder =
    JD.list todoDecoder


maybeTodosToTodos : Maybe (List Todo) -> JD.Decoder (List Todo)
maybeTodosToTodos value =
    case value of
        Nothing ->
            JD.succeed []

        Just todos ->
            JD.succeed todos


dataContainerDecoder : JD.Decoder DataContainer
dataContainerDecoder =
    JD.succeed DataContainer
        |: (JD.field "uid" JD.string)
        |: (JD.field "target" JD.string)
        |: (JD.maybe (JD.field "data" JD.value))


decodeDataContainer : JD.Value -> Result String DataContainer
decodeDataContainer value =
    JD.decodeValue dataContainerDecoder value
