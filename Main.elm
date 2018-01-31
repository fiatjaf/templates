import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Platform.Sub as Sub
import Json.Encode
import Array exposing (Array)
import Tuple exposing (first, second)
import String exposing (trim, words, join)
import List exposing (take)

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
  , showing_lists : Bool
  , showing_save : Bool
  }

type alias Flags =
  { initial_template : String
  , initial_data : String
  }


init : Flags -> (Model, Cmd Msg)
init {initial_template, initial_data} =
  ( { template = ("", initial_template)
    , data = ("", initial_data)
    , rendered = ""
    , template_list = []
    , data_list = []
    , logged = False
    , showing_lists = False
    , showing_save = False
    }
  , changed (initial_template, initial_data)
  )


-- UPDATE

type Msg
  = SetTemplate String
  | SetData String
  | SetTemplateName String
  | SetDataName String
  | LoadTemplate String
  | LoadData String
  | GotRendered String
  | GotLogged Bool
  | GotDataList (List String)
  | GotTemplateList (List String)
  | GotData (String, String)
  | GotTemplate (String, String)
  | ShowList Bool
  | PromptSave Bool
  | SaveTemplate
  | SaveData

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
    SetTemplateName n ->
      ( { model | template = (n, second model.template) }
      , Cmd.none
      )
    SetDataName n ->
      ( { model | data = (n, second model.data) }
      , Cmd.none
      )
    LoadTemplate d -> ( model, gettemplate d )
    LoadData d -> ( model, getdata d )
    GotRendered r -> ( { model | rendered = r }, Cmd.none )
    GotLogged logged -> ( { model | logged = logged }, Cmd.none )
    GotDataList list -> ( { model | data_list = list }, Cmd.none )
    GotTemplateList list -> ( { model | template_list = list }, Cmd.none )
    GotData t -> ( { model | data = t, showing_lists = False }, Cmd.none )
    GotTemplate t -> ( { model | template = t, showing_lists = False }, Cmd.none )
    ShowList s -> ( { model | showing_lists = s }, Cmd.none )
    PromptSave s -> ( { model | showing_save = s } , Cmd.none )
    SaveTemplate -> (model, savetemplate model.template)
    SaveData -> (model, savedata model.data)


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
    , saved (\_ -> PromptSave False)
    ]


-- VIEW

view : Model -> Html Msg
view model =
  div []
    [ div [ id "save", class <| "modal" ++ if model.showing_save then " is-active" else "" ]
      [ div [ class "modal-background", onClick (PromptSave False) ] []
      , div [ class "modal-content" ]
        [ div [ class "box" ]
          [ div [ class "level" ]
            [ div [ class "level-left" ]
              [ p [ class "level-item" ] [ text "Save current template with name " ]
              , p [ class "level-item" ] 
                [ input
                  [ value <| first model.template
                  , onInput SetTemplateName
                  ] []
                ]
              , p [ class "level-item" ] [ text "? " ]
              ]
            , div [ class "level-right" ]
              [ div [ class "level-item" ]
                [ button [ class "button is-primary", onClick SaveTemplate ] [ text "Save" ]
                ]
              ]
            ]
          ]
        , div [ class "box" ]
          [ div [ class "level" ]
            [ div [ class "level-left" ]
              [ p [ class "level-item" ] [ text "Save current data with name " ]
              , p [ class "level-item" ] 
                [ input
                  [ value <| first model.data
                  , onInput SetDataName
                  ] []
                ]
              , p [ class "level-item" ] [ text "? " ]
              ]
            , div [ class "level-right" ]
              [ div [ class "level-item" ]
                [ button [ class "button is-primary", onClick SaveData ] [ text "Save" ]
                ]
              ]
            ]
          ]
        ]
      ]
    , nav [ class "navbar" ]
      [ div [ class "navbar-brand" ]
        [ a [ class "navbar-item" ] [ text "templates.alhur.es" ]
        ]
      , div [ class "navbar-menu" ]
        [ div [ class "navbar-start" ]
          <| if not model.showing_lists
            then
              [ div [ class "navbar-item" ]
                [ button
                  [ class "button is-info"
                  , disabled <| not model.logged
                  , onClick (ShowList True)
                  ] [ text "Load" ]
                ]
              , div [ class "navbar-item" ]
                [ button
                  [ class "button is-success"
                  , disabled <| not model.logged
                  , onClick (PromptSave True)
                  ] [ text "Save" ]
                ]
              ]
            else
              [ div [ class "navbar-item" ]
                [ button
                  [ class "button is-warning"
                  , onClick (ShowList False)
                  ] [ text "Cancel" ]
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
          [ div []
            [ if not model.showing_lists
              then textarea
                [ class "textarea"
                , placeholder "Template, use markdown with {{ variables }}"
                , name "template"
                , onInput SetTemplate
                ] [ text <| second model.template ]
              else if List.length model.template_list > 0
                then
                  let fn t = li [] [ a [ onClick (LoadTemplate t) ] [ text t ] ]
                  in ul [] <| List.map fn model.template_list
                else
                  text "No templates saved in your remoteStorage."
            ]
          , div []
            [ if not model.showing_lists
              then textarea
                [ class "textarea"
                , placeholder "Parameters, use the YAML format"
                , name "params"
                , onInput SetData
                ] [ text <| second model.data ]
              else if List.length model.data_list > 0
                then
                  let fn t = li [] [ a [ onClick (LoadData t) ] [ text t ] ]
                  in ul [] <| List.map fn model.data_list
                else
                  text "No data blobs saved in your remoteStorage."
            ]
          ]
        , div
          [ class "column content"
          , id "output"
          , property "innerHTML" (Json.Encode.string model.rendered)
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
