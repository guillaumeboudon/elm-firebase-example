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
update pagesMsg currentPage =
    case pagesMsg of
        SetPage page ->
            page

        InputUserFirstName firstName ->
            case currentPage of
                UserPage user ->
                    { user | firstName = firstName }
                        |> UserPage

                _ ->
                    currentPage

        InputUserLastName lastName ->
            case currentPage of
                UserPage user ->
                    { user | lastName = lastName }
                        |> UserPage

                _ ->
                    currentPage



-- MSG


type Msg
    = SetPage Page
    | InputUserFirstName String
    | InputUserLastName String
