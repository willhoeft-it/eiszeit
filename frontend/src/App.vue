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
          </v-list>
        </v-navigation-drawer>      
        <v-toolbar dark fixed app>
          <v-toolbar-side-icon @click.stop="drawer = !drawer"></v-toolbar-side-icon>
          <v-toolbar-title>Timetracking</v-toolbar-title>
        </v-toolbar>
        
        <!-- BEGIN dailyBookingPage -->
        <daily-booking-page v-if="page === 'dailyBookingPage'">
        </daily-booking-page>
        <!-- END dailyBookingPage -->
        
        <!-- BEGIN taskManagingPage -->
        <v-content v-if="page === 'taskManagingPage'">
          <v-container grid-list-md><v-layout row wrap>
          <v-flex xs6>
            <h2>Task Managing</h2>
          </v-flex>

          <v-flex xs12>
            <v-btn raised>submit</v-btn>
            <v-btn>reset</v-btn>
          </v-flex>
          </v-layout></v-container>
        </v-content>
        <!-- END taskManagingPage -->

        <v-snackbar v-model="snackbar.show" :color="snackbar.level" :multi-line="snackbar.level === 'error'" bottom :timeout="(snackbar.level === 'error') ? 0 : 2000">
        {{ snackbar.message }}
          <v-btn flat @click="snackbar.show = false">
            Close
          </v-btn>
        </v-snackbar>
        <v-footer dark app>
          <span class="white--text">&copy; 2018 - Willhöft IT-Beratung GmbH</span>
        </v-footer>
      </v-app>
    </div>
  </div>
</template>

<script>
  import DailyBookingPage from '@/views/DailyBookingPage.vue'
  
  export default {
    data: function() {
return {
      page: 'taskManagingPage',
      drawer: false,
      snackbar: {
        message: "",
        level: "info",
        show: false
      },
      billableOptions: [
        'yes', 'no', 'depends'
      ]
    };
},
    methods: {
      showMessage: function(text, level) {
        this.snackbar.message = text;
        this.snackbar.level = level;
        this.snackbar.show = true;
      }
    }
  }
</script>
