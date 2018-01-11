var path = require('path')

module.exports = {
  entry: './src/static/index.js',

  output: {
    path: path.resolve(__dirname + '/build'),
    filename: 'index.js',
  },

  module: {
    rules: [
      {
        test:    /\.html$/,
        exclude: /node_modules/,
        loader:  'file-loader?name=index.html'
      },
      {
        test: /\.(css|scss)$/,
        use: ['style-loader', 'css-loader']
      },
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        loader: 'elm-webpack-loader?verbose=true&warn=true&debug=true'
      }
    ],

    noParse: /\.elm$/
  }
}
