port module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http exposing (..)
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
sessionKey = "lastSession"

-- =========================================================

type View 
    = Kanban Jobs.Model
    | Feed
    | Settings
    | Calendar

type alias Model = 
    { user_token: Maybe String
    , user_name: Maybe String
    , view: View
    , login_win: Modal.Visibility
    , navbarState : Navbar.State 
    , login: Login.Model  
    , error: Maybe String
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
    in 
        (Model Nothing Nothing feed modal navbar lm Nothing
        , Cmd.batch [ cmds, sendLoad sessionKey ])
    -- in (Model Nothing Kanban emp Modal.shown lm, Cmd.none)
-- ( emptyModel , Cmd.batch [ sendLoad appKey ]) 

-- ===============================================
-- ===============================================

loadData: Model -> String -> (Model, Cmd Msg)
loadData model data =
    let 
        asSession = Deco.decodeString decodeSession data
        asJobs = Jobs.decode data
    in
        case (asSession, asJobs) of
            (Err _, Just s) -> (loadJobs model s, Cmd.none)
            (Ok s, Nothing) -> loadSession model s
            (Ok _, Just _) -> ({model | error = Just "both right?"}, Cmd.none)
            _ -> ({model | error = Just "read error"}, Cmd.none)


loadJobs: Model -> Jobs.Model -> Model
loadJobs model data = 
    case model.view of
        Kanban _ -> { model | view = Kanban data }
        _ -> model

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

encodeSession usr token =
        Enco.object
      [ ("user", Enco.string usr)
      , ("token", Enco.string token)
      ]

toPair: a -> b -> (a, b)
toPair a b = (a, b)

decodeSession : Deco.Decoder (String, String)
decodeSession =
  map2 toPair
      (Deco.field "user" Deco.string)
      (Deco.field "token" Deco.string)

saveSession: String -> String -> Cmd Msg
saveSession user token =
    let 
        withKey = \data -> (sessionKey, data)
    in
        encodeSession user token 
            |> Enco.encode 0 
            |> withKey 
            |> sendSave

loadSession: Model -> (String, String) -> (Model, Cmd Msg)
loadSession model (usr, token) = 
        -- { model | user_name = Just usr
        --         , user_token = Just token 
        --         , login_win = Modal.hidden
        -- }

      --  ( model, testSession token )
      ( model,  Login.testSession token |> Cmd.map LoginMsg)

-- ===============================================
-- ===============================================

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

        Load data -> loadData model data
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
                    newmodel = {model 
                            | login = nm 
                            , user_token = nm.token
                            , user_name = Just nm.user
                            , login_win = Modal.hidden
                            }
                    user = Maybe.withDefault "" newmodel.user_name
                    token = Maybe.withDefault "" newmodel.user_token 
                in 
                    if Login.loginDone nm then
                        (newmodel
                        , Cmd.batch [ saveSession user token ])
                    else
                         ({model | login = nm }, Cmd.map LoginMsg cmds)
            -- cmds |> Cmd.map LoginMsg )
        NavbarMsg state -> 
            ( { model | navbarState = state }, Cmd.none )


-- ===============================================

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch 
        [ Navbar.subscriptions model.navbarState NavbarMsg
        , recvLoad Load
        ]

-- ===============================================
-- ===============================================

activeKanban: Model -> List (Attribute msg) -> List (Html msg) -> Navbar.Item msg
activeKanban model =
    case model.view of
        Kanban _ -> Navbar.itemLinkActive
        _ -> Navbar.itemLink

activeFeed: Model -> List (Attribute msg) -> List (Html msg) -> Navbar.Item msg
activeFeed model =
    case model.view of
        Feed -> Navbar.itemLinkActive
        _ -> Navbar.itemLink

activeCalendar: Model -> List (Attribute msg) -> List (Html msg) -> Navbar.Item msg
activeCalendar model =
    case model.view of
        Calendar -> Navbar.itemLinkActive
        _ -> Navbar.itemLink

activeConfig: Model -> List (Attribute msg) -> List (Html msg) -> Navbar.Item msg
activeConfig model =
    case model.view of
        Settings -> Navbar.itemLinkActive
        _ -> Navbar.itemLink

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
            [ (activeFeed model) [href "#"] [ text "Feed"] 
            , (activeKanban model) [href "#"] [ text "Trabajos"]
            , (activeCalendar model) [href "#"] [ text "Calendario"] 
            , (activeConfig model) [href "#"] [ text "Configuración"] 
            ]
        |> Navbar.customItems
            [ 
                case model.user_name of
                    Just t -> Navbar.textItem [  class "muted" ] [ "usuario: " ++ t |> text]
                    Nothing -> Navbar.textItem [ class "muted" ] [ text "no estas registrado" ]
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