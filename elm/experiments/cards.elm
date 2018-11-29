module Main exposing (main)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Browser.Navigation as Navigation
import Browser exposing (UrlRequest)
import Url exposing (Url)
import Url.Parser as UrlParser exposing ((</>), Parser, s, top)
import Bootstrap.Navbar as Navbar
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Button as Button
import Bootstrap.ListGroup as Listgroup
import Bootstrap.Modal as Modal
import Bootstrap.CDN as CDN
import Bootstrap.Progress as Progress

main = Browser.sandbox { init = init, update = update, view = view }


init: Model
init = Model "header" "content"

type alias Model = 
  { header: String
  , content: String
  }

type Msg = Noop

update: Msg -> Model -> Model
update msg model =
  model


viewCard: Model -> Html Msg
viewCard model =
  Card.config [ Card.outlinePrimary ]
    |> Card.headerH4 [] [ text model.header ]
    |> Card.block []
        [ Block.text [] [ text model.content ]
        , Block.custom <|
            Button.linkButton
                [ Button.primary, Button.attrs [ href "#getting-started" ] ]
                [ text "Edit" ]
        ]
    |> Card.view


view: Model -> Html Msg
view model = 
  Grid.container [] 
    [ CDN.stylesheet
    , Grid.row []
        [ Grid.col []
            [ 
              viewCard model
            ]
        , Grid.col []
            [ 
              viewCard model
            ]
        , Grid.col []
            [ Card.config [ Card.outlineDanger ]
                |> Card.headerH4 [] [ text "Modules" ]
                |> Card.block []
                    [ Block.text [] [ text "Check out the modules overview" ]
                    , Block.custom <| 
                        div []
                            [ Progress.progress
                                [ Progress.info
                                , Progress.value 30
                                ]
                            , Button.linkButton
                                [ Button.primary
                                , Button.attrs [ href "#modules" ] 
                                ]
                                [ text "Module" ]
                            ]    
                    ]
                |> Card.view
            ]
        ]
    ]