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
import Bootstrap.Text as Text

import Json.Encode as Enco exposing (..) 
import Json.Decode as Deco exposing (..) 

import Tools exposing(..)

init: Model
init = Model Modal.hidden None 0 initSort []
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
    , desc: String
    , tasks: List Task
    -- data for manipulating, not saved
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

getJob: JobId -> List Job -> Maybe Job
getJob id jobs = 
    jobs |> List.filter (\j -> j.id == id) |> List.head

setJob:  Job -> List Job -> List Job
setJob newJob jobs = 
    let 
        replace = \job ->
            if job.id == newJob.id then
                newJob
            else
                job 
    in
        jobs |> List.map replace

-- =================================================================
-- =================================================================

initSort = (ById orderById, ById orderById, ById orderById)

orderById: Job -> Int
orderById job = job.id

orderByName: Job -> String
orderByName job = job.name

orderByCompletion: Job -> Float
orderByCompletion job = 100 - (computeCompletness job.tasks)

sortBy: OrderBy -> (List Job) -> (List Job)
sortBy order list =
    case order of
        ByName o -> List.sortBy o list
        ById o -> List.sortBy o list
        ByCompetion o -> List.sortBy o list 

type OrderBy = ByName (Job -> String)
             | ById (Job -> Int)
             | ByCompetion (Job -> Float)

-- =================================================================
-- =================================================================

type ModalMode = None
            | Create Job
            | Edit Job


type alias Model = 
  { create: Modal.Visibility
  , creating: ModalMode 
  , nextId: JobId
  , sort: (OrderBy, OrderBy, OrderBy)
  , jobs: List Job
  }

type Msg = Noop 

        -- create/edit job
        | CreateJob 
        | EditJob JobId
        | ChangeName String
        | ChangeDesc String
        | DoneCreating 
        | CancelCreating

        -- update tasks job
        | UpdateJob JobId ViewKind
        | UpdateTask JobId String Bool

        -- sortBy 
        | SortBy Int OrderBy


update: Msg -> Model -> Model
update msg model =
    case msg of    

        Noop -> model

        CreateJob -> 
            { model | 
                create = Modal.shown,
                creating = Create (Job model.nextId "" "" initTasks Simple Nothing)
            }

        ChangeName newname -> 
            case model.creating of
                Create job -> { model | creating = Create (Job job.id newname job.desc job.tasks Simple Nothing)}
                Edit job -> { model | creating = Edit (Job job.id newname job.desc job.tasks Simple Nothing)}
                None -> model

        ChangeDesc newdesc -> 
            case model.creating of
                Create job -> { model | creating = Create (Job job.id job.name newdesc job.tasks Simple Nothing)}
                Edit job -> { model | creating = Edit (Job job.id job.name newdesc job.tasks Simple Nothing)}
                None -> model

        DoneCreating -> 
            case model.creating of
                None -> model
                Create newjob ->
                    { model | 
                        create = Modal.hidden,
                        creating = None,
                        nextId = model.nextId + 1,
                        jobs = model.jobs ++ [ newjob ]
                    }
                Edit newjob -> 
                    { model |
                        create = Modal.hidden,
                        creating = None,
                        jobs = setJob newjob model.jobs
                    }

        CancelCreating -> { model | create = Modal.hidden }

        EditJob jobId -> 
            case getJob jobId model.jobs of
                Nothing -> model
                Just job -> 
                        { model | 
                            create = Modal.shown,
                            creating = Edit job
                        }

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

        SortBy col by ->  
            { model | sort =  by |> Tools.set col model.sort }


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
    , ("desc", Enco.string job.desc ) 
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
    , desc: Maybe String
    , tasks: List Task
    }


decodeJob : Deco.Decoder TmpJob
decodeJob =
  map4 TmpJob
      (Deco.field "id" Deco.int)
      (Deco.field "name" Deco.string)
      (Deco.maybe <| Deco.field "desc" Deco.string)
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
                    |> List.map (\j -> Job j.id j.name (Maybe.withDefault "" j.desc) j.tasks Simple Nothing)
                    |> Model Modal.hidden None count initSort
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
        [ text job.desc
        , Form.group []
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
        , Button.button 
            [ Button.secondary
            , Button.onClick (EditJob job.id) 
            ] 
            [ text "Editar" 
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
    Card.config [ Card.outlineSecondary,
                  Card.align Text.alignSmLeft ]
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


viewTitle: String -> Int -> OrderBy -> Html Msg
viewTitle title col sort = 
    let
        id = ById orderById
        name = ByName orderByName
        prog = ByCompetion orderByCompletion

        isOn = \order -> sort == order

        firstColor = 
            if isOn id then
                Button.primary
            else
                Button.secondary

        secondColor = 
            if isOn name then
                Button.primary
            else
                Button.secondary

        thirdColor = 
            if isOn prog then
                Button.primary
            else
                Button.secondary
    in
        div []
            [ Html.h2 [] [text title]
            , Button.button [ firstColor
                            , Button.small
                            , Button.onClick (SortBy col id)
                            ] 
                [ text "fecha"]
            , Button.button [ secondColor 
                            , Button.small
                            , Button.onClick (SortBy col name)
                            ] 
                [ text "nombre"]
            , Button.button [ thirdColor
                            , Button.small
                            , Button.onClick (SortBy col prog)
                            ] 
                [ text "progreso"]
            ]


viewGrid: Model -> Html Msg
viewGrid model = 
  Grid.container [] 
    [ Grid.row []
        [ Grid.col [ Col.textAlign Text.alignXsCenter ] 
            [ viewTitle "Por empezar" 0 (get 0 model.sort)
            , model.jobs 
                |> List.filter (\job -> (computeCompletness job.tasks == 0.0))
                |> sortBy  (get 0 model.sort)
                |> viewJobs
            ]
        , Grid.col [ Col.textAlign Text.alignXsCenter ] 
            [ viewTitle "En progreso" 1 (get 1 model.sort)
            , model.jobs 
                |> List.filter (\job -> Tools.inExclusiveRange (computeCompletness job.tasks) (0,100))
                |> sortBy (get 1 model.sort)
                |> viewJobs

            ]
        , Grid.col [ Col.textAlign Text.alignXsCenter ] 
            [ viewTitle "Terminado" 2 (get 2 model.sort)
            , model.jobs 
                |> List.filter (\job -> (computeCompletness job.tasks == 100.0))
                |> sortBy (get 2 model.sort)
                |> viewJobs
            ]
        ]
    ]


viewNewButton: Model -> Html Msg
viewNewButton model = 
    Button.button [ Button.primary
                    , Button.onClick CreateJob
                    ] 
        [ text "Hacer algo nuevo"]


viewNewModal: Model -> Html Msg
viewNewModal model =
    let 
        modalDialog =  \title job ->
            Modal.config (DoneCreating)
                |> Modal.large
                |> Modal.hideOnBackdropClick True
                |> Modal.h3 [] [ text title ]
                |> Modal.body [] 
                    [ InputGroup.config
                        (InputGroup.text 
                            [ Input.placeholder job.name
                            , Input.onInput ChangeName
                            ])
                        |> InputGroup.predecessors
                            [ InputGroup.span [] 
                                [ text "Nombre:" 
                                ]
                            ]
                        |> InputGroup.view
                    , InputGroup.config
                        (InputGroup.text 
                            [ Input.placeholder job.desc
                            , Input.onInput ChangeDesc
                            ])
                        |> InputGroup.predecessors
                            [ InputGroup.span [] 
                                [ text "Descripción:" 
                                ]
                            ]
                        |> InputGroup.view
                    ]
                |> Modal.footer []
                    [ Button.button
                        [ Button.outlinePrimary
                        , Button.attrs [ onClick (DoneCreating) ]
                        ]
                        [ text "Listo" ]
                    , Button.button
                        [ Button.outlineSecondary
                        , Button.attrs [ onClick CancelCreating ]
                        ]
                        [ text "Cancelar" ]
                    ]
                |> Modal.view model.create
    in
        case model.creating of
            None -> div [][]
            Create job -> modalDialog "Nuevo Trabajo" job
            Edit job   -> modalDialog "Editar Trabajo" job


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