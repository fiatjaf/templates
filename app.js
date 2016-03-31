import Rx from 'rx'
import marked from 'marked'
import xtend from 'xtend'

export default function app ({OUTPUT, params$, template$}) {
  let html$ = Rx.Observable.combineLatest(params$, template$, (params = {}, template) => {
    var loopvalues = [{}]
    if (params.loop) {
      loopvalues = params.loop
    }

    try {
      return '<div class=unit>' + loopvalues.map((values, i) => {
        let data = xtend(params, values, {
          loop: {
            index: i + 1,
            index0: i,
            revindex: loopvalues.length - i,
            revindex0: loopvalues.length - i - 1,
            first: i === 0,
            last: i === (loopvalues.length - 1),
            cycle: function () {
              return arguments[i % arguments.length]
            },
            depth: 0,
            depth0: -1
          }
        })
        let md = window.nunjucks.renderString(template, data)
        return marked(md)
      }).join('</div><div class=unit>') + '</div>'
    } catch (e) {
      return ''
    }
  })

  return {
    OUTPUT: html$
  }
}
