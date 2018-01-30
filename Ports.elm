port module Ports exposing (..)

port changed : (String, String) -> Cmd msg
port save : () -> Cmd msg
port gettemplate : String -> Cmd msg
port getdata : String -> Cmd msg

port rendered : (String -> msg) -> Sub msg
port logged : (Bool -> msg) -> Sub msg
port gottemplatelist : (List String -> msg) -> Sub msg
port gotdatalist : (List String -> msg) -> Sub msg
port gottemplate : ((String, String) -> msg) -> Sub msg
port gotdata : ((String, String) -> msg) -> Sub msg
