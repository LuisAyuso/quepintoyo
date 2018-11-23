
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)

import Browser.Navigation as Navigation
import Browser exposing (UrlRequest)


type Model 
    = Loading
    | Loaded String

type Msg
    = NoOp
    | Done String

init: String -> (Model, Cmd msg)
init flags = (Loading, Cmd.batch [])

update: Msg -> Model -> (Model, Cmd msg)
update msg model =
    case msg of
        NoOp -> (model, Cmd.none)
        Done data -> (Loaded data , Cmd.none)


view: Model -> Html Msg
view model =
    case model of
        Loading -> text "loading"
        Loaded data -> 
                img
                    [ src data
                    ]
                    []

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

main = Browser.element 
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    }