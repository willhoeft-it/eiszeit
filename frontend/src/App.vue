<template>
  <div id="app">
    <div id="nav">
      <v-app>
        <v-navigation-drawer v-model="drawer" fixed app >
          <v-list dense>
            <!--
                <router-link to="/">Home</router-link> |
                <router-link to="/about">About</router-link>
            -->
            <v-list-tile @click="page='homePage'">
              <v-list-tile-action>
                <v-icon>home</v-icon>
              </v-list-tile-action>
              <v-list-tile-content>
                <v-list-tile-title>dashboard</v-list-tile-title>
              </v-list-tile-content>
            </v-list-tile>
            <v-list-tile @click="page='dailyBookingPage'">
              <v-list-tile-action>
                <v-icon>book</v-icon>
              </v-list-tile-action>
              <v-list-tile-content>
                <v-list-tile-title>daily booking</v-list-tile-title>
              </v-list-tile-content>
            </v-list-tile>
            <v-list-tile @click="page='taskManagingPage'">
              <v-list-tile-action>
                <v-icon>list</v-icon>
              </v-list-tile-action>
              <v-list-tile-content>
                <v-list-tile-title>task managing</v-list-tile-title>
              </v-list-tile-content>
            </v-list-tile>
            <v-list-tile @click="page='reportProjectsPage'">
              <v-list-tile-action>
                <v-icon>list</v-icon>
              </v-list-tile-action>
              <v-list-tile-content>
                <v-list-tile-title>report on projects</v-list-tile-title>
              </v-list-tile-content>
            </v-list-tile>
            <v-list-tile @click="page='reportWorkingtimePage'">
              <v-list-tile-action>
                <v-icon>list</v-icon>
              </v-list-tile-action>
              <v-list-tile-content>
                <v-list-tile-title>report on working time</v-list-tile-title>
              </v-list-tile-content>
            </v-list-tile>
          </v-list>
        </v-navigation-drawer>
        <v-toolbar dark fixed app>
          <v-toolbar-side-icon @click.stop="drawer = !drawer"></v-toolbar-side-icon>
          <v-toolbar-title>Timetracking</v-toolbar-title>
        </v-toolbar>

        <daily-booking-page v-if="page === 'dailyBookingPage'" v-on:pageMessageEvent="showMessage">
        </daily-booking-page>

        <task-managing-page v-if="page === 'taskManagingPage'" v-on:pageMessageEvent="showMessage">
        </task-managing-page>

        <report-projects-page v-if="page === 'reportProjectsPage'" v-on:pageMessageEvent="showMessage">
        </report-projects-page>

        <report-workingtime-page v-if="page === 'reportWorkingtimePage'" v-on:pageMessageEvent="showMessage">
        </report-workingtime-page>

        <v-snackbar v-model="snackbar.show" :color="snackbar.level" :multi-line="snackbar.level === 'error'" bottom :timeout="(snackbar.level === 'error') ? 0 : 2000">
        {{ snackbar.message }}
          <v-btn flat @click="snackbar.show = false">
            Close
          </v-btn>
        </v-snackbar>
        <v-footer dark app>
          <span class="white--text">&copy; 2019 - Willhöft IT-Beratung GmbH</span>
        </v-footer>
      </v-app>
    </div>
  </div>
</template>

<script>
  // eslint-disable-next-line
  import DailyBookingPage from '@/views/DailyBookingPage.vue'
  // eslint-disable-next-line
  import TaskManagingPage from '@/views/TaskManagingPage.vue'
  // eslint-disable-next-line
  import ReportProjectsPage from '@/views/ReportProjectsPage.vue'
  // eslint-disable-next-line
  import ReportWorkingtimePage from '@/views/ReportWorkingtimePage.vue'

  export default {
    data: function() {
      return {
        page: 'reportWorkingtimePage',
        drawer: false,
        snackbar: {
          message: "",
          level: "info",
          show: false
        }
      };
    },
    methods: {
      showMessage: function(event) {
        this.snackbar.message = event.text;
        this.snackbar.level = event.level;
        this.snackbar.show = true;
      }
    }
  }
</script>
