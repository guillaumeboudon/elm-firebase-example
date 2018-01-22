module Types exposing (..)

import Modules.Auth as Auth
import Modules.Database as Database


-- MODEL
{- Structure -}


type alias Model =
    { auth : Auth.Auth
    , database : Maybe Database.Database
    }



{- Initializers -}


initialModel : Model
initialModel =
    { auth = Auth.initialAuth
    , database = Nothing
    }



{- Setters -}


setAuth : Auth.Auth -> Model -> Model
setAuth auth model =
    { model | auth = auth }


setDatabase : Maybe Database.Database -> Model -> Model
setDatabase maybeDatabase model =
    { model | database = maybeDatabase }



-- UPDATE


type Msg
    = NoOp
    | AuthMsg Auth.Msg
    | DatabaseMsg Database.Msg
