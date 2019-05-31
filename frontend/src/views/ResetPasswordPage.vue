<template>
  <v-content><v-container fluid><v-layout row wrap>
    <v-container fluid grid-list-md>
      <h1>Reset your password here</h1>
      <div>{{myPath}}</div>
      <div>{{myQuery}}</div>
    </v-container>

  </v-layout></v-container></v-content>
</template>

<script>

  // TODO: implement this. 


  import Vue from 'vue'
  import pageMixin from '@/views/PageMixin.js'


  export default Vue.component('reset-password-page', {
    mixins: [pageMixin],
    props: {
    },
    data: function() {
      return {
        myPath: "(none)",
        myQuery: "(none)"
      };
    },
    created: function () {

    },
    // TODO: remove this
    beforeRouteEnter (to, from, next) {
      next(vm => {
        vm.myPath = to.path
        vm.myQuery = to.query
      })
    },

    computed: {

    },
    methods: {
    }
  })

</script>
