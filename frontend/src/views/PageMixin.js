import axios from 'axios'

export default {
    data: function() {
      return {
        // TODO: staff members should be queried from database
        staff: [
          {
            _staffmemberId: "joern",
          },
          {
            _staffmemberId: "ute",
          },
        ],
        staffmember: {
          _staffmemberId: "joern",
          name: "Willhöft",
          givenName: "Jörn"
        },
        billableOptions: [
          'yes', 'no', 'depends'
        ],
        server: axios.create({
          timeout: 10000,
          headers: {'Content-Type': 'application/xml; charset=UTF-8'}
        })
      };
    },
    methods: {
      showMessage: function(text, level) {
        this.$emit('pageMessageEvent', {text, level})
      },
      handleHttpError: function(error) {
        if (error.response) {
          // The request was made and the server responded with a status code
          // that falls out of the range of 2xx
          console.log(error.response.data);
          console.log(error.response.status);
          console.log(error.response.headers);
          if (error.response.status == 401) {
            this.$emit('authFailEvent')
          }
          this.showMessage("ERROR " + error.response.status + ": " + error.response.data, 'error')
        } else if (error.request) {
          // The request was made but no response was received
          // `error.request` is an instance of XMLHttpRequest in the browser and an instance of
          // http.ClientRequest in node.js
          console.log(error.request);
          this.showMessage("ERROR : Failed contacting server", 'error')
        } else {
          // Something happened in setting up the request that triggered an Error
          console.log('Error', error.message);
          this.showMessage("ERROR : Failed setting up server request", 'error')
        }
      },
    }
}
