module Ctx.Ctx exposing (Context, initCtx, ctxWithToken, createFormPostRequest, createGetRequest, createJsonPutRequest)

import Html exposing (..)
import Browser exposing (..)
import Http exposing (..)
import Json.Encode as Enco exposing (..) 

-- ==========================================

type Context = NoAuth | WithJwt String

type alias RespFn msg = Result Http.Error String -> msg 

initCtx: Context
initCtx = NoAuth

ctxWithToken: Maybe String -> Context
ctxWithToken token =
    case token of
        Nothing -> NoAuth
        Just t -> WithJwt t

createFormPostRequest: Context -> String -> String -> RespFn msg -> Cmd msg
createFormPostRequest ctx url payload msg =  
    payload
        |> Http.stringBody "application/x-www-form-urlencoded"
        |> httpPost ctx url msg

createJsonPutRequest: Context -> String -> RespFn msg -> Enco.Value -> Cmd msg
createJsonPutRequest ctx url msg json_payload =  
    json_payload 
        |> Enco.encode 0 
        |> Http.stringBody "application/json"
        |> httpPut ctx url msg

createGetRequest: Context -> String -> RespFn msg -> Cmd msg
createGetRequest ctx url msg = 
    httpCompose "GET" ctx url msg Http.emptyBody 

httpPost: Context -> String -> RespFn msg -> Http.Body ->  Cmd msg
httpPost ctx url msg body  = httpCompose "POST" ctx url msg body

httpPut: Context -> String -> RespFn msg -> Http.Body ->  Cmd msg
httpPut ctx url msg body = httpCompose "PUT" ctx url msg body

httpCompose: String -> Context -> String -> RespFn msg -> Http.Body -> Cmd msg
httpCompose method ctx url msg body =
    let 
        header = 
            case ctx of
                NoAuth -> []
                WithJwt token -> [ Http.header "Authorization" ("Bearer " ++ token) ]
    in 
        Http.request
        { method = method
        , headers = header 
        , url = url
        , body = body
        , expect =  Http.expectString msg
        , timeout = Nothing
        , tracker = Nothing
        }

-- ==========================================
-- stand alone code for debug
