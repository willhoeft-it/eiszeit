/* @flow
<template>

  <v-content><v-container grid-list-md><v-layout row wrap>
    <v-flex xs6>
      <h2>User: {{staffmember.givenName}} {{staffmember.name}}</h2>
      <!-- TODO: this is not updated to today on load. Why? Need to switch to a month select anyway...-->
      <input v-model="dateSelected" @change="loadData" type="date" overflow="hidden" text-overflow="ellipsis"/>
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
          <td>{{ b.item._date }}</td>
          <td>{{ b.item.project._title }}</td>
          <td>{{ b.item.task._title }}</td>
          <td class="text-xs-right">{{ b.item._duration }}</td>
          <td class="text-xs-right">{{ b.item._billable }}</td>
          <td>{{ b.item.description }}</td>
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
        dateSelected: this.dateToLocalISOString(new Date()),
        tableHeaders: [
          {
            text: 'Date',
            align: 'left',
            sortable: true,
            value: 'date'
          },
          {
            text: 'Project',
            align: 'left',
            sortable: true,
            value: 'project'
          },
          { text: 'Task',
            align: 'left',
            sortable: true,
            value: 'task'
          },
          { text: 'Duration',
            align: 'right',
            sortable: true,
            value: '_duration'
          },
          { text: 'Billable',
            align: 'right',
            sortable: true,
            value: '_billable'
          },
          { text: 'Description',
            align: 'left',
            sortable: false,
            value: 'description'
          }
        ]
      };
    },
    created: function () {
      this.loadData()
    },
    methods: {
      loadData: function() {
        console.log("loadData")
        console.log("today string: " + this.dateSelected)
        const today = new Date(this.dateSelected)
        console.log("today: " + today)
        const monthBegin = new Date(today.getFullYear(), today.getMonth(), 1)
        const nextMonthBegin = new Date(monthBegin.getFullYear(), monthBegin.getMonth() + 1, 1)
        console.log("begin: " + monthBegin + ", next: " + nextMonthBegin)
        this.bookings = {
          _dateFrom: this.dateToLocalISOString(monthBegin),
          _dateTo: this.dateToLocalISOString(nextMonthBegin)
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
