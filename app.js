/* globals Elm */

const YAML = require('yaml-js')
const nunjucks = require('nunjucks')
const debounce = require('debounce')
const xtend = require('xtend')
const RemoteStorage = require('remotestoragejs')
const Widget = require('remotestorage-widget')
const markdown = require('markdown-it')({
  html: true,
  linkify: false,
  typographer: true
})

let template = `[comment]: <> (a Markdown template goes here)

## Receipt

**No.**: {{ loop.index }}
**Date**: {{ date }}

* **Received from**: {{ from }}
* **For payment of**: {{ quantity }} units of 100W incandescent light bulb
* **Amount**: $ {{ quantity * price }}

Paid by {{ paidby or 'cash' }}.

**Received by**: Alfred Telecom Inc.

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

Alfred, from Alfred Telecom

---


`
let data = ` # and here some data to be applied to the template

from: Julie Lights
price: 32
loop:
  - date: 3/14/2012
    quantity: 2
  - date: 4/27/2013
    quantity: 1
  - date: 7/1/2017
    quantity: 13
    paidby: bitcoin
`

let app = Elm.Main.fullscreen({
  initial_data: data,
  initial_template: template
})

let rs = new RemoteStorage({logging: false})
rs.access.claim('templates', 'rw')
rs.caching.enable('/templates/markdown/')
rs.caching.enable('/templates/data/yaml/')

rs.on('connected', () => {
  app.ports.logged.send(true)
  listData()
  listTemplates()
})
rs.on('disconnected', () => {
  app.ports.logged.send(false)
  app.ports.gottemplatelist.send([])
  app.ports.gotdatalist.send([])
})

let widget = new Widget(rs, {
  leaveOpen: false,
  autoCloseAfter: 4000
})
setTimeout(() => {
  widget.attach('rs-widget')
}, 1000)

let md = rs.scope('/templates/markdown/')
let dt = rs.scope('/templates/data/yaml/')

function listTemplates () {
  md.getListing('')
    .then(listing => {
      app.ports.gottemplatelist.send(
        Object.keys(listing)
          .filter(name => name.slice(-1)[0] !== '/')
      )
    })
}

function listData () {
  md.getListing('')
    .then(listing => {
      app.ports.gotdatalist.send(
        Object.keys(listing)
          .filter(name => name.slice(-1)[0] !== '/')
      )
    })
}

function fetchTemplate (name) {
  md.getObject(name)
    .then(template => {
      app.ports.gottemplate.send((name, template))
    })
}

function fetchData (name) {
  dt.getObject(name)
    .then(data => {
      app.ports.gotdata.send((name, data))
    })
}

app.ports.gettemplate.subscribe(fetchTemplate)
app.ports.getdata.subscribe(fetchData)

app.ports.save.subscribe((name, doc) => {
  // save
})

app.ports.changed.subscribe(debounce(([template, data]) => {
  let params = YAML.load(data)

  try {
    let html = render(params, template)
    app.ports.rendered.send(html)
  } catch (e) {
    console.log('failed to render', e)
  }
}, 500))

function render (params, template) {
  if (params.loop) {
    return '<div class=unit>' + params.loop.map((values, i) => {
      let data = xtend(params, values, {
        loop: {
          index: i + 1,
          index0: i,
          revindex: params.loop.length - i,
          revindex0: params.loop.length - i - 1,
          first: i === 0,
          last: i === (params.loop.length - 1),
          cycle: function () {
            return arguments[i % arguments.length]
          },
          depth: 0,
          depth0: -1
        }
      })
      let md = nunjucks.renderString(template, data)
      return markdown.render(md)
    }).join('</div><div class=unit>') + '</div>'
  } else {
    let md = nunjucks.renderString(template, params)
    return markdown.render(md)
  }
}
