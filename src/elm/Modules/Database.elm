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


emptyDatabase : Database
emptyDatabase =
    Database emptyUser emptyTodos



{- Setters -}


setUser : User -> { a | user : User } -> { a | user : User }
setUser user database =
    { database | user = user }


setTodos : Todos -> { a | todos : Todos } -> { a | todos : Todos }
setTodos todos database =
    { database | todos = todos }


saveTodo : Todo -> Todos -> Todos
saveTodo todo todos =
    let
        updateTodo element =
            if element.id == todo.id then
                todo
            else
                element
    in
        if todo.id /= todos.uid then
            { todos | todos = List.map updateTodo todos.todos }
        else
            { todos
                | uid = todos.uid + 1
                , todos = todos.todos ++ [ todo ]
            }


saveTodoToTodos : Todo -> Database -> Database
saveTodoToTodos todo database =
    { database | todos = database.todos |> saveTodo todo }


deleteTodo : Int -> Todos -> Todos
deleteTodo todoId todos =
    let
        selectTodo element list =
            if element.id == todoId then
                list
            else
                element :: list
    in
        { todos | todos = todos.todos |> List.foldr selectTodo [] }


deleteTodoFromTodos : Int -> Database -> Database
deleteTodoFromTodos todoId database =
    { database | todos = database.todos |> deleteTodo todoId }


toggleTodo : Int -> Todos -> Todos
toggleTodo todoId todos =
    let
        toggler element =
            if element.id == todoId then
                { element
                    | state =
                        (case element.state of
                            Pending ->
                                Done

                            Done ->
                                Pending
                        )
                }
            else
                element
    in
        { todos | todos = todos.todos |> List.map toggler }


toggleTodoFromTodos : Int -> Database -> Database
toggleTodoFromTodos todoId database =
    { database | todos = database.todos |> toggleTodo todoId }



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
    | DeleteTodo Int
    | ToggleTodoState Int


update : Msg -> Database -> Database
update databaseMsg database =
    case databaseMsg of
        ReceiveUser user ->
            database |> setUser user

        ReceiveTodos todos ->
            database |> setTodos todos

        SaveUser user ->
            database |> setUser user

        SaveTodo todo ->
            database |> saveTodoToTodos todo

        DeleteTodo todoId ->
            database |> deleteTodoFromTodos todoId

        ToggleTodoState todoId ->
            database |> toggleTodoFromTodos todoId



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
