module Ctx.Ctx exposing (Context, initCtx, ctxWithToken, createFormPostRequest, createGetRequest)

import Html exposing (..)
import Browser exposing (..)
import Http exposing (..)

-- ==========================================

type Context = NoAuth | WithJwt String

initCtx: Context
initCtx = NoAuth

ctxWithToken: Maybe String -> Context
ctxWithToken token =
    case token of
        Nothing -> NoAuth
        Just t -> WithJwt t

createFormPostRequest: Context -> String -> String -> Http.Request String
createFormPostRequest ctx url payload =  
    payload
        |> Http.stringBody "application/x-www-form-urlencoded"
        |> httpPost ctx url

createGetRequest: Context -> String -> Http.Request String
createGetRequest ctx url = 
    httpCompose "GET" ctx url Http.emptyBody

httpPost: Context -> String -> Http.Body ->  Http.Request String
httpPost ctx url body = httpCompose "POST" ctx url body

httpCompose: String -> Context -> String -> Http.Body -> Http.Request String
httpCompose method ctx url body =
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
            , expect = Http.expectString
            , timeout = Nothing
            , withCredentials = False
            } 

-- ==========================================
-- stand alone code for debug
