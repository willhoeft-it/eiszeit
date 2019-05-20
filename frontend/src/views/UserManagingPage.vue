<template>
  <v-content><v-container fluid><v-layout row wrap>
    <v-container fluid grid-list-md>
      <v-dialog v-model="editDialog" persistent max-width="300px">
        <v-card>
          <v-card-text>
            <div class="headline mb-2 text-xs-center">
              <v-text-field ref="editGivenName" placeholder="given name" v-model="modUser.givenName"/>
              <v-text-field placeholder="name" v-model="modUser.name"/>
            </div>
            <!-- TODO: validate email -->
            <div class="mb-2 text-xs-center"><v-text-field placeholder="email" v-model="modUser.email"/></div>
            <div class="subheading font-weight-bold text-xs-center"><v-text-field placeholder="alias" v-model="modUser.alias"/></div>
          </v-card-text>
          <v-divider />
          <v-card-actions>
            <v-spacer />
            <v-btn icon @click="saveUser(modUser)"><v-icon>check</v-icon></v-btn>
            <v-btn icon @click="clearUser(modUser)"><v-icon>cancel</v-icon></v-btn>
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
            <v-card>
              <v-card-text>
                <h2 class="headline mb-2 text-xs-center">{{ props.item.givenName }} {{ props.item.name }}</h2>
                <div class="mb-2 text-xs-center">{{ props.item.email }}</div>
                <div class="subheading font-weight-bold text-xs-center">{{ props.item.alias }}</div>
              </v-card-text>
              <v-divider />
              <v-card-actions>
                <v-spacer />
                <v-btn icon @click="editUser(props.item)"><v-icon>edit</v-icon></v-btn>
                <v-btn icon @click="removeUser(props.item)"><v-icon>delete</v-icon></v-btn>
              </v-card-actions>
            </v-card>
          </v-flex>
        </template>
      </v-data-iterator>
    </v-container>
    <v-flex xs12>
      <v-btn @click.stop="editUser(null)"><v-icon>add</v-icon></v-btn>
      <v-btn @click="loadData">reset</v-btn>
    </v-flex>
  </v-layout></v-container></v-content>
</template>

<script>
  import Vue from 'vue'
  import pageMixin from '@/views/PageMixin.js'
  import _ from 'lodash'
  import axios from 'axios'
  import X2JS from 'x2js'

  const x2jsStaffmembers = new X2JS({
    arrayAccessFormPaths : [ 'staff.staffmember' ]
  })
  const x2jsStaffmember = new X2JS()

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
        editDialog: false,
        modUser: {}
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
        this.editDialog = false
        this.modUser = {}
      },
      editUser: function(user) {
        console.log("edit user", user)
        if (user) {
          const u = _.clone(user)
          this.modUser = u
        } else {
          const id = this.pskey--
          this.modUser = {
            _id: id,
            givenName: "",
            name: "",
            email: "",
            alias: ""
          }
        }
        this.editDialog = true
        this.$nextTick(() => this.$refs.editGivenName.focus())
      },
      saveUser: function(user) {
        console.log("save user", user)

        const xmlDocStr = x2jsStaffmember.js2xml({
          staffmember: user
        })
        const self = this
        self.server.post('../users/user', xmlDocStr).then(function () {
          self.showMessage("saved!", 'success');
          self.loadData()
          self.editDialog = false
        }).catch(this.handleHttpError);
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
