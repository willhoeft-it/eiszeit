<template>
  <v-content><v-container fluid><v-layout row wrap>
    <v-container fluid grid-list-md>
      <v-dialog v-model="editDialog" persistent max-width="300px">
        <v-card>
          <v-card-text>
            <v-form ref="userForm" v-model="userFormValid" lazy-validation>
              <v-text-field ref="editGivenName" placeholder="given name" v-model="modUser.givenName" required :rules="givenNameRules"/>
              <v-text-field placeholder="name" v-model="modUser.name" required :rules="nameRules"/>
              <v-text-field placeholder="email" v-model="modUser.email" :rules="emailRules"/>
              <v-text-field placeholder="alias" v-model="modUser.alias" required :rules="aliasRules"/>
            </v-form>
          </v-card-text>
          <v-divider />
          <v-card-actions>
            <v-spacer />
            <v-btn :disabled="!userFormValid" icon @click="saveUser(modUser)"><v-icon>check</v-icon></v-btn>
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
                <v-menu v-model="resetPasswordUrl" :disabled="(! props.item._id) || (props.item._id < 0)" :close-on-content-click="false" :nudge-width="400" left >
                  <template v-slot:activator="{ on }">
                    <v-btn icon v-on="on" @click="resetPassword(props.item)"><v-icon small>fas fa-key</v-icon></v-btn>
                  </template>
                  <v-card tile>
                    <v-text-field
                      outline
                      single-line
                      v-model="resetPasswordUrl"
                      @focus="clipboardAccessTokenUrl($event)"
                      append-icon="fas fa-paste"
                    />
                  </v-card>
                </v-menu>
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
  const x2js = new X2JS();

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
        modUser: {},
        userFormValid: false,
        resetPasswordUrl: "",
        givenNameRules: [
          v => !!v || 'Given name is required',
          v => !v || /^[\w\x7f-\xff .]+$/.test(v) || 'No special characters allowed',
          v => !v || v.length <= 40 || 'Given name must be less than 40 characters'
        ],
        nameRules: [
          v => !!v || 'Name is required',
          v => !v || /^[\w\x7f-\xff .]+$/.test(v) || 'No special characters allowed',
          v => !v || v.length <= 40 || 'Name must be less than 40 characters'
        ],
        emailRules: [
          v => !v || /^([^@]+@[^.]+\..+)?$/.test(v) || 'E-mail must be valid',
          v => !v || v.length <= 40 || 'E-mail must be less than 40 characters'
        ],
        aliasRules: [
          v => !!v || 'Alias is required',
          v => !v || /^[a-z0-9]+$/.test(v) || 'Alias may contain only lower case letters',
          v => !v || v.length <= 10 || 'Alias must be less than 10 characters'
        ]
      };
    },
    created: function () {
      this.loadData();
    },
    computed: {

    },
    methods: {
      loadData: function() {
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
        if (user) {
          const u = _.clone(user)
          this.modUser = u
        } else {
          const id = this.pskey--
          this.modUser = {
            _id: id,
            givenName: "",
            // email,
            name: "",
            alias: ""
          }
        }
        this.editDialog = true
        this.$nextTick(() => this.$refs.editGivenName.focus())
      },
      saveUser: function(user) {
        const u = _.omitBy(user, v => (_.isEmpty(v) && !_.isNumber(v)) )
        const xmlDocStr = x2js.js2xml({
          staffmember: u
        })
        const self = this
        self.server.post('../api/users/user', xmlDocStr).then(function () {
          self.showMessage("saved!", 'success');
          self.loadData()
          self.editDialog = false
        }).catch(this.handleHttpError);
      },
      removeUser: function(user) {
        if (! (user || user._id)) return;
        if (user._id < 0)
          this.staffmembers.splice(this.staffmembers.indexOf(user), 1)
        else {
          const self = this
          self.server.delete('../api/users/user/' + user._id).then(function () {
            self.showMessage("deleted!", 'success');
            self.loadData()
            self.editDialog = false
          }).catch(this.handleHttpError);
        }
      },
      resetPassword: function(user) {
        console.log("reset password")
        if (! (user || user._id || user._id < 0)) return;
        const path = "../api/users/user/" + user._id + "/password"
        const url = new URL(path, window.location.href)
        const self = this
        self.server.get('../api/token?path=' + encodeURIComponent(url.pathname)).then(function(tokenResponse) {
          const resetUrl = new URL("#/resetPassword", window.location.href)
          self.resetPasswordUrl =  resetUrl.href + "?staffmemberId=" + user._id + "&accessToken=" + encodeURIComponent(x2js.xml2js(tokenResponse.data).token);
        }).catch(this.handleHttpError);
      },
      clipboardAccessTokenUrl(event) {
        event.target.select()
        const success = document.execCommand('copy');
        if (success) this.showMessage('Password reset link copied to clipboard', 'success')
        else this.showMessage('Copy to clipboard failed', 'error')
        this.resetPasswordUrl = ""
      },
    }
  })
</script>
