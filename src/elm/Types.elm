module Types exposing (..)

import Modules.Auth as Auth
import Modules.Database as Database


-- MODEL
{- Structure -}


type Status
    = Loading
    | Active


type alias Model =
    { auth : Auth.Auth
    , database : Maybe Database.Database
    , status : Status
    }



{- Initializers -}


initialModel : Model
initialModel =
    { auth = Auth.initialAuth
    , database = Nothing
    , status = Active
    }



{- Setters -}


setAuth : Auth.Auth -> Model -> Model
setAuth auth model =
    { model | auth = auth }


setDatabase : Maybe Database.Database -> Model -> Model
setDatabase maybeDatabase model =
    { model | database = maybeDatabase }


setStatus : Status -> Model -> Model
setStatus status model =
    { model | status = status }



-- UPDATE


type Msg
    = NoOp
    | AuthMsg Auth.Msg
    | DatabaseMsg Database.Msg
    | SetActiveStatus
