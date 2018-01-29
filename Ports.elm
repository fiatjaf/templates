port module Ports exposing (..)

port changed : (String, String) -> Cmd msg

port rendered : (String -> msg) -> Sub msg
