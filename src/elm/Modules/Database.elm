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


createUserData : String -> User -> OutcomingData
createUserData uid user =
    { ref = uid ++ "/user"
    , data = user |> userEncoder
    }



-- PORTS


type alias OutcomingData =
    { ref : String
    , data : JE.Value
    }


port databaseFetchData : String -> Cmd msg


port databaseWriteData : OutcomingData -> Cmd msg


port databaseReceiveData : (JD.Value -> msg) -> Sub msg



-- UPDATE


type Msg
    = ReceiveData Database


update : Msg -> Maybe Database -> Maybe Database
update databaseMsg database =
    case databaseMsg of
        ReceiveData newDatabase ->
            Just newDatabase



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


databaseDecoder : JD.Decoder Database
databaseDecoder =
    JD.succeed Database
        |: (JD.field "user" userDecoder)
        |: (JD.field "todos" todosDecoder)


decodeDatabase : JD.Value -> Result String Database
decodeDatabase value =
    JD.decodeValue databaseDecoder value
