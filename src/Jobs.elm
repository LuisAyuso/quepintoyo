module Jobs exposing (Model, Msg(..), viewJobs, viewGrid, viewNewButton, viewNewModal, update, init, encode, decode)

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

import Json.Encode as Enco exposing (..) 
import Json.Decode as Deco exposing (..) 

import Tools 

init: Model
init = Model Modal.hidden Nothing 0 []
     -- [ Job 1 "massive darkness" initTasks Simple Nothing
     -- , Job 2 "star trek" initTasks Simple Nothing ]

type alias Task = 
    { done: Bool
    , name: String
    }

initTasks: List Task
initTasks = 
    [ Task False "Montado"
    , Task False "Imprimado"
    , Task False "Capa Base"
    , Task False "Luces"
    , Task False "Peana"
    , Task False "Barnizado"
    ]

type ViewKind = Simple | Extended

type alias JobId = Int

type alias Job = 
    { id: JobId
    , name: String
    , tasks: List Task
    , view: ViewKind
    , editing: Maybe (List Task)
    }

mapif: (a -> Bool) -> (a -> a) -> List a -> List a
mapif condition transform list =
    let 
        f = \elem ->
            if condition elem then
                transform elem
            else
                elem
    in
        list |> List.map f


updateTask: JobId -> String -> Bool -> List Job -> List Job
updateTask id taskName toggle jobs =
    let 
        foreachtask = \task ->
            if taskName == task.name then
                { task | done = toggle }
            else
                task

        foreachjob = \job ->
            if id == job.id then
            case job.editing of
                Just tasks ->
                    { job | 
                        editing = Just (List.map foreachtask tasks) 
                    }
                Nothing -> job
            else
                job
    in
        (List.map foreachjob jobs)


type alias Model = 
  { create: Modal.Visibility
  , creating: Maybe Job
  , nextId: JobId
  , jobs: List Job
  }


type Msg = Noop 

        -- create job
         | CreateJob 
         | ChangeName String
         | DoneCreating Job
         | CancelCreating

        -- update tasks job
         | UpdateJob JobId ViewKind
         | UpdateTask JobId String Bool


update: Msg -> Model -> Model
update msg model =
    case msg of    

        Noop -> model

        CreateJob -> 
            { model | 
                create = Modal.shown,
                creating = Just (Job model.nextId "" initTasks Simple Nothing)
            }

        ChangeName newname -> 
            case model.creating of
                Just job -> { model | creating = Just (Job job.id newname initTasks Simple Nothing)}
                Nothing -> model

        DoneCreating newjob -> 
            let
                newJobs = model.jobs ++ [ newjob ]
            in
                { model | 
                    create = Modal.hidden,
                    creating = Nothing,
                    nextId = model.nextId + 1,
                    jobs = newJobs
                }

        CancelCreating -> { model | create = Modal.hidden }

        UpdateJob jobId viewKind -> 
            let 
                cond = \job -> job.id == jobId
                commitchanges = \job -> 
                    case job.editing of
                        Just l -> 
                            { job |
                                view = viewKind,
                                tasks = l,
                                editing = Nothing
                            }
                        Nothing -> job
                extend = \job -> 
                            { job |
                                view = viewKind,
                                editing =  Just job.tasks
                            }
            in
                case viewKind of
                    Extended -> 
                        { model | 
                            jobs = model.jobs |> mapif cond extend
                        }
                    Simple -> 
                        { model | 
                            jobs = model.jobs |> mapif cond commitchanges
                        }

        UpdateTask jobId taskName enabled -> 
            { model | 
                jobs = (updateTask jobId taskName enabled model.jobs) 
            }

-- =================================================================
-- help routines

encodeTask: Task -> Enco.Value
encodeTask task = Enco.object 
    [ ("name", Enco.string task.name)
    , ("done", Enco.bool task.done)
    ]

encodeJob: Job -> Enco.Value
encodeJob job = Enco.object 
    [ ("id", Enco.int job.id ) 
    , ("name", Enco.string job.name ) 
    , ("tasks",
        job.tasks |> Enco.list (\task -> encodeTask task)
      )
    ]

encode: Model -> Enco.Value
encode model = 
        model.jobs
            |> Enco.list (\job -> encodeJob job)


decodeTask : Deco.Decoder Task
decodeTask =
  map2 Task
      (Deco.field "done" Deco.bool)
      (Deco.field "name" Deco.string)

type alias TmpJob = 
    { id: JobId
    , name: String
    , tasks: List Task
    }

decodeJob : Deco.Decoder TmpJob
decodeJob =
  map3 TmpJob
      (Deco.field "id" Deco.int)
      (Deco.field "name" Deco.string)
      (Deco.field "tasks" (Deco.list decodeTask))

decode: String -> Maybe Model
decode str = 
    let
        tmpdeco = Deco.decodeString (Deco.list decodeJob) str
        maybecount =
            case tmpdeco of 
                Ok jobs -> jobs 
                    |> List.map (\j -> j.id)
                    |> List.maximum
                Err _ -> Nothing
        count =
            case maybecount of 
                Just n -> n + 1
                _ -> 0
    in
       case tmpdeco of 
           Ok jobs ->  
                jobs
                    |> List.map (\j -> Job j.id j.name j.tasks Simple Nothing)
                    |> Model Modal.hidden Nothing count
                    |> Just
           Err _ -> Nothing
        

-- =================================================================
-- View routines

viewTask: (Task, JobId) -> Html Msg
viewTask (task, jobId) =
    Checkbox.checkbox 
        [ Checkbox.checked task.done
        , Checkbox.onCheck (UpdateTask jobId task.name)
        ] task.name


matchTask2Jobs: List Task -> JobId -> List (Task, JobId)
matchTask2Jobs tasks jobId =
    (List.map (\task -> (task, jobId)) tasks)


computeCompletness: List Task -> Float
computeCompletness tasks =
    let 
        count = \task i ->
            if task.done then
                i+1
            else
                i
    in
      (List.foldr count 0 tasks) / (toFloat (List.length tasks)) * 100.0


viewExtendedJob: Job -> Html Msg
viewExtendedJob job =
    let 
        tasks = 
            case job.editing of
                Nothing -> []
                Just t -> t
    in
        Form.form []
        [ Form.group []
                (List.map viewTask (matchTask2Jobs tasks job.id) )
        , Progress.progress
                [ Progress.info
                , Progress.value (computeCompletness tasks)
                ]
        , br [] []
        , Button.button 
            [ Button.primary
            , Button.onClick (UpdateJob job.id Simple) 
            ] 
            [ text "Guardar" 
            ]
        ]


viewSimpleJob: Job -> Html Msg
viewSimpleJob job =
    div[]
    [   Progress.progress
            [ Progress.info
            , Progress.value (computeCompletness job.tasks)
            ]
    , Button.button 
        [ Button.primary
        , Button.onClick (UpdateJob job.id Extended) 
        ] 
        [ text "Actualizar" ]
    ]


viewJob: Job -> Html Msg
viewJob job =
    Card.config [ Card.outlineSecondary ]
       |> Card.headerH4 [] [ text job.name ]
       |> Card.block []
           [ Block.custom <| 
               div [] 
               [
                   case job.view of
                      Simple -> viewSimpleJob job
                      Extended -> viewExtendedJob job
               ]
           ]
       |> Card.view


viewJobs: List Job -> Html Msg
viewJobs jobs = 
    div []
        (List.map viewJob jobs)


viewGrid: Model -> Html Msg
viewGrid model = 
  Grid.container [] 
    [ Grid.row []
        [ Grid.col [] 
            [ text "Por empezar"
            , model.jobs 
                |> List.filter (\job -> (computeCompletness job.tasks == 0.0))
                |> viewJobs
            ]
        , Grid.col [] 
            [ text "En progreso"
            , model.jobs 
                |> List.filter (\job -> Tools.inExclusiveRange (computeCompletness job.tasks) (0,100))
                |> viewJobs

            ]
        , Grid.col [] 
            [ text "Terminado"
            , model.jobs 
                |> List.filter (\job -> (computeCompletness job.tasks == 100.0))
                |> viewJobs
            ]
        ]
    ]

viewNewButton: Model -> Html Msg
viewNewButton model = 
    div []
    [ Button.button [ Button.primary
                    , Button.onClick CreateJob
                    ] 
        [ text "Hacer algo nuevo"]
    ] 

viewNewModal: Model -> Html Msg
viewNewModal model =
    case model.creating of
        Nothing -> div [][]

        Just job -> 
            Modal.config (DoneCreating job)
                |> Modal.small
                |> Modal.hideOnBackdropClick True
                |> Modal.h3 [] [ text "Nuevo Trabajo" ]
                |> Modal.body [] 
                    [ p [] 
                        [ InputGroup.config
                            (InputGroup.text [ Input.onInput ChangeName])
                            |> InputGroup.predecessors
                                [ InputGroup.span [] 
                                    [ text "Nombre:" 
                                    ]
                                ]
                            |> InputGroup.view
                        ]
                    ]
                |> Modal.footer []
                    [ Button.button
                        [ Button.outlinePrimary
                        , Button.attrs [ onClick (DoneCreating job) ]
                        ]
                        [ text "Listo" ]
                    , Button.button
                        [ Button.outlineSecondary
                        , Button.attrs [ onClick CancelCreating ]
                        ]
                        [ text "Cancelar" ]
                    ]
                |> Modal.view model.create


-- ============================================
--   make an app

main = Browser.sandbox { init = init, update = update, view = viewStandAlone }

viewStandAlone: Model -> Html Msg
viewStandAlone model = 
        let 
            codedStr =  model |> encode |> Enco.encode 2
            decoded = decode codedStr
        in
    div [] 
    [ CDN.stylesheet 
    , viewGrid model
    , viewNewButton model 
    , viewNewModal model 
    ,div[]
        [ text "encoded:"
        , text codedStr
        ]
    ,div[]
        [ text "decoded:"
        ,  
            case decoded of
                Nothing -> text "caca"
                Just val -> viewGrid val
        ]
    ]