module App exposing (main)

import Html exposing (text)
import Browser exposing (..)

type alias Model = String

init = "goodbye"

update msg model = model

view model =
    text model

main = Browser.sandbox({init = init, update = update, view = view})

