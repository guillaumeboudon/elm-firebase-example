module Modules.Pages exposing (..)

import Modules.Database as Database


-- MODEL


type Page
    = WaitingPage
    | AuthPage
    | UserPage Database.User
    | TodoPage (Maybe Database.Todo)



-- UPDATE


update : Msg -> Page -> Page
update pagesMsg page =
    case page of
        UserPage user ->
            case pagesMsg of
                InputUserFirstName firstName ->
                    { user | firstName = firstName }
                        |> UserPage

                InputUserLastName lastName ->
                    { user | lastName = lastName }
                        |> UserPage

        _ ->
            page



-- MSG


type Msg
    = InputUserFirstName String
    | InputUserLastName String
