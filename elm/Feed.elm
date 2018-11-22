module Feed exposing (Model, Msg(..), update, init, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Browser.Navigation as Navigation
import Browser exposing (UrlRequest)

import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col

import Bootstrap.CDN as CDN

import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block

import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Form.Select as Select
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Form.Radio as Radio
import Bootstrap.Form.Textarea as Textarea
import Bootstrap.Form.Fieldset as Fieldset
import Bootstrap.Form.InputGroup as InputGroup

import Bootstrap.Button as Button
import Bootstrap.Progress as Progress
import Bootstrap.Modal as Modal
import Bootstrap.Text as Text

import Json.Encode as Enco exposing (..) 
import Json.Decode as Deco exposing (..) 

import Tools exposing(..)
import Url exposing(..)


type alias Entry = 
    { title: String
    , content: String
    , photos: Maybe Url
    , link: Maybe (List Url)
    }


type alias Model = 
    { entries: List Entry
    }

type Msg = NoOp

-- ============================================================
-- ============================================================

init: String -> (Model, Cmd Msg)
init flags = (Model [ Entry "one" "two" Nothing Nothing
                    , Entry "two" "fasgfasfqa" Nothing Nothing
                    ]
            , Cmd.none
            )

update: Msg -> Model -> (Model, Cmd Msg)
update msg model = 
    (model, Cmd.none)

getColumn: Int -> Int -> List a -> List a
getColumn col cols list = 
    list |> Tools.enumerate 
         |> List.filter (\(i,e) -> (modBy 4 i) == col)
         |> List.map (\(_,e) -> e)

viewEntry: Entry -> Html Msg
viewEntry entry = 
            Card.config [ Card.outlinePrimary ]
                |> Card.headerH4 [] [ text entry.title ]
                |> Card.block []
                    [ Block.text [] [ text entry.content ]
                    , Block.custom <| 
                        div [][
                            -- img [src  "Loading_icon.gif" ][]
                        ]
                    ]
                |> Card.view

view: Model -> Html Msg
view model = 
  Grid.container [] 
    [ Grid.row []
        [ model.entries 
                |> getColumn 0 4
                |> List.map viewEntry
                |> Grid.col []
        , model.entries 
                |> getColumn 1 4
                |> List.map viewEntry
                |> Grid.col []
        , model.entries 
                |> getColumn 2 4
                |> List.map viewEntry
                |> Grid.col []
        , model.entries 
                |> getColumn 3 4
                |> List.map viewEntry
                |> Grid.col []
        ]
    ]
