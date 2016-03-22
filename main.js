import Cycle from '@cycle/core'
import Rx from 'rx'
import yaml from 'js-yaml'

const editor = new window.SimpleMDE({
  element: document.querySelector('textarea[name="template"]'),
  autosave: {
    enabled: true,
    delay: 4000,
    uniqueId: 'template'
  },
  indentWithTabs: false,
  spellChecker: false
})
editor.render()

import app from './app'

const paramsDriver = function () {
  return Rx.Observable.timer(1000, 1000)
    .map(() => document.querySelector('textarea[name="params"]').value)
    .map(v => {
      try {
        return yaml.load(v)
      } catch (e) {
        return {}
      }
    })
}

const templateDriver = function () {
  return Rx.Observable.timer(1000, 1000)
    .map(() => editor.value())
    .startWith('# alô')
}

const HTMLDriver = function (html$) {
  html$.subscribe(html => {
    let el = document.querySelector('#output')
    if (el.innerHTML === html) return
    el.innerHTML = html
  })
}

Cycle.run(app, {
  OUTPUT: HTMLDriver,
  params$: paramsDriver,
  template$: templateDriver
})
