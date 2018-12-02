module Jobs.Jobs exposing (Model, Msg(..), viewJobs, viewGrid, viewNewButton, viewNewModal, view, updateApp, initApp, encode, decode)

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
import Bootstrap.Utilities.Spacing as Spacing

import Json.Encode as Enco exposing (..) 
import Json.Decode as Deco exposing (..) 

import Http exposing(..) 

import Time exposing(..)
import Task exposing(..)

import Tools exposing(..)
import Ctx.Ctx as Ctx exposing(..)

import Gen.Task as BeTask exposing(..)
import Gen.Job as BeJob exposing(..)

initApp: Ctx.Context -> String -> (Model, Cmd Msg)
initApp ctx flags = 
            (Model Modal.hidden None 0 initSort [] 
            , Cmd.batch [ 
                    Ctx.createGetRequest ctx "jobs" |>
                    Http.send GetJobsResponse 
               ] 
            )


init: String -> (Model, Cmd Msg)
init flags = initApp Ctx.initCtx flags

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
    , photos: List String
    -- data for manipulating, do not serialize => not saved
    , view: ViewKind
    , editing: Maybe (List Task)
    }


updateTask: JobId -> String -> Bool -> List Job -> (List Job, Cmd Msg)
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
        (jobs |> List.map foreachjob, Cmd.none)

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
        | GetTime Time.Posix
        | DoneCreating 
        | CancelCreating

        -- update tasks job
        | UpdateJob JobId ViewKind
        | UpdateTask JobId String Bool

        -- sortBy 
        | SortBy Int OrderBy
    
        -- persistence answers
        | NewJobResponse (Result Http.Error String)
        | GetJobsResponse (Result Http.Error String)

        | DoWithTime (Time.Posix -> (Model, Cmd Msg)) Time.Posix 


updateApp: Ctx.Context -> Msg -> Model -> (Model, Cmd Msg)
updateApp ctx msg model =
    case msg of    

        Noop -> (model, Cmd.none)

        CreateJob -> 
            ({ model | 
                create = Modal.shown,
                creating = Job model.nextId "" "" initTasks [] Simple Nothing
                            |> Create
            }, Cmd.none)

        ChangeName newname -> 
            (case model.creating of
                Create job -> 
                    { model 
                    | creating = Job job.id newname job.desc job.tasks [] Simple Nothing
                                |> Create
                    }
                Edit job -> 
                    { model 
                    | creating = Job job.id newname job.desc job.tasks [] Simple Nothing
                                |> Edit
                    }
                None -> model
            , Cmd.none)

        ChangeDesc newdesc -> 
            (case model.creating of
                Create job -> 
                    { model 
                    | creating = Job job.id job.name newdesc job.tasks [] Simple Nothing 
                                |> Create
                    }
                Edit job -> 
                    { model 
                    | creating = Job job.id job.name newdesc job.tasks [] Simple Nothing
                                |> Edit
                    }
                None -> model
            , Cmd.none)

        GetTime _ -> (model, Cmd.none)

        DoneCreating -> 
            let
                request = (\job -> job |> encodeJob |>
                                Ctx.createJsonPutRequest ctx ("jobs/" ++ (Tools.tostr job.id)) |>
                                Http.send GetJobsResponse)
            in
                case model.creating of

                    None -> (model, Cmd.none)
                    Create newjob ->
                        ({ model | 
                            create = Modal.hidden,
                            creating = None,
                            nextId = model.nextId + 1,
                            jobs = model.jobs ++ [ newjob ]
                        }
                        , Cmd.batch [ request newjob ])
                    Edit newjob -> 
                        ({ model |
                            create = Modal.hidden,
                            creating = None,
                            jobs = setJob newjob model.jobs
                        }
                        , Cmd.none)


        CancelCreating -> ({ model | create = Modal.hidden } , Cmd.none)

        EditJob jobId -> 
            (case getJob jobId model.jobs of
                Nothing -> model
                Just job -> 
                        { model | 
                            create = Modal.shown,
                            creating = Edit job
                        }
            , Cmd.none)

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

                newjobs = case viewKind of
                    Extended ->  model.jobs |> Tools.mapif cond extend
                    Simple -> model.jobs |> Tools.mapif cond commitchanges

                saveCmd =
                    case Tools.getif newjobs (\j-> j.id == jobId) of
                        Nothing -> Cmd.none
                        Just j -> Cmd.batch[
                                    j |> encodeJob |>
                                    Ctx.createJsonPutRequest ctx ("jobs/" ++ (Tools.tostr j.id)) |>
                                    Http.send GetJobsResponse
                                ]
            in
            ( { model | 
                jobs = newjobs
              }
            , saveCmd)

        UpdateTask jobId taskName enabled -> 
            let 
                (jbs, msgs) = (updateTask jobId taskName enabled model.jobs) 
            in
                ({ model | 
                    jobs = jbs
                }
                , Cmd.batch [ msgs])

        SortBy col by ->  
            ({ model | sort =  by |> Tools.set col model.sort }
            , Cmd.none)

        NewJobResponse res -> (model, Cmd.none)
        GetJobsResponse res -> 
            case res of
                Err _ -> (model, Cmd.none)
                Ok jobs -> 
                    case decode jobs of
                        Nothing -> (model, Cmd.none)
                        Just m -> (m, Cmd.none)

        DoWithTime f t -> t |>  f

update: Msg -> Model -> (Model, Cmd Msg)
update msg model = updateApp Ctx.initCtx msg model

-- =================================================================
-- serialize routines

getNewTime : Cmd Msg
getNewTime =
  Task.perform GetTime Time.now

encodeJob: Job -> Enco.Value
encodeJob job = 
        job |> toBe |> BeJob.encode 

-- =========================================================
-- =========================================================

-- convert routines from the BE data into the state/data object for the FE 

toBe:  Job -> BeJob.Job
toBe job = 
    BeJob.Job job.id job.name 0.0 0.0 (Just job.desc) (Just job.tasks) (Just job.photos)

fromBe:  BeJob.Job -> Job
fromBe job = 
        Job 
            job.id 
            job.name 
            (Maybe.withDefault "" job.desc) 
            (Maybe.withDefault [] job.tasks)
            (Maybe.withDefault [] job.photos)
            -- default editing values
            Simple 
            Nothing


-- =========================================================
-- =========================================================


encode: Model -> Enco.Value
encode model = 
        model.jobs
            |> Enco.list encodeJob 


decode: String -> Maybe Model
decode str = 
    let
        tmpdeco = Deco.decodeString (Deco.list BeJob.decode) str
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
                    |> List.map fromBe
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
                  Card.align Text.alignSmLeft,
                  Card.attrs [Spacing.mt2 ] 
                ]
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
            [ viewTitle "Por empezar" 0 (Tools.get 0 model.sort)
            , model.jobs 
                |> List.filter (\job -> (computeCompletness job.tasks == 0.0))
                |> sortBy  (Tools.get 0 model.sort)
                |> viewJobs
            ]
        , Grid.col [ Col.textAlign Text.alignXsCenter ] 
            [ viewTitle "En progreso" 1 (Tools.get 1 model.sort)
            , model.jobs 
                |> List.filter (\job -> Tools.inExclusiveRange (computeCompletness job.tasks) (0,100))
                |> sortBy (Tools.get 1 model.sort)
                |> viewJobs

            ]
        , Grid.col [ Col.textAlign Text.alignXsCenter ] 
            [ viewTitle "Terminado" 2 (Tools.get 2 model.sort)
            , model.jobs 
                |> List.filter (\job -> (computeCompletness job.tasks == 100.0))
                |> sortBy (Tools.get 2 model.sort)
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


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

-- ============================================
-- server interaction

-- saveJobs: Model -> Cmd Msg
-- saveJobs jobs =
    -- let 
        -- withKey = \data -> ("jobs", data)
    -- in
    --    Cmd.batch [ jobs 
        -- |> encode 
        -- |> json2str 
        -- |> withKey 
        -- |> sendSave
        -- ]

view: Model -> Html Msg
view model = 
    div [] 
        [ viewNewButton model 
        , viewGrid model
        , viewNewModal model 
        ]

-- ============================================
--   make an app

main = Browser.element { init = init, update = update, view = viewStandAlone, subscriptions = subscriptions }


viewStandAlone: Model -> Html Msg
viewStandAlone model = 
    let 
        codedStr =  model |> encode |> Enco.encode 2
        decoded = decode codedStr
    in div [] 
        [ CDN.stylesheet 
        , view model
        ,div[]
            [ text "encoded:"
            , text codedStr
            ]
        ,div[]
            [ text "decoded:"
            ,  case decoded of
                    Nothing -> text "caca"
                    Just val -> viewGrid val
            ]
        ]