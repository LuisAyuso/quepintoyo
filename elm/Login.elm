module Login exposing (Model, Msg, init, update, view, loginDone, testSession)

import Json.Decode as Decode exposing (..)
import Json.Encode as Encode exposing (..)

-- import SHA1 exposing(Digest, fromString, toBase64)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Button as Button
import Bootstrap.Tab as Tab
import Bootstrap.Alert as Alert
import Bootstrap.CDN as CDN

import Browser.Navigation as Navigation
import Browser exposing (UrlRequest)

import Http exposing (..)
import Http.Progress exposing (..)
import Json.Decode as Decode exposing (list, string)
import Json.Encode as Encode

import Validate exposing (..)


type alias Model =
    { callback: String
    , tab: Tab.State
    , user: String
    , password: String
    , password2: String
    , token: Maybe String
    , errorStr: Maybe String
    , validationStr: Maybe String
    }

type Msg 
    -- fill data
    = UpdateUser String 
    | UpdatePass String
    | UpdatePass2 String

    -- login
    | DoLogin 
    | LoginResponse (Result Http.Error String)

    -- register
    | DoRegister
    | RegisterResponse (Result Http.Error String)

    -- some components state
    | TabMsg Tab.State

init: String -> (Model, Cmd Msg)
init flags = 
    ({callback= ""
    , tab= Tab.initialState
    , user= ""
    , password= ""
    , password2= ""
    , token = Nothing
    , errorStr= Nothing
    , validationStr= Nothing
    }, Cmd.batch [])

-- ==================================================================
-- ==================================================================

loginDone: Model -> Bool
loginDone model = 
    case model.token of
        Just _ -> True
        Nothing -> False

-- ==================================================================
-- ==================================================================

doLogin: String -> String -> Http.Request String
doLogin usr passwrd =  
    encodeLogin usr passwrd
        |> Http.stringBody "application/x-www-form-urlencoded"
        |> httpPost "login"

doRegister: String -> String -> Http.Request String
doRegister usr passwrd = 
    encodeLogin usr passwrd
        |> Http.stringBody "application/x-www-form-urlencoded"
        |> httpPost "register"


httpPost: String -> Http.Body -> Http.Request String
httpPost url body =
    Http.request
        { method = "POST"
        , headers = []
        , url = url
        , body = body
        , expect = Http.expectString
        , timeout = Nothing
        , withCredentials = False
        } 

encodeLogin: String -> String -> String
encodeLogin usr passwrd =
    let pswd_digest = passwrd 
    in
        formUrlencoded [ ("user", usr)
                    , ("password", pswd_digest) ]

formUrlencoded : List ( String, String ) -> String
formUrlencoded object =
    object
        |> List.map
            (\( user, value ) ->
                 user ++ "=" ++ value
            )
        |> String.join "&"

buildRequest: String -> Http.Request String
buildRequest token  = 
  let 
    headers =
              [ Http.header "Authorization" ("Bearer " ++ token) 
              ]
  in
    Http.request
    { body = Http.emptyBody
    , expect = Http.expectString 
    , headers = headers
    , method = "GET"
    , timeout = Nothing 
    , url = "check_token"
    , withCredentials = False
    } 

testSession: String -> Cmd Msg
testSession token  = 
    buildRequest token |> Http.send LoginResponse

-- ==================================================================
-- ==================================================================

pwdValidator: (subject -> String.String) -> (subject -> String.String) -> error -> Validate.Validator error subject
pwdValidator pwd pwd2 error= 
    ifFalse (\subject -> (pwd subject) == (pwd2 subject)) error

modelValidator: Validator String Model
modelValidator = 
    Validate.all
        [ ifBlank .user "Necesitamos un nombre de usuario."
   --     , ifInvalidEmail .user (\_ -> "Por favor, revisa tu email")
        , ifBlank .password "Por favor, introduce una contraseña."
        ]

modelValidator2: Validator String Model
modelValidator2 = 
    Validate.all
        [ ifBlank .user "Necesitamos un nombre de usuario."
   --     , ifInvalidEmail .user (\_ -> "Por favor, revisa tu email")
        , ifBlank .password "Por favor, introduce una contraseña."
        , pwdValidator .password .password2 "Las dos contraseñas deben se ser iguales."
        ]

-- ==================================================================
-- ==================================================================

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    let 
        newmodel  =
            case msg of
                UpdateUser str -> { model | user = str }
                UpdatePass str -> { model | password = str }
                UpdatePass2 str -> { model | password2 = str }

                DoLogin -> model 
                LoginResponse res -> 
                    case res of
                        Ok token -> { model | token = Just token }
                        Err error -> { model | errorStr = Just "usuario o contraseña no validos" }

                DoRegister -> model 
                RegisterResponse _ -> model

                TabMsg state -> 
                    { model 
                    | tab = state
                    , user = ""
                    , password = ""
                    , password2 = ""
                    }

        validation = 
            case Validate.validate modelValidator newmodel of
                Err [] -> Just "error desconocido"
                Err (s :: _) -> Just s
                Ok _ -> Nothing

        validmodel = 
            { newmodel | 
                validationStr = 
                    case msg of
                        DoLogin -> validation
                        DoRegister -> validation
                        _ -> Nothing
            }

        cmds = 
            case validmodel.validationStr of
                Nothing -> 
                    case msg of
                        DoLogin    -> Cmd.batch [ doLogin model.user model.password |> Http.send LoginResponse ] 
                        DoRegister -> Cmd.batch [ doRegister model.user model.password |> Http.send LoginResponse ] 
                        _ -> Cmd.none
                Just _ -> Cmd.none
    in
     (validmodel, cmds)

-- ==================================================================
-- ==================================================================

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

-- ===========================================================

viewLogin: Model -> Html Msg
viewLogin model = 
    div []
    [  text "login"
    ,InputGroup.config
        (InputGroup.text [ Input.placeholder model.user, Input.onInput UpdateUser])
        |> InputGroup.predecessors
            [ InputGroup.span [] [ text "Alias" ] ]
        |> InputGroup.view
    ,InputGroup.config
        (InputGroup.password [ Input.placeholder model.password, Input.onInput UpdatePass])
        |> InputGroup.predecessors
            [ InputGroup.span [] [ text "Contraseña" ] ]
        |> InputGroup.view
    , case model.validationStr of
        Nothing -> div [][]
        Just str -> Alert.simpleWarning [] [ text str ]
    , case model.errorStr of
        Nothing -> div [][]
        Just str -> Alert.simpleDanger [] [ text str ]
    , Button.button [ Button.primary, Button.onClick DoLogin ][ text "Entrar"]
    ]


viewRegister: Model -> Html Msg
viewRegister model = 
    div []
    [  text "Registrarse"
    ,InputGroup.config
        (InputGroup.text [ Input.placeholder model.user, Input.onInput UpdateUser])
        |> InputGroup.predecessors
            [ InputGroup.span [] [ text "Alias" ] ]
        |> InputGroup.view
    ,InputGroup.config
        (InputGroup.password [ Input.placeholder model.password, Input.onInput UpdatePass])
        |> InputGroup.predecessors
            [ InputGroup.span [] [ text "Contraseña" ] ]
        |> InputGroup.view
    ,InputGroup.config
        (InputGroup.password [ Input.placeholder model.password2, Input.onInput UpdatePass2])
        |> InputGroup.predecessors
            [ InputGroup.span [] [ text "Repite la contraseña" ] ]
        |> InputGroup.view
    , case model.errorStr of
        Nothing -> div [][]
        Just str -> Alert.simpleDanger [] [ text str ]
    , Button.button [ Button.primary, Button.onClick DoRegister ][ text "Registrar"]
    ]

                    
view: Model -> Html Msg
view model =  
--  Card.config [ Card.outlinePrimary ]
--    |> Card.block []
    div[]
        [
            Tab.config TabMsg
            |> Tab.items
                [ Tab.item
                    { id = "login"
                    , link = Tab.link [] [ text "Login" ]
                    , pane =
                        Tab.pane [  ]
                            [ viewLogin model ]
                    }
                , Tab.item
                    { id = "registrarse"
                    , link = Tab.link [] [ text "Register" ]
                    , pane =
                        Tab.pane [  ]
                            [ viewRegister model ]
                    }
                ]
            |> Tab.view model.tab
       --     |> Block.custom 
        ]
 --   |> Card.view

-- =========================================================
-- standalone view
-- =========================================================

main = Browser.element 
        { init = init
        , update = update
        , view = viewStandalone 
        , subscriptions  = subscriptions
        }

viewStandalone: Model -> Html Msg
viewStandalone model =
    div []
  --  [ CDN.stylesheet 
    [ Grid.container []                                     
        [ Grid.row []                                     
            [ Grid.col [] [  ]
            , Grid.col [] [ view model ]
            , Grid.col [] [  ]
            ]
        ]
    ]