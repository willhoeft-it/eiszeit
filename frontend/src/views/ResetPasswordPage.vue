<template>
  <v-content><v-container fluid><v-layout row wrap>
    <v-container fluid grid-list-md>
      <!-- TODO Without access token, do not allow to enter password -->
      <!-- TODO: if user is logged in, do not require / use access token and staffmemberId, but oldCred instead -->
      <h1>Reset your password here</h1>
      <div>Your ID: {{staffmemberId}}</div>
      <v-text-field placeholder="password" v-model="passwd" required :rules="passwdRules" :append-icon="passwdShow ? 'visibility' : 'visibility_off'" :type="passwdShow ? 'text' : 'password'" @click:append="passwdShow = !passwdShow" />
      <v-text-field placeholder="again" v-model="passwd2" required :rules="passwd2Rules" :type="passwdShow ? 'text' : 'password'" />
    </v-container>
    <v-flex xs12>
      <v-btn color="green"  @click="submit">OK</v-btn>
    </v-flex>
  </v-layout></v-container></v-content>
</template>

<script>
  import Vue from 'vue'
  import pageMixin from '@/views/PageMixin.js'

  export default Vue.component('reset-password-page', {
    mixins: [pageMixin],
    props: ['staffmemberId','accessToken'],
    data: function() {
      return {
        passwd: "",
        passwdShow: false,
        passwd2: "",
        passwdRules: [
          v => !!v || 'Password required',
          v => !v || /^[\w\x7f-\xff.,_()@$!%*#?&]+$/.test(v) || 'Only letters, numbers and .,_()@$!%*#?& allowed',
          v => !v || v.length >= 6 || 'Must be 6 characters minimum',
          v => !v || v.length <= 30 || 'Must be less than 30 characters',
          v => !v || /^(?=.*[\w\x7f-\xff])(?=.*[.,_()@$!%*#?&])[\w\x7f-\xff.,_()@$!%*#?&]+$/.test(v) || 'Must contain at least one letter and one of .,_()@$!%*#?&'
        ],
        passwd2Rules: [
          v => !!v || 'Please repeat password',
          v => !v || v === this.passwd || 'Passwords must match'
        ]
      };
    },
    created: function () {
    },

    computed: {

    },
    methods: {
      submit: function() {
        console.log('submit')
        const self = this

        // TODO: signature check fails. url encode? 
        this.server.post(
          '../api/users/user/' + this.staffmemberId + '/password',
          'newCred=' + this.passwd + '&accessToken=' + this.accessToken,
          { headers: {'Content-Type': 'application/x-www-form-urlencoded' } }
        ).then(function () {
          self.showMessage("Password set!", 'success');
          // TODO route to / or close or say ok
        }).catch(this.handleHttpError);
      }
    }
  })

</script>
