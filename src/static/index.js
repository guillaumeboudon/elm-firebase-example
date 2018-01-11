require('./index.html')

var Elm = require('../elm/Main.elm')
var app = Elm.Main.embed(document.getElementById('main'))
