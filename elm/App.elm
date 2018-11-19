port module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Browser exposing (UrlRequest)

import Json.Decode as Deco exposing (..) 
import Json.Encode as Enco exposing (..) 

import Bootstrap.Button as Button
import Bootstrap.Modal as Modal
import Bootstrap.Navbar as Navbar

import Jobs exposing (..)
import Login exposing (..)

-- =========================================================

type alias KeyVal = (String, String) 

port sendSave   : KeyVal -> Cmd msg
port sendDelAll : String -> Cmd msg
port sendLoad   : String -> Cmd msg

port recvLoad   : (String -> msg) -> Sub msg

appKey = "myApp"

-- =========================================================

type View 
    = Kanban Jobs.Model
    | Feed
    | Settings
    | Calendar

type alias Model = 
    { logged_token: Maybe String
    , view: View
    , login_win: Modal.Visibility
    , navbarState : Navbar.State 
    , login: Login.Model  
    }

type Msg 
    = Noop 
    | Load String
    | SaveAll
    | DelAll
    | JobsMsg Jobs.Msg
    | LoginMsg Login.Msg
    | NavbarMsg Navbar.State

-- ===============================================
-- ===============================================

emptyJobs = Jobs.init

init: String -> (Model, Cmd Msg)
init _ = 
    let (lm, _) =  Login.init ""
        kanban = Kanban emptyJobs
        feed = Feed
        (navbar, cmds) = Navbar.initialState NavbarMsg
        modal = Modal.shown -- Modal.hidden
    in (Model Nothing feed modal navbar lm , cmds)
    -- in (Model Nothing Kanban emp Modal.shown lm, Cmd.none)
-- ( emptyModel , Cmd.batch [ sendLoad appKey ]) 

-- ===============================================
-- ===============================================

loadJobs: Model -> String -> Model
loadJobs model data = model
    -- {model | jobs = Jobs.decode data }


saveJobs: Jobs.Model -> Cmd Msg
saveJobs jobs =
    let 
        withKey = \data -> (appKey, data)
    in
       Cmd.batch [ jobs 
        |> Jobs.encode 
        |> json2str 
        |> withKey 
        |> sendSave
        ]


updateJobs: Jobs.Msg -> Jobs.Model -> Maybe Jobs.Model
updateJobs msg jobs =
        Jobs.update msg jobs |> Just

upModelKanban: Model -> (m -> m) -> Model
upModelKanban model callback =
    model

upCmdKanban: Model -> (Jobs.Model -> Cmd Msg) -> Cmd Msg
upCmdKanban model callback =
    case model.view of
        Kanban km -> callback km -- |> Cmd.map JobsMsg
        _ -> Cmd.batch []

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =

    case msg of
        Noop -> (model, Cmd.none )

        Load data -> (model, Cmd.none)
            --(loadJobs model data, Cmd.batch [])
        SaveAll -> (model
                   , upCmdKanban model (\jm -> saveJobs jm) )

        DelAll ->  (model, Cmd.batch [ sendDelAll appKey ]) 

        JobsMsg jobsmsg -> (model, Cmd.batch [])
    --        let 
    --            newjobs = updateJobs jobsmsg model.view
    --        in
    --        ( { model | jobs = newjobs }
    --        , case jobsmsg of
    --            Jobs.DoneCreating -> saveJobs newjobs [] |> Cmd.batch 
    --            Jobs.UpdateJob _ _ -> saveJobs newjobs [] |> Cmd.batch 
    --            _ ->  Cmd.batch []
    --        )
        LoginMsg loginmsg -> 
                let (nm, cmds) = Login.update loginmsg model.login
                in 
                    ({model | login = nm }, Cmd.map LoginMsg cmds)
            -- cmds |> Cmd.map LoginMsg )
        NavbarMsg state -> 
            ( { model | navbarState = state }, Cmd.none )


-- ===============================================

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [
    Navbar.subscriptions model.navbarState NavbarMsg
    ]
    -- recvLoad Load

-- ===============================================
-- ===============================================

json2str: Enco.Value -> String
json2str value = Enco.encode 2 value

view: Model -> Html Msg
view model =
    div[]
    [
    Navbar.config NavbarMsg
        |> Navbar.withAnimation
        |> Navbar.brand [ href "#"] [ text "QuePintoYo"]
        |> Navbar.items
            [ Navbar.itemLink [href "#"] [ text "Feed"]
            , Navbar.itemLink [href "#"] [ text "Trabajos"]
            , Navbar.itemLink [href "#"] [ text "Calendario"]
            , Navbar.itemLink [href "#"] [ text "Configuración"]
            ]
        |> Navbar.view model.navbarState
    ,

        case model.view of
            Kanban jbs ->
                div []
                [ Html.map  (\msg -> JobsMsg msg)  (Jobs.viewGrid      jbs)
                , Html.map  (\msg -> JobsMsg msg)  (Jobs.viewNewButton jbs)
                , Html.map  (\msg -> JobsMsg msg)  (Jobs.viewNewModal  jbs)
                , Button.button [ Button.secondary
                                , Button.onClick SaveAll
                                ] 
                    [ text "Guardar"]
                , Button.button [ Button.danger
                                , Button.onClick DelAll
                                ] 
                    [ text "Borrar todo"]
                ]
            Feed -> text "feed"
            Settings -> text "settings"
            Calendar -> text"calendar"

        , Modal.config (Noop)
            |> Modal.large
            |> Modal.hideOnBackdropClick False
            --|> Modal.h3 [] [ text "hello" ]
            |> Modal.body []  [ Html.map LoginMsg (Login.view model.login) ]
            --|> Modal.footer [] []
            |> Modal.view model.login_win
    ]

-- ===============================================
-- ===============================================

main = Browser.element { 
        init = init, 
        update = update, 
        view = view , 
        subscriptions = subscriptions
 }