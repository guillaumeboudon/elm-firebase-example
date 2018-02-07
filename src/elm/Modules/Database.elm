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


encodeTodoState : TodoState -> String
encodeTodoState todoState =
    case todoState of
        Pending ->
            "pending"

        Done ->
            "done"


type TodoState
    = Pending
    | Done


type alias Todo =
    { id : Int
    , title : String
    , state : TodoState
    }


type alias Todos =
    { uid : Int
    , todos : List Todo
    }


type alias Database =
    { user : User
    , todos : Todos
    }



{- Initializers -}


emptyUser : User
emptyUser =
    User "" ""


emptyTodos : Todos
emptyTodos =
    Todos 0 []


newTodo : Int -> Todo
newTodo id =
    Todo id "" Pending



{- Setters -}


setUser : User -> { a | user : User } -> { a | user : User }
setUser user database =
    { database | user = user }


setTodos : Todos -> { a | todos : Todos } -> { a | todos : Todos }
setTodos todos database =
    { database | todos = todos }


setTodoTitle : Todo -> String -> Todo
setTodoTitle todo title =
    { todo | title = title }


addTodo : Todo -> Todos -> Todos
addTodo todo todos =
    { todos
        | uid = todo.id + 1
        , todos = todos.todos ++ [ todo ]
    }


addTodoToTodos : Todo -> Database -> Database
addTodoToTodos todo database =
    { database | todos = database.todos |> addTodo todo }



-- PORTS


port databaseFetchData : DataContainer -> Cmd msg


port databaseReceiveData : (JD.Value -> msg) -> Sub msg


port databaseSaveData : DataContainer -> Cmd msg



-- UPDATE


type Msg
    = ReceiveUser User
    | ReceiveTodos Todos
    | SaveUser User
    | SaveTodo Todo


update : Msg -> Maybe Database -> Maybe Database
update databaseMsg maybeDatabase =
    case databaseMsg of
        ReceiveUser user ->
            case maybeDatabase of
                Nothing ->
                    Just (Database user emptyTodos)

                Just database ->
                    Just (database |> setUser user)

        ReceiveTodos todos ->
            case maybeDatabase of
                Nothing ->
                    Nothing

                Just database ->
                    Just (database |> setTodos todos)

        SaveUser user ->
            case maybeDatabase of
                Nothing ->
                    Nothing

                Just database ->
                    Just (database |> setUser user)

        SaveTodo todo ->
            case maybeDatabase of
                Nothing ->
                    Nothing

                Just database ->
                    Just (database |> addTodoToTodos todo)



-- DATA TREATMENT FUNCTIONS


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


databaseSaveTodos : String -> Todos -> Cmd msg
databaseSaveTodos uid todos =
    DataContainer uid "todos" (Just (todos |> todosEncoder))
        |> databaseSaveData


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



-- ENCODERS


userEncoder : User -> JE.Value
userEncoder user =
    JE.object
        [ ( "firstName", JE.string user.firstName )
        , ( "lastName", JE.string user.lastName )
        ]


todoEncoder : Todo -> JE.Value
todoEncoder todo =
    JE.object
        [ ( "id", JE.int todo.id )
        , ( "title", JE.string todo.title )
        , ( "state", JE.string (todo.state |> encodeTodoState) )
        ]


todosEncoder : Todos -> JE.Value
todosEncoder todos =
    JE.object
        [ ( "uid", JE.int todos.uid )
        , ( "todos", JE.list (List.map todoEncoder todos.todos) )
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
        |: (JD.field "id" JD.int)
        |: (JD.field "title" JD.string)
        |: (JD.field "state" (JD.andThen todoStateDecoder JD.string))


todoListDecoder : JD.Decoder (List Todo)
todoListDecoder =
    JD.list todoDecoder


todosDecoder : JD.Decoder Todos
todosDecoder =
    JD.succeed Todos
        |: (JD.field "uid" JD.int)
        |: (JD.field "todos" todoListDecoder)


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
