module Feed.Feed exposing (Model, Msg(..), updateApp, initApp, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http exposing (..)
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
import Ctx.Ctx as Ctx exposing(..)


type alias NewsEntry = 
    { title: String
    , content: String
    , photos: Maybe (List String)
    , link: Maybe String --Url
    }

decodeNewsEntry: Deco.Decoder NewsEntry
decodeNewsEntry =
    Deco.map4 NewsEntry
        (Deco.field "title" Deco.string)
        (Deco.field "content" Deco.string)
        (Deco.maybe (Deco.field "photos" (Deco.list Deco.string)))
        (Deco.maybe (Deco.field "link" Deco.string))

decodeNews: Deco.Decoder (List NewsEntry)
decodeNews = 
    Deco.list decodeNewsEntry

type alias Model = 
    { entries: List NewsEntry
    , errStr: String
    }

type Msg = NoOp
    | NewsResponse (Result Http.Error String)
    | GotStr String


-- ============================================================
-- ============================================================

initApp: Ctx.Context -> String -> (Model, Cmd Msg)
initApp ctx flags = (Model  [] "no error"

                    -- [ NewsEntry "one" "two" Nothing Nothing
                    -- , NewsEntry "two" "fasgfasfqa" Nothing Nothing
                    -- ] "no error"
            , Cmd.batch [ 
                    Ctx.createGetRequest ctx "news" |>
                    Http.send NewsResponse 
               ] 
            )


init: String -> (Model, Cmd Msg)
init flags = 
    initApp Ctx.initCtx flags


updateApp: Ctx.Context -> Msg -> Model -> (Model, Cmd Msg)
updateApp ctx msg model =
    case msg of
        NewsResponse res -> 
            case res of
                Ok json -> 
                    case Deco.decodeString decodeNews json of
                        Ok news -> ({model | entries = news }, Cmd.none)
                        Err _ -> ({model | errStr = "parse error"}, Cmd.none)
                Err error -> ({model | errStr = "recv error"}, Cmd.none)
        _ -> ({model | errStr = "caca"}, Cmd.none)

update: Msg -> Model -> (Model, Cmd Msg)
update msg model = updateApp Ctx.initCtx msg model

getColumn: Int -> Int -> List a -> List a
getColumn col cols list = 
    list |> Tools.enumerate 
         |> List.filter (\(i,e) -> (modBy 4 i) == col)
         |> List.map (\(_,e) -> e)

viewNewsEntry: NewsEntry -> Html Msg
viewNewsEntry entry = 
            Card.config [ Card.outlinePrimary ]
                |> Card.headerH4 [] [ text entry.title ]
                |> Card.block []
                    [ 
                        -- Block.text [] [ text entry.content ]
                     Block.custom <| 
                        a [ Maybe.withDefault "" entry.link |> href
                          , target "_blank"
                          , rel  "noopener noreferrer" ][
                            case entry.photos of
                                Nothing -> text "no hay fotos"
                                Just (img_url::_)  -> img [src  img_url
                                                          , width 210 ][]
                                Just (_)  -> text "no hay fotos"
                        ]
                    ]
                |> Card.view

view: Model -> Html Msg
view model = 
    div []
    [ Grid.container [] 
        [ Grid.row []
            [ model.entries 
                    |> getColumn 0 4
                    |> List.map viewNewsEntry
                    |> Grid.col [Col.xs3]
            , model.entries 
                    |> getColumn 1 4
                    |> List.map viewNewsEntry
                    |> Grid.col [Col.xs3]
            , model.entries 
                    |> getColumn 2 4
                    |> List.map viewNewsEntry
                    |> Grid.col [Col.xs3]
            , model.entries 
                    |> getColumn 3 4
                    |> List.map viewNewsEntry
                    |> Grid.col [Col.xs3]
            ]
        ]
    , text model.errStr
    ]