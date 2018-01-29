import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Platform.Sub as Sub
import Json.Encode

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
  { template : String
  , data : String
  , rendered : String
  }

type alias Flags =
  { initial_template : String
  , initial_data : String
  }


init : Flags -> (Model, Cmd Msg)
init {initial_template, initial_data} =
  ( Model
    initial_template
    initial_data
    ""
  , changed (initial_template, initial_data)
  )


-- UPDATE
type Msg
  = SetTemplate String
  | SetData String
  | GotRendered String
  | SaveTemplate String
  | SaveData String

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    SetTemplate t ->
      ( { model | template = t }
      , changed (t, model.data)
      )
    SetData d ->
      ( { model | data = d }
      , changed (model.template, d)
      )
    GotRendered r ->
      ( { model | rendered = r }, Cmd.none )
    SaveTemplate _ -> ( model, Cmd.none )
    SaveData _ -> ( model, Cmd.none )


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
    [ rendered GotRendered
    ]


-- VIEW


view : Model -> Html Msg
view {template, data, rendered} =
  div []
    [ nav [ class "navbar" ]
      [ div [ class "navbar-brand" ]
        [
        ]
      , div [ class "navbar-menu" ]
        [ 
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
              ] [ text template ]
            ]
          , div []
            [ textarea
              [ class "textarea"
              , placeholder "Parameters, use the YAML format"
              , name "params"
              , onInput SetData
              ] [ text data ]
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
      [ p [] [ a [ href "https://github.com/fiatjaf/templates", target "_blank" ] [ text "source" ] ]
      , p [] [ a [ href "https://fiatjaf.alhur.es/", target "_blank" ] [ text "author" ] ]
      ]
    ]
