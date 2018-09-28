export default {
    data: function() {
      return {
        staffmember: {
          _id: "joern",
          name: "Willhöft",
          givenName: "Jörn"
        },
        billableOptions: [
          'yes', 'no', 'depends'
        ]
      };
    },
    methods: {
      showMessage: function(text, level) {
        this.$emit('pageMessageEvent', {text, level})
      }
    }
}
