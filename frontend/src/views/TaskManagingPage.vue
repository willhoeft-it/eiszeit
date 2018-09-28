<template>
   <v-content><v-container grid-list-md><v-layout row wrap>
    <v-flex xs6>
      <h2>User: {{staffmember.givenName}} {{staffmember.name}}</h2>
    </v-flex>
    <v-flex xs12>
      <h2>Tasks</h2>
    </v-flex>
  </v-layout></v-container></v-content>
</template>

<script>
  import Vue from 'vue'
  import pageMixin from '@/views/PageMixin.js'
  
  const x2jsTasks = new X2JS({
    arrayAccessFormPaths : [
      /.+.projectGroup/,
      /.+.project/,
      /.+.member/,
      /.+.taskGroup/,
      /.+.task/
    ]
  });
  
  export default Vue.component('task-managing-page', {
    mixins: [pageMixin],
    data: function() {
      return {
        tasks: {
        }
      };
    },
    created: function () {
      this.loadData();
    },
    methods: {
      loadData: function() {
        console.log("loadData")
        const self = this
        self.server.get('../api/tasks/').then(function(taskResponse) {
          console.log("tasks:")
          console.log(taskResponse);
          const t = x2jsTasks.xml_str2json(taskResponse.data).tasks;
          self.tasks = t
          self.showMessage('fetched!', 'info')
        }).catch(function (error) {
          if (error.response) {
            // The request was made and the server responded with a status code
            // that falls out of the range of 2xx
            console.log(error.response.data);
            console.log(error.response.status);
            console.log(error.response.headers);
            self.showMessage("ERROR " + error.response.status + ": " + error.response.data, 'error')
          } else if (error.request) {
            // The request was made but no response was received
            // `error.request` is an instance of XMLHttpRequest in the browser and an instance of
            // http.ClientRequest in node.js
            console.log(error.request);
            self.showMessage("ERROR : Failed contacting server", 'error')
          } else {
            // Something happened in setting up the request that triggered an Error
            console.log('Error', error.message);
            self.showMessage("ERROR : Failed setting up server request", 'error')
          }
        });
      }
    }
  })
</script>
