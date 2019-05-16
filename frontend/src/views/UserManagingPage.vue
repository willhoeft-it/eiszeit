<template>
  <v-content><v-container fluid><v-layout row wrap>
    <v-container fluid grid-list-md>
      <v-dialog v-model="newDialog" persistent max-width="300px">
        <template v-slot:activator="{ on }">
          <v-btn :disabled="editing" v-on="on"><v-icon>add</v-icon></v-btn>
        </template>
        <v-card>
          <!-- TODO: set focus to first name on dialog open. "autofocus" does nothing-->
          <v-card-text>
            <div class="headline mb-2 text-xs-center">
              <v-text-field placeholder="given name" v-model="newUser.givenName"/>
              <v-text-field placeholder="name" v-model="newUser.name"/>
            </div>
            <div class="mb-2 text-xs-center"><v-text-field placeholder="email" v-model="newUser.email"/></div>
            <div class="subheading font-weight-bold text-xs-center"><v-text-field placeholder="alias" v-model="newUser.alias"/></div>
          </v-card-text>
          <v-divider />
          <v-card-actions>
            <v-spacer />
            <v-btn icon @click="addUser(newUser)"><v-icon>check</v-icon></v-btn>
            <v-btn icon @click="clearUser(newUser)"><v-icon>cancel</v-icon></v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>

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
            <v-card v-if="props.item._status==='edit'">
              <v-card-text>
                <div class="headline mb-2 text-xs-center">
                  <v-text-field placeholder="given name" v-model="props.item.givenName"/>
                  <v-text-field placeholder="name" v-model="props.item.name"/>
                </div>
                <!-- TODO: validate email -->
                <div class="mb-2 text-xs-center"><v-text-field placeholder="email" v-model="props.item.email"/></div>
                <div class="subheading font-weight-bold text-xs-center"><v-text-field placeholder="alias" v-model="props.item.alias"/></div>
              </v-card-text>
              <v-divider />
              <v-card-actions>
                <v-spacer />
                <v-btn icon @click="saveUser(props.item)"><v-icon>check</v-icon></v-btn>
              </v-card-actions>
            </v-card>
            <v-card v-else>
              <v-card-text>
                <h2 class="headline mb-2 text-xs-center">{{ props.item.givenName }} {{ props.item.name }}</h2>
                <!-- TODO: validate email -->
                <div class="mb-2 text-xs-center">{{ props.item.email }}</div>
                <div class="subheading font-weight-bold text-xs-center">{{ props.item.alias }}</div>
              </v-card-text>
              <v-divider />
              <v-card-actions>
                <v-spacer />
                <v-btn icon :disabled="editing" @click="editUser(props.item)"><v-icon>edit</v-icon></v-btn>
                <v-btn icon @click="removeUser(props.item)"><v-icon>delete</v-icon></v-btn>
              </v-card-actions>
            </v-card>

          </v-flex>
        </template>
      </v-data-iterator>
    </v-container>
    <v-flex xs12>
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
        editing: false,
        newDialog: false,
        newUser: {}
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
      clearUser: function() {
        this.newDialog = false
        this.newUser = {
          _status: "changed",
          _id: "",
          givenName: "",
          name: "",
          email: "",
          alias: ""
        }
      },
      addUser: function(user) {
        console.log("add user")
        this.newDialog = false
        const u = _.clone(user)
        const id = this.pskey--
        u._id = id
        this.staffmembers.push(u)
        this.clearUser()
      },
      editUser: function(user) {
        console.log("edit user", user)
        user._status = 'edit'
        this.editing = true
      },
      // TODO: implement saveUser to db
      saveUser: function(user) {
        console.log("save user", user)
        user._status = 'changed'
        this.editing = false
      },
      // TODO: implement removeUser from db
      removeUser: function(user) {
        console.log("remove user", user)
        if (user._id < 0)
          this.staffmembers.splice(this.staffmembers.indexOf(user), 1)
      }
    }
  })
</script>
