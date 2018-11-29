import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)



-- MAIN


main =
  Browser.sandbox { init = init, update = update, view = view }



-- MODEL


type alias Model =
  { name : String
  , password : String
  , passwordAgain : String
  , age : String
  }


init : Model
init =
  Model "" "" "" ""



-- UPDATE


type Msg
  = Name String
  | Password String
  | PasswordAgain String
  | Age String


update : Msg -> Model -> Model
update msg model =
  case msg of
    Name name ->
      { model | name = name }

    Password password ->
      { model | password = password }

    PasswordAgain password ->
      { model | passwordAgain = password }

    Age age ->
      { model | age = age }


-- VIEW


view : Model -> Html Msg
view model =
  div []
    [ viewInput "text" "Name" model.name Name
    , viewInput "password" "Password" model.password Password
    , viewInput "password" "Re-enter Password" model.passwordAgain PasswordAgain
    , viewValidation model
    , viewInput "age" "Age" model.age Age
    ]


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
  input [ type_ t, placeholder p, value v, onInput toMsg ] []

viewValidation : Model -> Html msg
viewValidation model =
  let valid = validation model
  in
  case  valid of
  Ok ->
    div [ style "color" "green" ] [ text "OK" ]
  Nop why ->
    div [ style "color" "red" ] [ text why ]

type ValidationRes = 
    Ok | Nop String

validation : Model -> ValidationRes
validation model =
    let
        eq = 
            validationEq model
        len = 
            validationLen model
    in
        case (len, eq) of
            (Ok, Ok) -> Ok
            (Ok, Nop str) -> Nop str
            (Nop str, _) -> Nop str
    

validationLen : Model -> ValidationRes
validationLen model = 
    if String.length model.password >= 8 then
        Ok
    else
        Nop "Password is shorter than 8 characters"

validationEq : Model -> ValidationRes
validationEq model = 
    if model.password == model.passwordAgain then
        Ok
    else
        Nop "Passwords do not match"

