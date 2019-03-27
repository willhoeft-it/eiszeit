<template>
  <v-content><v-container fluid><v-layout row wrap>
    <v-flex xs12>
      <v-layout>
        <v-flex xs6>

        </v-flex>
      </v-layout>
    <v-btn @click="addUser">add user</v-btn>
    </v-flex>
    <v-flex xs12>
      <v-btn @click="loadData">reset</v-btn>
    </v-flex>
  </v-layout></v-container></v-content>
</template>

<script>
  import Vue from 'vue'
  import pageMixin from '@/views/PageMixin.js'
  import axios from 'axios'

  // eslint-disable-next-line
  const x2jsStaffmembers = new X2JS({
    arrayAccessFormPaths : [ 'staff.staffmember' ]
  })

  export default Vue.component('user-managing-page', {
    mixins: [pageMixin],
    props: {
      staffmember: Object
    },
    data: function() {
      return {
        staffmembers: [],
        // Page scope unique key generator. Uses negative keys to avoid conflicts with ids from back end
        // Back end will generate new keys for all new items
        pskey: -1
      };
    },
    created: function () {
      this.loadData();
    },
    computed: {

    },
    methods: {
      loadData: function() {
        console.log("loadData")
        const self = this
        axios.all([
          self.server.get('../api/staff')
        ]).then(axios.spread(function(staffResponse) {
          const s = x2jsStaffmembers.xml_str2json(staffResponse.data).staff;
          self.staffmembers = s.staffmember
          self.showMessage('fetched!', 'info')
        })).catch(this.handleHttpError);
      },
      addUser: function() {
        console.log("add user")
      }
    }
  })
</script>
