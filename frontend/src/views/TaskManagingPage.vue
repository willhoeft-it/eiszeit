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
  import axios from 'axios'
  import pageMixin from '@/views/PageMixin.js'
  
  export default Vue.component('task-managing-page', {
    mixins: [pageMixin],
    data: function() {
      return {
        tasks: {
          task: []
        }
      };
    },
    created: function () {
      this.loadData();
    },
    methods: {
      loadData: function() {
        console.log("TODO: loadData")
      }
    }
  })
</script>
