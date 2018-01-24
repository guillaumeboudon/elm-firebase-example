module Types exposing (..)

import Modules.Auth as Auth
import Modules.Database as Database
import Modules.Pages as Pages


-- MODEL
{- Structure -}


type Page
    = WaitingPage
    | AuthPage
    | UserCreatePage Database.User
    | TodoPage


type alias Model =
    { auth : Auth.Auth
    , database : Maybe Database.Database
    , page : Page
    }



{- Initializers -}


initialModel : Model
initialModel =
    { auth = Auth.initialAuth
    , database = Nothing
    , page = AuthPage
    }



{- Setters -}


setAuth : Auth.Auth -> Model -> Model
setAuth auth model =
    { model | auth = auth }


setDatabase : Maybe Database.Database -> Model -> Model
setDatabase maybeDatabase model =
    { model | database = maybeDatabase }


setPage : Page -> Model -> Model
setPage page model =
    { model | page = page }



-- UPDATE


type Msg
    = NoOp
    | AuthMsg Auth.Msg
    | DatabaseMsg Database.Msg
    | SetPage Page
    | PagesMsg Pages.Msg
