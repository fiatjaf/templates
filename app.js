import Rx from 'rx'

export default function app ({OUTPUT, params$, template$}) {
  let md$ = Rx.Observable.combineLatest(params$, template$, (params, template) => {
    try {
      return window.nunjucks.renderString(template, params)
    } catch (e) {
      return ''
    }
  })

  return {
    OUTPUT: md$
  }
}
