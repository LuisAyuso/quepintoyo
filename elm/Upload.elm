port module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onCheck, targetValue, on, onSubmit)

import Http exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation as Navigation

import Json.Decode as Decode
import Json.Encode as Encode

-- ==============================================================

port sendOpenFile : String -> Cmd msg
port recvOpenFile : (FilePortData -> msg) -> Sub msg

type alias FilePortData =
    { filename : String
    , contents : String
    }

-- ==============================================================

type alias Model =
    { uploadState : State
    , id : String
    }

type State 
    = None
    | Upload String
    | Done

type Msg 
    = NoOp 
    | StartUpload FilePortData
    | UploadResult (Result Error ()) 
    | FileSelected 
    | FormSubmited 

-- ==============================================================

view: Model -> Html Msg
view model =
    div []
        [ Html.form
            [ onSubmit FormSubmited
            ]
            [ input
                [ type_ "file"
                , id model.id
                , on "change" (Decode.succeed FileSelected)
                ]
                []
            , button [ type_ "submit" ]
                [ text "submit" ]
            ]
        ]


update: Msg -> Model -> (Model, Cmd Msg)
update msg model = 
    case msg of
        FileSelected ->  (model, Cmd.batch [ sendOpenFile model.id ])
        StartUpload data -> 
            ( model
            , fileUploadRequest data  |> Http.send UploadResult 
            )
        UploadResult (Err e) -> (model, Cmd.none)
        UploadResult (Ok _) -> (model, Cmd.none)
        _ -> (model, Cmd.none)


init: String -> (Model, Cmd msg)
init flags = (Model None "InputId", Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
     Sub.batch [ recvOpenFile StartUpload ]


fileUploadRequest : FilePortData -> Http.Request ()
fileUploadRequest { filename, contents } =
    let
        body =
            Encode.object
                [ ( "filename", Encode.string filename )
                , ( "contents", Encode.string contents )
                ]
    in
        Http.post "upload" (jsonBody body) (Decode.succeed ())


main = Browser.element 
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    }
