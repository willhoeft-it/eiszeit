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
      }
    }
}
