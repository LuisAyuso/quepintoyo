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

init: Model
init = Model []

type alias Entry = 
    { title: String
    , content: String
    }


type alias Model = 
    { entries: List Entry
    }

