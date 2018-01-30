import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Platform.Sub as Sub
import Json.Encode
import Array exposing (Array)
import Tuple exposing (first, second)

import Ports exposing (..)


main =
  Html.programWithFlags
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


-- MODEL

type alias Model =
  { template : (String, String)
  , data : (String, String)
  , rendered : String
  , template_list : List String
  , data_list : List String
  , logged : Bool
  , show_list : Bool
  }

type alias Flags =
  { initial_template : String
  , initial_data : String
  }


init : Flags -> (Model, Cmd Msg)
init {initial_template, initial_data} =
  (
    { template = ("", initial_template)
    , data = ("", initial_data)
    , rendered = ""
    , template_list = []
    , data_list = []
    , logged = False
    , show_list = False
    }
  , changed (initial_template, initial_data)
  )


-- UPDATE

type Msg
  = SetTemplate String
  | SetData String
  | GotRendered String
  | GotLogged Bool
  | GotDataList (List String)
  | GotTemplateList (List String)
  | GotData (String, String)
  | GotTemplate (String, String)
  | ShowList Bool
  | Save

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    SetTemplate t ->
      ( { model | template = (first model.template, t) }
      , changed (t, second model.data)
      )
    SetData d ->
      ( { model | data = (first model.data, d) }
      , changed (second model.template, d)
      )
    GotRendered r -> ( { model | rendered = r }, Cmd.none )
    GotLogged logged -> ( { model | logged = logged }, Cmd.none )
    GotDataList list -> ( { model | data_list = list }, Cmd.none )
    GotTemplateList list -> ( { model | template_list = list }, Cmd.none )
    GotData t -> ( { model | data = t }, Cmd.none )
    GotTemplate t -> ( { model | template = t }, Cmd.none )
    ShowList show -> ( { model | show_list = show }, Cmd.none )
    Save ->
      ( model
      , Cmd.none
      )


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
    [ rendered GotRendered
    , logged GotLogged
    , gotdatalist GotDataList
    , gottemplatelist GotTemplateList
    , gotdata GotData
    , gottemplate GotTemplate
    ]


-- VIEW

view : Model -> Html Msg
view {template, data, logged, rendered, data_list, template_list, show_list} =
  div []
    [ nav [ class "navbar" ]
      [ div [ class "navbar-brand" ]
        [ a [ class "navbar-item" ] [ text "templates.alhur.es" ]
        ]
      , div [ class "navbar-menu" ]
        [ div [ class "navbar-start" ]
          [ div [ class "navbar-item" ]
            [ button
              [ class "button is-info"
              , disabled <| not logged
              , onClick (ShowList True)
              ] [ text "load" ]
            ]
          ]
        , div [ class "navbar-end" ]
          [ div [ id "rs-widget", class "navbar-item" ] []
          ]
        ]
      ]
    , div [ class "container" ]
      [ div [ class "columns" ]
        [ div [ class "column", id "input" ]
          [ p []
            [ b [] [ text "Press Ctrl+P to print the output." ]
            ]
          , div []
            [ textarea
              [ class "textarea"
              , placeholder "Template, use markdown with {{ variables }}"
              , name "template"
              , onInput SetTemplate
              ] [ text <| second template ]
            ]
          , div []
            [ textarea
              [ class "textarea"
              , placeholder "Parameters, use the YAML format"
              , name "params"
              , onInput SetData
              ]
              [ text <| second data ]
            ]
          ]
        , div
          [ class "column content"
          , id "output"
          , property "innerHTML" (Json.Encode.string rendered)
          ] []
        ]
      ]
    , footer [ class "footer" ]
      [ p []
        [ text "made by "
        , a [ href "https://fiatjaf.alhur.es/", target "_blank" ] [ text "fiatjaf" ]
        , text " and sources published on "
        , a [ href "https://github.com/fiatjaf/templates", target "_blank" ] [ text "GitHub" ] 
        , text "."
        ]
      ]
    ]
