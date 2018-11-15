module Login exposing (Model, Msg, init, update, view)

import Json.Decode as Decode exposing (..)
import Json.Encode as Encode exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block

import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Button as Button

import Bootstrap.Tab as Tab

import Bootstrap.CDN as CDN

import Browser.Navigation as Navigation
import Browser exposing (UrlRequest)

type alias Model =
    { tab: Tab.State
    , name: String
    , password: String
    , token: String
    , errorStr: Maybe String
    }

type Msg 
    = UpdateName String 
    | UpdatePass String
    | DoLogin 
    | TabMsg Tab.State

init: String -> (Model, Cmd Msg)
init flags = (Model Tab.initialState "" "" "" Nothing, Cmd.batch [])

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    ( case msg of
            UpdateName str -> { model | name = str }
            UpdatePass str -> { model | password = str }
            DoLogin -> model 
            TabMsg state -> { model | tab = state}
    , Cmd.none
    )

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

-- ===========================================================

viewLogin: Model -> Html Msg
viewLogin model = 
    div []
    [  text "login"
    ,InputGroup.config
        (InputGroup.text [ Input.placeholder model.name, Input.onInput UpdateName])
        |> InputGroup.predecessors
            [ InputGroup.span [] [ text "@"] ]
        |> InputGroup.view
    ,InputGroup.config
        (InputGroup.text [ Input.placeholder model.password, Input.onInput UpdatePass])
        |> InputGroup.predecessors
            [ InputGroup.span [] [ text "passwd" ] ]
        |> InputGroup.view
    , case model.errorStr of
        Nothing -> div [][]
        Just str -> text str

    , Button.button [ Button.primary, Button.onClick DoLogin ][ text "Login"]
    ]

viewRegister: Model -> Html Msg
viewRegister model = 
    div []
    [  text "register"
    ]

                    
view: Model -> Html Msg
view model =  
  Card.config [ Card.outlinePrimary ]
    |> Card.block []
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
                    { id = "register"
                    , link = Tab.link [] [ text "Register" ]
                    , pane =
                        Tab.pane [  ]
                            [ viewRegister model ]
                    }
                ]
            |> Tab.view model.tab
            |> Block.custom 
        ]
    |> Card.view

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
    [ CDN.stylesheet 
    , Grid.container []                                     
        [ Grid.row []                                     
            [ Grid.col [] [  ]
            , Grid.col [] [ view model ]
            , Grid.col [] [  ]
            ]
        ]
    ]