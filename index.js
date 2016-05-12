'use strict'

const siml = require('siml')

class SIMLAngularBrunch {

  constructor(config) {
    this.config = (config && config.plugins && config.plugins.siml) || {}
  }

  compile(file) {

    let data = siml.angular.parse(file.data)

    data = data.replace(/'/g, "\\'")
    data = data.replace(/\n/g, "\\n")

    data = `module.exports = '${data}'`

    return Promise.resolve({
      data
    })
  }
}

SIMLAngularBrunch.prototype.type = 'template'
SIMLAngularBrunch.prototype.extension = 'siml'
SIMLAngularBrunch.prototype.brunchPlugin = true

module.exports = SIMLAngularBrunch
