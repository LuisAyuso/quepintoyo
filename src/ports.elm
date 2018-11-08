port module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Browser.Navigation as Navigation
import Browser exposing (UrlRequest)

-- =========================================================

port save : String -> Cmd msg

-- =========================================================

type alias Model =
    { saved: String 
    , new: String
    }

type Msg = Noop | Save | Change String


init: Maybe String -> (Model, Cmd msg)
init flags =
    case flags of
        Just str -> (Model str "", Cmd.batch [] )
        Nothing -> (Model "no flags" "", Cmd.batch [])


update: Msg -> Model -> (Model, Cmd msg)
update msg model = 
    case msg of
        Noop -> (model, Cmd.batch [] )
        Change str -> (model, Cmd.batch [] )
        Save -> (model, Cmd.batch [save "guay"] )


view: Model -> Html Msg
view model = 
    div []
    [ text model.saved
    , input [ onInput Change] []
    , button [onClick Save ][text "ok"]
    ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

-- =======================================================

main = Browser.element { 
        init = init, 
        update = update, 
        view = view , 
        subscriptions = subscriptions
 }