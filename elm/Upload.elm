port module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onCheck, targetValue, on)

import Http exposing (..)
import Http.Progress exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation as Navigation

import Json.Decode as Decode
import Base64
import UrlBase64

-- ==============================================================

port sendOpenFile : String -> Cmd msg
port recvOpenFile : (String -> msg) -> Sub msg

-- ==============================================================

type alias Model =
    { uploadState : State
    }

type State 
    = None
    | Upload String
    | Done

type Msg = NoOp | StartUpload String

-- ==============================================================

view: Model -> Html msg
view model = text "hello" 

update: Msg -> Model -> (Model, Cmd msg)
update msg model = (model, Cmd.none)

init: String -> (Model, Cmd msg)
init flags = (Model None, Cmd.batch [ sendOpenFile "D:\\caca.txt" ])

subscriptions : Model -> Sub Msg
subscriptions model =
    recvOpenFile StartUpload

main = Browser.element 
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    }
