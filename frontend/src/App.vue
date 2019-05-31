<template>
  <v-app :dark="darkTheme">
    <v-navigation-drawer v-model="drawer" fixed app >
      <v-list dense>
        <v-list-tile to='/dashboard'>
          <v-list-tile-action>
            <v-icon>fas fa-chart-line</v-icon>
          </v-list-tile-action>
          <v-list-tile-content>
            <v-list-tile-title>dashboard</v-list-tile-title>
          </v-list-tile-content>
        </v-list-tile>
        <v-list-tile to='/dailyBooking'>
          <v-list-tile-action>
            <v-icon>fas fa-clipboard</v-icon>
          </v-list-tile-action>
          <v-list-tile-content>
            <v-list-tile-title>daily booking</v-list-tile-title>
          </v-list-tile-content>
        </v-list-tile>
        <v-list-tile to='/taskManaging'>
          <v-list-tile-action>
            <v-icon>fas fa-tasks</v-icon>
          </v-list-tile-action>
          <v-list-tile-content>
            <v-list-tile-title>task managing</v-list-tile-title>
          </v-list-tile-content>
        </v-list-tile>
        <v-list-tile to='/userManaging'>
          <v-list-tile-action>
            <v-icon>fas fa-users</v-icon>
          </v-list-tile-action>
          <v-list-tile-content>
            <v-list-tile-title>user managing</v-list-tile-title>
          </v-list-tile-content>
        </v-list-tile>
        <v-list-tile to='/reportProjects'>
          <v-list-tile-action>
            <v-icon>fas fa-money-check-alt</v-icon>
          </v-list-tile-action>
          <v-list-tile-content>
            <v-list-tile-title>report on projects</v-list-tile-title>
          </v-list-tile-content>
        </v-list-tile>
        <v-list-tile to='/reportWorkingtime'>
          <v-list-tile-action>
            <v-icon>fas fa-clock</v-icon>
          </v-list-tile-action>
          <v-list-tile-content>
            <v-list-tile-title>report on working time</v-list-tile-title>
          </v-list-tile-content>
        </v-list-tile>
        <v-divider />
        <v-list-tile @click="logout">
          <v-list-tile-action>
            <v-icon>fas fa-power-off</v-icon>
          </v-list-tile-action>
          <v-list-tile-content>
            <v-list-tile-title>log out</v-list-tile-title>
          </v-list-tile-content>
        </v-list-tile>

      </v-list>
    </v-navigation-drawer>
    <v-toolbar fixed app>
      <v-toolbar-side-icon @click.stop="drawer = !drawer"></v-toolbar-side-icon>
      <v-toolbar-title>Timetracking</v-toolbar-title>
      <v-spacer/>
      <v-btn icon @click.stop="darkTheme = !darkTheme">
        <v-icon>far fa-lightbulb</v-icon>
      </v-btn>
    </v-toolbar>

    <router-view v-on:pageMessageEvent="showSnackbarMessage" v-on:authFailEvent="loadStaffmember" v-bind:staffmember="staffmember" />

    <v-snackbar v-model="snackbar.show" :color="snackbar.level" :multi-line="snackbar.level === 'error'" bottom :timeout="snackbar.timeout">
    {{ snackbar.message }}
      <v-btn flat @click="snackbar.show = false">
        Close
      </v-btn>
    </v-snackbar>

    <!-- TODO: after a failed access and then a successful login, retry the failed access -->
    <v-dialog v-bind:value="loginVisible" persistent max-width="600px">
      <v-card>
        <v-card-title>
          <span class="headline">Login</span>
        </v-card-title>
        <v-form @submit.prevent="submitLogin">
          <v-card-text>
            <v-container grid-list-md>
              <v-layout wrap>
                <v-flex xs12>
                  <v-text-field v-model="login" label="Login" required type="username"/>
                </v-flex>
                <v-flex xs12>
                  <v-text-field v-model="password" label="Password" type="password" required />
                </v-flex>
              </v-layout>
            </v-container>
          </v-card-text>
          <v-card-actions>
            <v-spacer></v-spacer>
            <v-btn color="green" dark type="submit">Ok</v-btn>
          </v-card-actions>
        </v-form>
      </v-card>
    </v-dialog>

    <v-footer dark app>
      <span class="white--text">&copy; 2018-2019 - Willhöft IT-Beratung GmbH</span>
    </v-footer>
  </v-app>
</template>

<script>
  import X2JS from 'x2js'
  import pageMixin from '@/views/PageMixin.js'

  const x2jsStaffmember = new X2JS()

  export default {
    mixins: [pageMixin],
    data: function() {
      return {
        darkTheme: true,
        page: 'dailyBookingPage',
        drawer: false,
        snackbar: {
          message: "",
          level: "info",
          show: false,
          timeout: 2000
        },
        login: "",
        password: "",
        staffmember: {}
      };
    },
    computed: {
      loginVisible: function() {
        return ! this.staffmember._id
      }
    },
    created: function () {
      this.loadStaffmember()
    },
    methods: {
      handleError: function(error) {
        if (error.response) {
          this.showSnackbarMessage({text: "ERROR " + error.response.status + ": " + error.response.data, level: 'error'})
        } else if (error.request) {
          // The request was made but no response was received
          // `error.request` is an instance of XMLHttpRequest in the browser and an instance of
          // http.ClientRequest in node.js
          console.log(error.request);
          this.showSnackbarMessage({text: "ERROR : Failed contacting server", level: 'error'})
        } else {
          // Something happened in setting up the request that triggered an Error
          console.log('Error', error.message);
          this.showSnackbarMessage({text: "ERROR : Failed setting up server request", level: 'error'})
        }
      },
      showSnackbarMessage: function(event) {
        // If error message is visible, it must be closed manually. Ignoring new messages
        if (this.snackbar.show && this.snackbar.level === 'error') return
        this.snackbar.show = false
        const self = this
        this.$nextTick(() => {
          self.snackbar.message = event.text
          self.snackbar.level = event.level
          self.snackbar.timeout = (event.level === 'error') ? 0 : 2000
          self.snackbar.show = true
        } )
      },
      loadStaffmember: function() {
        const self = this
        self.server.get('../api/user/login').then(function(response) {
          self.staffmember = x2jsStaffmember.xml2js(response.data).staffmember;
        }).catch(function(error) {
          if (error.response && error.response.status == 401) {
            self.staffmember = {}
            return
          }
          self.handleError(error)
        })
      },
      submitLogin: function() {
        const self = this
        self.server.post('../api/user/login', 'login=' + this.login + '&' + 'password=' + this.password, {headers: {'Content-Type': 'application/x-www-form-urlencoded'}})
          .then(function (response) {
            console.log(response)
            self.showSnackbarMessage({text: "Logged in!", level: 'success'})
            self.loadStaffmember()
          })
          .catch(function (error) {
            self.handleError(error)
        })
      },
      logout: function() {
        const self = this
        self.server.post('../api/user/logout')
          .then(function (response) {
            console.log(response)
            self.showSnackbarMessage({text: "Logged out!", level: 'success'})
            self.loadStaffmember()
            self.$router.push({path: '/'})
          })
          .catch(function (error) {
            self.handleError(error)
        })
      }
    }
  }
</script>
