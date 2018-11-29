module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Browser exposing (UrlRequest)

import Json.Decode as Deco exposing (..) 
import Json.Encode as Enco exposing (..) 

import Bootstrap.CDN as CDN

import Jobs exposing (..)


type alias Model = Jobs.Model

type Msg 
    = Noop 
    | Jobs Jobs.Msg


init: Model
init = Jobs.init

update: Msg -> Model -> Model
update msg model =
    case msg of
        Noop -> model
        Jobs a -> Jobs.update a model

-- ===============================================
-- View stuff
-- ===============================================

getJson: Model -> Enco.Value
getJson model = 
        model.jobs
            |> Enco.list (\job -> Jobs.encodeJob job)

json2str: Enco.Value -> String
json2str value = Enco.encode 2 value

view: Model -> Html Msg
view model =
    div []
    [ CDN.stylesheet
    , Html.map  (\msg -> Jobs msg)  (Jobs.viewGrid model)
    , Html.map  (\msg -> Jobs msg)  (Jobs.viewNew model)
    , getJson model 
        |> json2str
        |> text
    ]

main = Browser.sandbox
    { init = init
    , update = update
    , view = view
    }