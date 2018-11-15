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

type alias KeyVal = (String, String) 

port sendSave   : KeyVal -> Cmd msg
port sendDelAll : String -> Cmd msg
port sendLoad   : String -> Cmd msg

port recvLoad   : (String -> msg) -> Sub msg

appKey = "myApp"

-- =========================================================

type alias Model = 
    {
        jobs: Maybe Jobs.Model
    }

type Msg 
    = Noop 
    | Load String
    | SaveAll
    | DelAll
    | Jobs Jobs.Msg

-- ===============================================
-- ===============================================

emptyModel: Model
emptyModel = Model (Just Jobs.init)

init: String -> (Model, Cmd msg)
init _ = ( emptyModel , Cmd.batch [ sendLoad appKey ]) 

-- ===============================================
-- ===============================================

loadJobs: Model -> String -> Model
loadJobs model data =
    {model | jobs = Jobs.decode data }


saveJobs: Maybe Jobs.Model -> List (Cmd msg) -> List (Cmd msg)
saveJobs toSave cmds =
    let 
        withKey = \data -> (appKey, data)
    in
        case toSave of
            Nothing  -> cmds
            Just jm  -> cmds ++ [ jm 
                                |> Jobs.encode 
                                |> json2str 
                                |> withKey 
                                |> sendSave
                                ]


updateJobs: Jobs.Msg -> Maybe Jobs.Model -> Maybe Jobs.Model
updateJobs msg jm =
    case jm of
        Nothing -> Nothing
        Just jobs -> Jobs.update msg jobs |> Just


update: Msg -> Model -> (Model, Cmd msg)
update msg model =
    case msg of
        Noop -> (model, Cmd.batch [])
        Load data -> (loadJobs model data, Cmd.batch [])
        SaveAll -> (model,  saveJobs model.jobs [] |> Cmd.batch) 
        DelAll ->  (emptyModel, Cmd.batch [ sendDelAll appKey ]) 
        Jobs jobsmsg ->
            let 
                newjobs = updateJobs jobsmsg model.jobs
            in
            ( { model | jobs = newjobs }
            , case jobsmsg of
                Jobs.DoneCreating -> saveJobs newjobs [] |> Cmd.batch 
                Jobs.UpdateJob _ _ -> saveJobs newjobs [] |> Cmd.batch 
                _ ->  Cmd.batch []
            )


-- ===============================================

subscriptions : Model -> Sub Msg
subscriptions nodel =
    recvLoad Load

-- ===============================================
-- ===============================================

json2str: Enco.Value -> String
json2str value = Enco.encode 2 value

view: Model -> Html Msg
view model =

    let 
        jbs =  case model.jobs of
                    Nothing -> Jobs.init
                    Just j -> j
    in
        div []
        [ Html.map  (\msg -> Jobs msg)  (Jobs.viewGrid      jbs)
        , Html.map  (\msg -> Jobs msg)  (Jobs.viewNewButton jbs)
        , Html.map  (\msg -> Jobs msg)  (Jobs.viewNewModal  jbs)
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

main = Browser.element { 
        init = init, 
        update = update, 
        view = view , 
        subscriptions = subscriptions
 }