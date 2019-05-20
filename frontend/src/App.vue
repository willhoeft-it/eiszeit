<template>
  <v-app :dark="darkTheme">
    <v-navigation-drawer v-model="drawer" fixed app >
      <v-list dense>
        <!--
            <router-link to="/">Home</router-link> |
            <router-link to="/about">About</router-link>
        -->
        <v-list-tile @click="page='dashboardPage'">
          <v-list-tile-action>
            <v-icon>fas fa-chart-line</v-icon>
          </v-list-tile-action>
          <v-list-tile-content>
            <v-list-tile-title>dashboard</v-list-tile-title>
          </v-list-tile-content>
        </v-list-tile>
        <v-list-tile @click="page='dailyBookingPage'">
          <v-list-tile-action>
            <v-icon>fas fa-clipboard</v-icon>
          </v-list-tile-action>
          <v-list-tile-content>
            <v-list-tile-title>daily booking</v-list-tile-title>
          </v-list-tile-content>
        </v-list-tile>
        <v-list-tile @click="page='taskManagingPage'">
          <v-list-tile-action>
            <v-icon>fas fa-tasks</v-icon>
          </v-list-tile-action>
          <v-list-tile-content>
            <v-list-tile-title>task managing</v-list-tile-title>
          </v-list-tile-content>
        </v-list-tile>
        <v-list-tile @click="page='userManagingPage'">
          <v-list-tile-action>
            <v-icon>fas fa-users</v-icon>
          </v-list-tile-action>
          <v-list-tile-content>
            <v-list-tile-title>user managing</v-list-tile-title>
          </v-list-tile-content>
        </v-list-tile>
        <v-list-tile @click="page='reportProjectsPage'">
          <v-list-tile-action>
            <v-icon>fas fa-money-check-alt</v-icon>
          </v-list-tile-action>
          <v-list-tile-content>
            <v-list-tile-title>report on projects</v-list-tile-title>
          </v-list-tile-content>
        </v-list-tile>
        <v-list-tile @click="page='reportWorkingtimePage'">
          <v-list-tile-action>
            <v-icon>fas fa-clock</v-icon>
          </v-list-tile-action>
          <v-list-tile-content>
            <v-list-tile-title>report on working time</v-list-tile-title>
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

    <daily-booking-page v-if="page === 'dailyBookingPage'" v-on:pageMessageEvent="showSnackbarMessage" v-on:authFailEvent="loadStaffmember" v-bind:staffmember="staffmember">
    </daily-booking-page>

    <task-managing-page v-if="page === 'taskManagingPage'" v-on:pageMessageEvent="showSnackbarMessage" v-on:authFailEvent="loadStaffmember" v-bind:staffmember="staffmember">
    </task-managing-page>

    <user-managing-page v-if="page === 'userManagingPage'" v-on:pageMessageEvent="showSnackbarMessage" v-on:authFailEvent="loadStaffmember" v-bind:staffmember="staffmember">
    </user-managing-page>

    <report-projects-page v-if="page === 'reportProjectsPage'" v-on:pageMessageEvent="showSnackbarMessage" v-on:authFailEvent="loadStaffmember" v-bind:staffmember="staffmember">
    </report-projects-page>

    <report-workingtime-page v-if="page === 'reportWorkingtimePage'" v-on:pageMessageEvent="showSnackbarMessage" v-on:authFailEvent="loadStaffmember" v-bind:staffmember="staffmember">
    </report-workingtime-page>

    <v-snackbar v-model="snackbar.show" :color="snackbar.level" :multi-line="snackbar.level === 'error'" bottom :timeout="(snackbar.level === 'error') ? 0 : 2000">
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
  // eslint-disable-next-line
  import DailyBookingPage from '@/views/DailyBookingPage.vue'
  // eslint-disable-next-line
  import TaskManagingPage from '@/views/TaskManagingPage.vue'
  // eslint-disable-next-line
  import UserManagingPage from '@/views/UserManagingPage.vue'
  // eslint-disable-next-line
  import ReportProjectsPage from '@/views/ReportProjectsPage.vue'
  // eslint-disable-next-line
  import ReportWorkingtimePage from '@/views/ReportWorkingtimePage.vue'
  import pageMixin from '@/views/PageMixin.js'

  // eslint-disable-next-line
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
          show: false
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
      showSnackbarMessage: function(event) {
        this.snackbar.message = event.text;
        this.snackbar.level = event.level;
        this.snackbar.show = true;
      },
      loadStaffmember: function() {
        const self = this
        self.server.get('../api/user/login').then(function(response) {
          self.staffmember = x2jsStaffmember.xml2js(response.data).staffmember;
        }).catch(function(error) {
          if (error.response) {
            if (error.response.status == 401) {
              self.staffmember = {}
              return
            }
            console.log(error.response.data);
            console.log(error.response.status);
            console.log(error.response.headers);
            self.showSnackbarMessage({text: "ERROR " + error.response.status + ": " + error.response.data, level: 'error'})
          } else if (error.request) {
            console.log(error.request);
            self.showSnackbarMessage({text: "ERROR : Failed contacting server", level: 'error'})
          } else {
            console.log('Error', error.message);
            self.showSnackbarMessage({text: "ERROR : Failed setting up server request", level: 'error'})
          }
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
            if (error.response) {
              // The request was made and the server responded with a status code
              // that falls out of the range of 2xx
              console.log(error.response.data);
              console.log(error.response.status);
              console.log(error.response.headers);
              self.showSnackbarMessage({text: "ERROR " + error.response.status + ": " + error.response.data, level: 'error'})
            } else if (error.request) {
              // The request was made but no response was received
              // `error.request` is an instance of XMLHttpRequest in the browser and an instance of
              // http.ClientRequest in node.js
              console.log(error.request);
              self.showSnackbarMessage({text: "ERROR : Failed contacting server", level: 'error'})
            } else {
              // Something happened in setting up the request that triggered an Error
              console.log('Error', error.message);
              self.showSnackbarMessage({text: "ERROR : Failed setting up server request", level: 'error'})
            }
        });

      }
    }
  }
</script>
