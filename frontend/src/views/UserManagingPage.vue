<template>
  <v-content><v-container fluid><v-layout row wrap>
    <v-container fluid grid-list-md>
      <v-data-iterator
      :items="staffmembers"
      item-key="_id"
      :rows-per-page-items="rowsPerPageItems"
      :pagination.sync="pagination"
      content-tag="v-layout"
      row wrap
      >
        <template v-slot:item="props">
          <v-flex xs12 sm6 md4 lg3 >
            <v-card>
              <v-card-text>
                <h2 class="headline mb-2 text-xs-center">{{ props.item.givenName }} {{ props.item.name }}</h2>
                <div class="mb-2 text-xs-center">{{ props.item.email }}</div>
                <div class="subheading font-weight-bold text-xs-center">{{ props.item.alias }}</div>
              </v-card-text>
              <v-divider />
              <v-card-actions>
                <v-spacer />
                <v-btn icon @click="removeUser(props.item)"><v-icon>delete</v-icon></v-btn>
              </v-card-actions>
            </v-card>
          </v-flex>
        </template>
      </v-data-iterator>
    </v-container>
    <v-flex xs12>
      <v-btn @click="addUser">add user</v-btn>
      <v-btn @click="loadData">reset</v-btn>
    </v-flex>
  </v-layout></v-container></v-content>
</template>

<script>
  import Vue from 'vue'
  import pageMixin from '@/views/PageMixin.js'
  import axios from 'axios'
  import X2JS from 'x2js'

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
        pskey: -1,
        rowsPerPageItems: [4, 8, 12],
        pagination: {
          rowsPerPage: 4
        },
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
          const s = x2jsStaffmembers.xml2js(staffResponse.data).staff;
          self.staffmembers = s.staffmember
          self.showMessage('fetched!', 'info')
        })).catch(this.handleHttpError);
      },
      // TODO: implement addUser
      addUser: function() {
        console.log("add user")
      },
      // TODO: implement removeUser
      removeUser: function(user) {
        console.log("remove user", user)
      }
    }
  })
</script>
