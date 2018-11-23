module Route exposing (Route(..), fromUrl, replaceUrl)

import Browser.Navigation as Nav
import Html exposing (Attribute)
import Html.Attributes as Attr
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, oneOf, s, string)


-- ROUTING


type Route
    = Home
    | Feed
    | Kanban
    | Calendar
    | Settings


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Home Parser.top
        , Parser.map Feed (s "feed")
        , Parser.map Kanban (s "kanban")
        , Parser.map Calendar (s "calendar")
        , Parser.map Settings (s "settings")
        ]



-- PUBLIC HELPERS



replaceUrl : Nav.Key -> Route -> Cmd msg
replaceUrl key route =
    Nav.replaceUrl key (routeToString route)


fromUrl : Url -> Maybe Route
fromUrl url =
    -- The RealWorld spec treats the fragment like a path.
    -- This makes it *literally* the path, so we can proceed
    -- with parsing as if it had been a normal path all along.
    { url | path = Maybe.withDefault "" url.fragment, fragment = Nothing }
        |> Parser.parse parser



-- INTERNAL


routeToString : Route -> String
routeToString page =
    let
        pieces =
            case page of
                Home -> [""]
                Feed -> ["feed"]
                Kanban -> ["kanban"]
                Calendar -> ["calendar"]
                Settings -> ["settings"]

    in
    "#/" ++ String.join "/" pieces
