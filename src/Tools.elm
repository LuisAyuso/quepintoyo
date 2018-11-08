module Tools exposing (inExclusiveRange)


inExclusiveRange: number -> (number, number) -> Bool
inExclusiveRange n (min, max) =
     n > min && n < max 