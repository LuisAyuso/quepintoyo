module Tools exposing (inExclusiveRange, get, set)


inExclusiveRange: number -> (number, number) -> Bool
inExclusiveRange n (min, max) =
     n > min && n < max 


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