
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onCheck, targetValue, on)

import Http exposing (..)
import Http.Progress exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation as Navigation

import Json.Decode as Decode
import Base64
import UrlBase64

type Model 
    = Loading
    | Loaded 
    | Visible 
    | Error String

type Msg
    = NoOp
    | Start
    | ImgLoaded 
    | Done (Result Http.Error String)

init: String -> (Model, Cmd msg)
init flags = (Loading, Cmd.batch [])

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        NoOp -> (model, Cmd.none)
        Start -> (model, request)
        Done (Ok data) -> (Loaded, Cmd.none)
        Done (Err _) -> (Error "nop" , Cmd.none)
        ImgLoaded  -> (Visible, Cmd.none)

encode str = str |> Base64.encode |> Ok
b64e = encode |> UrlBase64.encode

onLoad : msg -> Attribute msg
onLoad message =
  on "load" (Decode.succeed message)

view: Model -> Html Msg
view model =
    case model of
        Loading -> div []
                    [text "loading"
                    , button [ onClick Start ]
                        [
                            text "get"
                        ]
                    ]

        Loaded  -> 
                div []
                [ img [ src "image.png"
                      , hidden True
                      , onLoad ImgLoaded ]
                    [ ]
                , text "loading"
                ]

        Visible ->
                div []
                [ img [ src "image.png"
                      , hidden False
                      , onLoad ImgLoaded ]
                    [ ]
                ]

        Error err -> text err


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

main = Browser.element 
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    }


request: Cmd Msg
request = 
    Http.send Done <|
        Http.getString "image.png" 


imgDecoder : Decode.Decoder String
imgDecoder =
  Decode.field "data" (Decode.field "image_url" Decode.string)