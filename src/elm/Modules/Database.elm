port module Modules.Database exposing (..)

import Json.Decode as JD
import Json.Decode.Extra exposing ((|:))


-- MODEL
{- Structure -}


type alias Persisted a =
    { id : Int
    , createdAt : String
    , updatedAt : String
    , data : a
    }


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
    { user : Persisted User
    , todos : List (Persisted Todo)
    }



{- Setters -}


setUser : User -> { a | user : User } -> { a | user : User }
setUser user database =
    { database | user = user }


setTodos : List (Persisted Todo) -> { a | todos : List (Persisted Todo) } -> { a | todos : List (Persisted Todo) }
setTodos todos database =
    { database | todos = todos }



-- PORTS


port databaseFetchData : String -> Cmd msg


port databaseReceiveData : (JD.Value -> msg) -> Sub msg



-- UPDATE


type Msg
    = ReceiveData Database


update : Msg -> Maybe Database -> Maybe Database
update databaseMsg database =
    case databaseMsg of
        ReceiveData newDatabase ->
            Just newDatabase



-- DECODERS


userDecoder : JD.Decoder User
userDecoder =
    JD.succeed User
        |: (JD.field "firstName" JD.string)
        |: (JD.field "lastName" JD.string)


persistedUserDecoder : JD.Decoder (Persisted User)
persistedUserDecoder =
    JD.succeed Persisted
        |: (JD.field "id" JD.int)
        |: (JD.field "createdAt" JD.string)
        |: (JD.field "updatedAt" JD.string)
        |: (JD.field "data" userDecoder)


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


persistedTodoDecoder : JD.Decoder (Persisted Todo)
persistedTodoDecoder =
    JD.succeed Persisted
        |: (JD.field "id" JD.int)
        |: (JD.field "createdAt" JD.string)
        |: (JD.field "updatedAt" JD.string)
        |: (JD.field "data" todoDecoder)


persistedTodosDecoder : JD.Decoder (List (Persisted Todo))
persistedTodosDecoder =
    JD.list persistedTodoDecoder


databaseDecoder : JD.Decoder Database
databaseDecoder =
    JD.succeed Database
        |: (JD.field "user" persistedUserDecoder)
        |: (JD.field "todos" persistedTodosDecoder)


decodeDatabase : JD.Value -> Result String Database
decodeDatabase value =
    JD.decodeValue databaseDecoder value
