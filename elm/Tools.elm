module Tools exposing (inExclusiveRange, get, set, json2str, enumerate, mapif, getif, tostr)

import Json.Encode as Enco exposing (..) 
import List.Extra as LE exposing (..)

inExclusiveRange: number -> (number, number) -> Bool
inExclusiveRange n (min, max) =
     n > min && n < max 


tostr v = Debug.toString v

get: Int -> (a, a, a) -> a
get n (f, s, t) = 
    if n == 0 then
        f
    else if n == 1 then
        s
    else if n == 2 then
        t
    else
        f

set: Int -> (a, a, a) -> a -> (a, a, a)
set n (f, s, t) val= 
    if n == 0 then
        (val, s, t)
    else if n == 1 then
        (f, val , t)
    else if n == 2 then
        (f, s, val)
    else
        (f, s, t)

json2str: Enco.Value -> String
json2str value = Enco.encode 2 value


enumerate: List a -> List (Int, a)
enumerate input =
    let 
        len = List.length input
        range = List.range 0 (len-1)
    in
        input |> LE.zip range 


getif: List a -> (a->Bool) -> Maybe a
getif list cond = list |> List.filter cond 
                    |> List.head

replaceif: List a -> (a->Bool) -> a -> List a
replaceif list cond newelem =
    let replace = \elem -> if cond elem then
                        newelem
                    else
                        elem
    in 
        list |> List.map replace 

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
