module Modules.Pages exposing (..)

import Modules.Database as Database


-- MODEL


type Page
    = WaitingPage
    | AuthPage
    | UserCreatePage Database.User
    | TodoPage (Maybe Database.Todo)



-- UPDATE


update : Msg -> Page -> Page
update pagesMsg page =
    case page of
        UserCreatePage user ->
            case pagesMsg of
                InputUserFirstName firstName ->
                    { user | firstName = firstName }
                        |> UserCreatePage

                InputUserLastName lastName ->
                    { user | lastName = lastName }
                        |> UserCreatePage

        _ ->
            page



-- MSG


type Msg
    = InputUserFirstName String
    | InputUserLastName String
