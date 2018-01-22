port module Modules.Auth exposing (..)

import Json.Decode as JD
import Json.Decode.Extra exposing ((|:))


-- MODEL
{- Structure -}


type alias AuthDetails =
    { email : String
    , password : String
    }


type alias AuthUser =
    { uid : String
    , email : String
    }


type Auth
    = NotAuthenticated AuthDetails
    | Authenticated AuthUser



{- Initializers -}


initialAuth : Auth
initialAuth =
    NotAuthenticated emptyAuthDetails


emptyAuthDetails : AuthDetails
emptyAuthDetails =
    AuthDetails "" ""


emptyAuthUser : AuthUser
emptyAuthUser =
    AuthUser "" ""



{- Setters -}


setEmail : String -> { a | email : String } -> { a | email : String }
setEmail email auth =
    { auth | email = email }


setPassword : String -> { a | password : String } -> { a | password : String }
setPassword password auth =
    { auth | password = password }


setUid : String -> { a | uid : String } -> { a | uid : String }
setUid uid auth =
    { auth | uid = uid }



-- PORTS


port authSignUp : AuthDetails -> Cmd msg


port authSignUpError : (String -> msg) -> Sub msg


port authLogIn : AuthDetails -> Cmd msg


port authLogOut : String -> Cmd msg


port authLoggedIn : (JD.Value -> msg) -> Sub msg


port authLoggedOut : (String -> msg) -> Sub msg



-- UPDATE


type Msg
    = InputEmail String
    | InputPassword String
    | SignUp
    | LogIn
    | LogOut
    | LoggedIn AuthUser
    | LoggedOut


updateNotAuthenticated : Msg -> AuthDetails -> ( Auth, Cmd Msg )
updateNotAuthenticated authMsg authDetails =
    case authMsg of
        InputEmail email ->
            ( authDetails
                |> setEmail email
                |> NotAuthenticated
            , Cmd.none
            )

        InputPassword password ->
            ( authDetails
                |> setPassword password
                |> NotAuthenticated
            , Cmd.none
            )

        SignUp ->
            ( NotAuthenticated authDetails, authSignUp authDetails )

        LogIn ->
            ( NotAuthenticated authDetails, authLogIn authDetails )

        LoggedIn authUser ->
            ( Authenticated authUser, Cmd.none )

        _ ->
            ( NotAuthenticated authDetails, Cmd.none )


updateAuthenticated : Msg -> AuthUser -> ( Auth, Cmd Msg )
updateAuthenticated authMsg authUser =
    case authMsg of
        LogOut ->
            ( Authenticated authUser, authLogOut "" )

        LoggedOut ->
            ( NotAuthenticated emptyAuthDetails, Cmd.none )

        _ ->
            ( Authenticated authUser, Cmd.none )


update : Msg -> Auth -> ( Auth, Cmd Msg )
update authMsg auth =
    case auth of
        NotAuthenticated authDetails ->
            updateNotAuthenticated authMsg authDetails

        Authenticated authUser ->
            updateAuthenticated authMsg authUser



-- DECODERS


authUserDecoder : JD.Decoder AuthUser
authUserDecoder =
    JD.succeed AuthUser
        |: (JD.field "email" JD.string)
        |: (JD.field "uid" JD.string)


decodeAuthUser : JD.Value -> Result String AuthUser
decodeAuthUser value =
    JD.decodeValue authUserDecoder value
