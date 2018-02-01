/* globals Elm */

const YAML = require('yaml-js')
const nunjucks = require('nunjucks')
const debounce = require('debounce')
const notie = require('notie')
const xtend = require('xtend')
const RemoteStorage = require('remotestoragejs')
const Widget = require('remotestorage-widget')
const markdown = require('markdown-it')({
  html: true,
  linkify: false,
  typographer: true
})

const initial_template = `[comment]: <> (a Markdown template goes here)

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
const initial_data = ` # and here some data to be applied to the template

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
  initial_template: localStorage.getItem('cached_template') || initial_template,
  initial_data: localStorage.getItem('cached_data') || initial_data
})

let rs = new RemoteStorage({logging: false})
rs.access.claim('templates', 'rw')
rs.caching.enable('/templates/template/')
rs.caching.enable('/templates/data/')

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

let md = rs.scope('/templates/template/')
let dt = rs.scope('/templates/data/')

function listTemplates () {
  md.getListing('')
    .then(listing => {
      app.ports.gottemplatelist.send(
        Object.keys(listing)
          .filter(name => name.slice(-1)[0] !== '/')
          .filter(name =>
            name.split('.').slice(-1)[0] === 'md' ||
            name.split('.').slice(-1)[0] === 'html'
          )
          .map(name => name.split('.').slice(0, -1).join('.'))
      )
    })
}

function listData () {
  dt.getListing('')
    .then(listing => {
      app.ports.gotdatalist.send(
        Object.keys(listing)
          .filter(name => name.slice(-1)[0] !== '/')
          .filter(name =>
            name.split('.').slice(-1)[0] === 'yaml' ||
            name.split('.').slice(-1)[0] === 'json'
          )
          .map(name => name.split('.').slice(0, -1).join('.'))
      )
    })
}

app.ports.loadtemplate.subscribe(name => {
  md.getFile(name + '.md')
    .then(res => {
      app.ports.gottemplate.send([name, res.data])
    })
    .catch(e => {
      console.log('failed to load template', e)
      notie.alert({
        type: 'error',
        text: `Failed to load '${name}'.`
      })
    })
})

app.ports.loaddata.subscribe(name => {
  dt.getFile(name + '.yaml')
    .then(res => {
      app.ports.gotdata.send([name, res.data])
    })
    .catch(e => {
      console.log('failed to load data', e)
      notie.alert({
        type: 'error',
        text: `Failed to load '${name}'.`
      })
    })
})

app.ports.deletetemplate.subscribe(name => {
  notie.confirm({
    text: `Are you sure you want to delete the template '${name}'?`
  }, () => {
    md.remove(name + '.md')
      .catch(e => {
        console.log('error deleting template', e)
        notie.alert({
          type: 'error',
          text: `Error deleting '${name}'.`
        })
      })
      .then(() => {
        listTemplates()
        notie.alert({
          type: 'success',
          text: `Deleted '${name}'.`
        })
      })
  })
})

app.ports.deletedata.subscribe(name => {
  notie.confirm({
    text: `Are you sure you want to delete the data '${name}'?`
  }, () => {
    dt.remove(name + '.yaml')
      .catch(e => {
        console.log('error deleting data', e)
        notie.alert({
          type: 'error',
          text: `Error deleting '${name}'.`
        })
      })
      .then(() => {
        listData()
        notie.alert({
          type: 'success',
          text: `Deleted '${name}'.`
        })
      })
  })
})

app.ports.savetemplate.subscribe(([name, template]) => {
  md.storeFile('text/njk+markdown', name + '.md', template)
    .catch(e => {
      console.log('error saving template', e)
      notie.alert({
        type: 'error',
        text: `Error saving '${name}'.`
      })
    })
    .then(() => {
      app.ports.saved.send(true)
      listTemplates()
      notie.alert({
        type: 'success',
        text: `Saved '${name}'!`
      })
    })
})

app.ports.savedata.subscribe(([name, data]) => {
  dt.storeFile('text/yaml', name + '.yaml', data)
    .catch(e => {
      console.log('error saving data', e)
      notie.alert({
        type: 'error',
        text: `Error saving '${name}'.`
      })
    })
    .then(() => {
      app.ports.saved.send(true)
      listData()
      notie.alert({
        type: 'success',
        text: `Saved '${name}'!`
      })
    })
})

app.ports.changed.subscribe(debounce(([template, data]) => {
  let params = YAML.load(data)

  try {
    let html = render(params, template)
    app.ports.rendered.send(html)
  } catch (e) {
    console.log('failed to render', e)
  }

  // save so this will be loaded on the next page reload
  localStorage.setItem('cached_template', template)
  localStorage.setItem('cached_data', data)
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
