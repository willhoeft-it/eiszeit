module.exports = {
  publicPath: process.env.NODE_ENV === 'production' ? '/ui/'  : '/',
  // development proxy to running basex API
  devServer: {
    proxy: {
      '/api/': {
        target: 'http://localhost:8984/',
      }
    }
  }
}
