module Modules.Pages exposing (..)

-- UPDATE


update : Msg -> b -> b
update pagesMsg page =
    page



-- MSG


type Msg
    = InputUserFirstName String
    | InputUserLastName String
