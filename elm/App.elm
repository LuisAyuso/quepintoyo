port module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Browser exposing (..)
import Browser.Navigation exposing (..)
import Url exposing(..)

import Json.Decode as Deco exposing (..) 
import Json.Encode as Enco exposing (..) 

import Bootstrap.Button as Button
import Bootstrap.Modal as Modal
import Bootstrap.Navbar as Navbar
import Bootstrap.Alert as Alert

import Jobs.Jobs as Jobs exposing (..)
import Login exposing (..)
import Tools exposing(..)
import Route exposing(..)
import Feed.Feed as Feed exposing(..) 

import Ctx.Ctx as Ctx exposing(..)

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
    | Feed Feed.Model
    | Settings
    | Calendar

type alias Model = 
    { context: Ctx.Context
    , user_name: Maybe String
    , view: View
    , login_win: Modal.Visibility
    , navbarState : Navbar.State 
    , login: Login.Model  
    , error: Maybe String
    , alert: Alert.Visibility
    }

type Msg 
    = NoOp 
    | Load String

    -- messages of views
    | JobsMsg Jobs.Msg
    | FeedMsg Feed.Msg

    -- messages of locally managed comps
    | LoginMsg Login.Msg
    | NavbarMsg Navbar.State
    | CloseSession

    -- Navigation
    | ChangeView Route.Route

    -- Alert
    | AlertMsg Alert.Visibility

-- ===============================================
-- ===============================================

initKanban: (Jobs.Model, Cmd Jobs.Msg)
initKanban =
        Jobs.init ""

initFeed: Ctx.Context -> (Feed.Model, Cmd Feed.Msg)
initFeed ctx = Feed.initApp ctx ""

initDefaultView: Ctx.Context -> (View, Cmd Msg)
initDefaultView ctx =
    let (md, cmd) = initFeed ctx
    in (Feed md, Cmd.map FeedMsg cmd)

init: String -> (Model, Cmd Msg)
init _ = 
    let (lm, _) =  Login.init ""
        ctx = Ctx.initCtx
        (default_view, view_cmds) = initDefaultView ctx
        (navbar, cmds) = Navbar.initialState NavbarMsg
        modal = Modal.shown -- Modal.hidden
    in 
        (Model ctx Nothing default_view modal navbar lm Nothing Alert.shown
        , Cmd.batch [ cmds, view_cmds,  sendLoad sessionKey, sendLoad appKey ])

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
    let
        (log_mod, cmds) = Login.testSession model.login usr token 
    in
      ( {model | login = log_mod }, Cmd.map LoginMsg cmds)

-- ===============================================
-- ===============================================


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
        NoOp -> (model, Cmd.none )

        Load data -> loadData model data

        JobsMsg jobsmsg ->
            case model.view of
                Kanban md -> 
                    let (newmod, cmds) = Jobs.update jobsmsg md 
                    in ({model | view = Kanban newmod}, cmds)
                _ -> (model, Cmd.none)

        FeedMsg feedmsg -> 
            case model.view of
                Feed md -> 
                    let (newmod, cmds) = Feed.updateApp model.context feedmsg md 
                    in ({model | view = Feed newmod}, Cmd.map FeedMsg cmds)
                _ -> (model, Cmd.none)

        LoginMsg loginmsg -> 
                let (nm, cmds) = Login.update loginmsg model.login
                    newmodel = {model 
                            | login = nm 
                            , context = Ctx.ctxWithToken nm.token
                            , user_name = Just nm.user
                            , login_win = Modal.hidden
                            }
                    user = nm.user
                    token = Maybe.withDefault "" nm.token 
                in 
                    if Login.loginDone nm then
                        (newmodel
                        , Cmd.batch [ saveSession user token ])
                    else
                         ({model | login = nm }, Cmd.map LoginMsg cmds)

        NavbarMsg state -> 
            ( { model | navbarState = state }, Cmd.none )

        CloseSession ->
            let 
                ctx = Ctx.initCtx
                (newlogin, _) = Login.init "" 
                (newview, cmds) = initDefaultView ctx
            in
                ({model | context = ctx
                    , user_name = Nothing
                    , login = newlogin 
                    , login_win = Modal.shown
                    , view = newview
                 }
                , Cmd.batch [ sendDelAll sessionKey, cmds ])

        ChangeView r -> 
            let 
                doNothing = (model, Cmd.none)
                (jbs, jobscmds) = initKanban
                (feed, feedcmds) = initFeed model.context
            in case r of
                Route.Home -> doNothing
                Route.Feed -> 
                    case model.view of
                        Feed _-> doNothing
                        _ ->  ({model | view = Feed feed}, Cmd.map FeedMsg feedcmds)
                Route.Kanban -> 
                    case model.view of
                        Kanban _ -> doNothing
                        _ ->  ({model | view = Kanban jbs }, Cmd.map JobsMsg jobscmds)
                Route.Calendar -> 
                    case model.view of
                        Calendar -> doNothing
                        _ ->  ({model | view = Calendar}, Cmd.none)
                Route.Settings -> 
                    case model.view of
                        Settings -> doNothing
                        _ ->  ({model | view = Settings}, Cmd.none)

        AlertMsg visibility ->
            ({ model | alert = visibility }, Cmd.none)

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
        Feed _ -> Navbar.itemLinkActive
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

viewAlert model =
         Alert.config
        |> Alert.info
        |> Alert.dismissable AlertMsg
        |> Alert.children
            [  -- Alert.h4 [] [ text "Atencion:" ]
             p [] [text "Nos obligan a informarte de la obviedad de que este sitio utiliza cookies!"]
            ]
        |> Alert.view model.alert

view: Model -> Html Msg
view model =
    div[]
    [
    Navbar.config NavbarMsg
        |> Navbar.withAnimation
        |> Navbar.brand [ href "#"] [ text "QuePintoYo"]
        |> Navbar.items
            [ (activeFeed model) [href "#feed"] [ text "Feed"] 
            , (activeKanban model) [href "#kanban"] [ text "Trabajos"]
            , (activeCalendar model) [href "#calendar"] [ text "Calendario"] 
            , (activeConfig model) [href "#settings"] [ text "Configuración"] 
            ]
        |> Navbar.customItems
            [ 
                case model.user_name of
                    Just t -> Navbar.textItem [  class "muted" ] [ "usuario: " ++ t |> text]
                    Nothing -> Navbar.textItem [ class "muted" ] [ text "no estas registrado" ]
                , Navbar.textItem [ class "muted" ] 
                    [ Button.button [ Button.secondary
                                    , Button.small
                                    , Button.onClick CloseSession
                                    ] 
                        [ text "Salir"]
                    ]
            ]
        |> Navbar.view model.navbarState
    , viewAlert model
    ,
        case model.view of
            Kanban jbs ->
                div []
                [ Html.map  (\msg -> JobsMsg msg)  (Jobs.view jbs)
                -- , Button.button [ Button.secondary
                --                 , Button.onClick SaveAll
                --                 ] 
                --     [ text "Guardar"]
                -- , Button.button [ Button.danger
                --                 , Button.onClick DelAll
                --                 ] 
                --     [ text "Borrar todo"]
                ]
            Feed f -> Html.map   (\msg -> FeedMsg msg)   (Feed.view f)
            Settings -> text "settings"
            Calendar -> text"calendar"

        , Modal.config (NoOp)
            |> Modal.large
            |> Modal.hideOnBackdropClick False
            --|> Modal.h3 [] [ text "hello" ]
            |> Modal.body []  [ Html.map LoginMsg (Login.view model.login) ]
            --|> Modal.footer [] []
            |> Modal.view model.login_win
    ]

-- ===============================================
-- ===============================================


onUrlRequest: UrlRequest -> Msg
onUrlRequest req = 
    case req of 
        Internal url ->
            case Route.fromUrl url of
                Nothing -> NoOp
                Just r -> ChangeView r
        External url -> NoOp

onUrlChange: Url -> Msg
onUrlChange url = ChangeView Route.Kanban

viewDoc model = 
     [ view model ] |> Browser.Document "QuePintoYo"

initApp: Maybe String -> Url -> Key -> ( Model, Cmd Msg )
initApp flags url key = init ""

-- ===============================================
-- ===============================================

main = Browser.application { 
        init = initApp, 
        update = update, 
        view = viewDoc , 
        subscriptions = subscriptions,
        onUrlRequest = onUrlRequest,
        onUrlChange = onUrlChange
 }