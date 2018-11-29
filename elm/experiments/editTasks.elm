
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Browser.Navigation as Navigation
import Browser exposing (UrlRequest)
import Url exposing (Url)
import Url.Parser as UrlParser exposing ((</>), Parser, s, top)
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Button as Button
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

main = Browser.sandbox { init = init, update = update, view = viewStandAlone }

init: Model
init = Model "header" initTasks False

type alias Task = (Bool, String)

initTasks: List Task
initTasks = 
    [ (False, "Montado")
    , (False, "Imprimado")
    , (False, "Capa Base")
    , (False, "Luces")
    , (False, "Peana")
    , (False, "Barnizado")
    ]

type alias Model = 
  { title: String
  , tasks: List Task
  , editing: Bool
  }

type Msg = Noop 
         | TitleChange String


update: Msg -> Model -> Model
update msg model =
    case msg of    
        Noop -> model
        TitleChange str -> { model | title = str }


viewTask: (Bool, String) -> Html Msg
viewTask (done, name) =
    Checkbox.checkbox [Checkbox.checked done] name

editTask: (Bool, String) -> Html Msg
editTask (done, name) =
    div[]
    [ InputGroup.config
        (InputGroup.text [ Input.placeholder name])
        |> InputGroup.predecessors
            [ InputGroup.span [] [ text "tarea"] ]
        |> InputGroup.successors
                    [ InputGroup.button [ Button.primary ] [ text "Cambiar"] 
                    , InputGroup.button [ Button.danger ] [ text "Eliminar"] 
                    ]
        |> InputGroup.view
    ]

viewForm: Model -> Html Msg
viewForm model =
    Form.form []
    [ Form.group []
        [ Form.label [for "taskTittle"] [ text "Nombre:"]
        , Input.email [ Input.id "taskTittle" ]
        , Form.help [] [ text "Nombre de la tarea, que es que vas a pintar." ]
        ]
    , Form.group []
            (List.map editTask model.tasks) 
    , Button.button [ Button.primary] [ text "Guardar" ]
    , Button.button [ Button.secondary] [ text "Cancelar" ]
    ]

view: Model -> Html Msg
view model = 

    Card.config [ Card.outlineDanger ]
       |> Card.headerH4 [] [ text "Editar Trabajo" ]
       |> Card.block []
           [ Block.custom <| 
               div []
               [ viewForm model
               ]    
           ]
       |> Card.view


viewStandAlone: Model -> Html Msg
viewStandAlone model = 
  Grid.container [] 
    [ CDN.stylesheet
    , Grid.row []
        [ Grid.col []
            [ 
                view model
            ]
        ]
    ]