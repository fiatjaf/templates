import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Platform.Sub as Sub
import Json.Encode
import Array exposing (Array)
import Tuple exposing (first, second)
import String exposing (trim, words, join, isEmpty)
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
  , rendered : Maybe String
  , template_list : List String
  , data_list : List String
  , logged : Bool
  , showing_lists : Bool
  , showing_save : Bool
  , showing_help : Bool
  }

type alias Flags =
  { initial_template : String
  , initial_data : String
  }


init : Flags -> (Model, Cmd Msg)
init {initial_template, initial_data} =
  ( { template = ("", initial_template)
    , data = ("", initial_data)
    , rendered = Nothing
    , template_list = []
    , data_list = []
    , logged = False
    , showing_lists = False
    , showing_save = False
    , showing_help = False
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
  | DeleteTemplate String
  | DeleteData String
  | GotRendered String
  | GotLogged Bool
  | GotDataList (List String)
  | GotTemplateList (List String)
  | GotData (String, String)
  | GotTemplate (String, String)
  | ShowList Bool
  | ShowHelp Bool
  | PromptSave Bool
  | SaveTemplate
  | SaveData

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    SetTemplate t ->
      if not <| isEmpty <| trim t
        then
          ( { model | template = (first model.template, t) }
          , changed (t, second model.data)
          )
        else
          ( { model | template = (first model.template, t), rendered = Nothing }
          , Cmd.none
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
    LoadTemplate d -> ( model, loadtemplate d )
    LoadData d -> ( model, loaddata d )
    DeleteTemplate d -> ( model, deletetemplate d )
    DeleteData d -> ( model, deletedata d )
    GotRendered r -> ( { model | rendered = Just r }, Cmd.none )
    GotLogged logged -> ( { model | logged = logged }, Cmd.none )
    GotDataList list -> ( { model | data_list = list }, Cmd.none )
    GotTemplateList list -> ( { model | template_list = list }, Cmd.none )
    GotData t -> ( { model | data = t, showing_lists = False }, Cmd.none )
    GotTemplate t -> ( { model | template = t, showing_lists = False }, Cmd.none )
    ShowList s -> ( { model | showing_lists = s }, Cmd.none )
    ShowHelp s -> ( { model | showing_help = s }, Cmd.none )
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
    [ div [ class <| "modal help" ++ if model.showing_help then " is-active" else "" ]
      [ div [ class "modal-background", onClick (ShowHelp False) ] []
      , div [ class "modal-content" ]
        [ div [ class "box" ] [ help ]
        ]
      , div [ class "modal-close", onClick (ShowHelp False) ] []
      ]
    , div [ id "save", class <| "modal" ++ if model.showing_save then " is-active" else "" ]
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
      , div [ class "modal-close", onClick (PromptSave False) ] []
      ]
    , nav [ class "navbar" ]
      [ div [ class "navbar-brand" ]
        [ div [ class "navbar-item" ]
          [ span [ class "primary"] [ text "templates.alhur.es" ]
          , span [ class "secondary" ] [ text "mix data with templates" ] 
          , button [ class "button", onClick (ShowHelp True) ] [ text "?" ]
          ]
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
                , placeholder "Template, use Markdown with {{ variables }}."
                , name "template"
                , onInput SetTemplate
                ] [ text <| second model.template ]
              else if List.length model.template_list > 0
                then
                  ul [] <| List.map (loadable LoadTemplate DeleteTemplate) model.template_list
                else
                  text "No templates saved in your remoteStorage."
            ]
          , div []
            [ if not model.showing_lists
              then textarea
                [ class "textarea"
                , placeholder "Data, use the YAML format."
                , name "params"
                , onInput SetData
                ] [ text <| second model.data ]
              else if List.length model.data_list > 0
                then
                  ul [] <| List.map (loadable LoadData DeleteData) model.data_list
                else
                  text "No data blobs saved in your remoteStorage."
            ]
          ]
        , case model.rendered of
          Just "" -> div [ class "column help" ] [ help ]
          Nothing -> div [ class "column help" ] [ help ]
          Just html -> div
            [ class "column content"
            , id "output"
            , property "innerHTML" (Json.Encode.string html)
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

loadable : (String -> Msg) -> (String -> Msg) -> String -> Html Msg
loadable load delete name =
  li []
    [ div [ class "level" ]
      [ div [ class "level-left" ] 
        [ div [ class "level-item" ] [ a [ onClick (load name) ] [ text name ] ]
        ]
      , div [ class "level-right" ]
        [ div [ class "level-item" ]
          [ a [ class "delete", onClick (delete name) ] [ text "" ]
          ]
        ]
      ]
    ]

help : Html Msg
help =
  div []
    [ h2 [ class "title is-2" ] [ text "How does everything work?" ]
    , p []
      [ text "You write a template in the upper left box and the data in the bottom left box. The data gets merged with the template and is shown on the right side. You can press Ctrl-P or tell your browser to print and only the output will be printed. The other parts of the page will dissappear."
      ]
    , h3 [ class "title is-3" ] [ text "Template fundamentals" ]
    , p []
      [ text "You can write the template in "
      , a [ href "http://commonmark.org/help/", target "_blank" ] [ text "Markdown" ]
      , text " or HTML, or you can mix both."
      ]
    , p []
      [ text "To apply the variables defined in the data box (see below), use the "
      , code [] [ text "{{ variable_name }}" ]
      , text " syntax. For more advanced usage, you can check the "
      , a [ href "https://mozilla.github.io/nunjucks/templating.html", target "_blank" ] [ text "Nunjucks" ]
      , text " documentation, as that's the library used underneath. There are many pre-built filters, variable modifiers and other niceties you can use."
      ]
    , h3 [ class "title is-3" ] [ text "Data fundamentals" ]
    , p []
      [ text "Data is the place where you define the variables used in the templates. You can write it in the "
      , a [ href "https://en.wikipedia.org/wiki/YAML", target "_blank" ] [ text "YAML" ]
      , text "format, a superset of "
      , a [ href "https://en.wikipedia.org/wiki/JSON", target "_blank" ] [ text "JSON" ]
      , text " that's easier to write (basically you just do "
      , code [] [ text "key: value" ]
      , text " with your desired key and value for that key."
      ]
    , h2 [ class "title is-2" ] [ text "Repeating the template" ]
    , p []
      [ text "To facilitate the printing of multiple repeated documents with small changes in data between each one (for example, a more-or-less equal document that must be printed with the names of different people, or with multiple different dates), there's the special key "
      , code [] [ text "loop" ]
      , text "."
      ]
    , p []
      [ code [] [ text "loop" ]
      , text " expects a list of data groups consisting of keys and values. For each group on that list, a repeated version of the template will be generated. You write a single template and it can access, through the "
      , code [] [ text "{{ varname }}" ]
      , text " syntax, both the top-level data and the loop data."
      ]
    , p []
      [ text "Loops operate much like the "
      , a [ href "https://mozilla.github.io/nunjucks/templating.html#for", target "_blank" ]
        [ code [] [ text "for" ]
        ]
      , text " context of Nunjucks and has access to its special "
      , code [] [ text "loop." ]
      , text " variables too."
      ]
    ]
