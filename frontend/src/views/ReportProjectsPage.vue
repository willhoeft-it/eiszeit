/* @flow
<template>

  <v-content><v-container grid-list-md><v-layout row wrap>
    <v-flex xs6>
      <h2>User: {{staffmember.givenName}} {{staffmember.name}}</h2>
      <input v-model="bookings._dateFrom" @change="loadData" type="date" overflow="hidden" text-overflow="ellipsis"/>
    </v-flex>

    <v-flex xs12>
      <h2>Report on projects</h2>
    </v-flex>
    <v-flex xs12>
      <v-data-table
        :headers="tableHeaders"
        :items="bookings.booking"
        :hide-actions="true"
      >
        <template slot="items" slot-scope="b">
          <td>{{ b.project.title }}</td>
          <td>{{ b.task.title }}</td>
          <td class="text-xs-right">{{ b._duration }}</td>
          <td class="text-xs-right">{{ b._billable }}</td>
          <td>{{ b.description }}</td>
        </template>
      </v-data-table>
    </v-flex>
  </v-layout></v-container></v-content>

</template>
*/

// <script>
  import Vue from 'vue'
  // eslint-disable-next-line
  import DurationTextfield from '@/components/DurationTextfield.vue'
  import {DateTime, Duration} from 'luxon'
  import axios from 'axios'
  import dateUtils from '@/utils/dateUtils.js'
  import pageMixin from '@/views/PageMixin.js'

  // eslint-disable-next-line
  const x2jsBookings = new X2JS({
    arrayAccessFormPaths : [
      "bookings.booking"
    ]
  });

  export default Vue.component('report-projects-page', {
    mixins: [dateUtils, pageMixin],
    data: function() {
      return {
        bookings: {},
        tableHeaders: [
          'Project', 'Task', 'Duration', 'Billable', 'Description'
        ]
      };
    },
    created: function () {
      this.loadData();
    },
    methods: {
      loadData: function() {
        console.log("loadData")
        if ( ! (this.bookings && this.bookings._dateFrom && this.bookings._dateTo) ) {
          const today = new Date()
          const monthBegin = new Date(today.getFullYear(), today.getMonth(), 1)
          const nextMonthBegin = new Date(monthBegin.getFullYear(), monthBegin.getMonth() + 1, 1)
          console.log("begin: " + monthBegin + ", next: " + nextMonthBegin)
          this.bookings = {
            _dateFrom: this.dateToLocalISOString(monthBegin),
            _dateTo: this.dateToLocalISOString(nextMonthBegin)
          }
        }
        const urlDates = "/" + this.bookings._dateFrom + "/" + this.bookings._dateTo
        const self = this
        self.server.get('../api/report/bookings' + urlDates).then(function(reportResponse) {
          console.log("report:")
          console.log(reportResponse);
          const b = x2jsBookings.xml_str2json(reportResponse.data).bookings;
          self.bookings = b
          self.showMessage('fetched!', 'info')
        }).catch(function (error) {
          // TODO: handle errors generically as in POST + alert/snackbar/..-dialog
          console.log(error);
          self.showMessage("ERROR: " + error, 'error')
        });
      }
    }
  })
// </script>
