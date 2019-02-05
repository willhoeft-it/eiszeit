module.exports = {
  publicPath: process.env.NODE_ENV === 'production' ? '/timetracking/static/'  : '/',
  // development proxy to running basex API
  devServer: {
    proxy: {
      '/api/': {
        target: 'http://localhost:8984/timetracking/',
      }
    }
  }
    /*
    chainWebpack: config => {
    // javascript libraries that are not available via npm and linked by script tag in index.html. Files in /public folder

    config.externals({
      'xml2json', 'X2JS'
    })
  }
*/

}
