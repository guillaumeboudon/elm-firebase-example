module Types exposing (..)

import Modules.Auth as Auth


-- MODEL
{- Structure -}


type alias Model =
    { auth : Auth.Auth }



{- Initializers -}


initialModel : Model
initialModel =
    { auth = Auth.initialAuth }



{- Setters -}


setAuth : Auth.Auth -> Model -> Model
setAuth auth model =
    { model | auth = auth }



-- UPDATE


type Msg
    = NoOp
    | AuthMsg Auth.Msg
