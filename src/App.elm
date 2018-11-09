port module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Browser exposing (UrlRequest)

import Json.Decode as Deco exposing (..) 
import Json.Encode as Enco exposing (..) 

import Bootstrap.Button as Button

import Jobs exposing (..)

-- =========================================================

port save : String -> Cmd msg
port delall : () -> Cmd msg

-- =========================================================

type alias Model = 
    {
        jobs: Jobs.Model
    }

type Msg 
    = Noop 
    | SaveAll
    | DelAll
    | Jobs Jobs.Msg

-- ===============================================
-- ===============================================

emptyModel: Model
emptyModel = Model Jobs.init

init: String -> (Model, Cmd msg)
init flags = 
    let 
        jobs = Jobs.decode flags
    in
    (
        case jobs of
            Nothing -> emptyModel
            Just val -> Model val 
    , Cmd.batch [])

-- ===============================================
-- ===============================================

update: Msg -> Model -> (Model, Cmd msg)
update msg model =
    let 
        saveCmd = \jobs -> jobs |> Jobs.encode |> json2str |> save 
    in
        case msg of
            Noop -> (model, Cmd.batch [])
            SaveAll -> (model, Cmd.batch [ saveCmd model.jobs ]) 
            DelAll -> (emptyModel, Cmd.batch [ delall () ]) 
            Jobs a ->
                let 
                    newjobs = Jobs.update a model.jobs 
                in
                ( { model | jobs = newjobs }
                , case a of
                    Jobs.DoneCreating -> Cmd.batch [ saveCmd newjobs ]
                    Jobs.UpdateJob _ _ -> Cmd.batch [ saveCmd newjobs ]
                    _ ->  Cmd.batch []
                )

-- ===============================================
-- ===============================================

json2str: Enco.Value -> String
json2str value = Enco.encode 2 value

view: Model -> Html Msg
view model =
    div []
    [ Html.map  (\msg -> Jobs msg)  (Jobs.viewGrid      model.jobs)
    , Html.map  (\msg -> Jobs msg)  (Jobs.viewNewButton model.jobs)
    , Html.map  (\msg -> Jobs msg)  (Jobs.viewNewModal  model.jobs)
    , Button.button [ Button.secondary
                    , Button.onClick SaveAll
                    ] 
        [ text "Guardar"]
    , Button.button [ Button.danger
                    , Button.onClick DelAll
                    ] 
        [ text "Borrar todo"]
    ]

-- ===============================================
-- ===============================================

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

-- ===============================================
-- ===============================================

main = Browser.element { 
        init = init, 
        update = update, 
        view = view , 
        subscriptions = subscriptions
 }