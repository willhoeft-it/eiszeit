/* @flow
<template>

  <v-content><v-container grid-list-md><v-layout row wrap>
    <v-flex xs12 sm8 md6>
      <h2>User: {{staffmember.givenName}} {{staffmember.name}}</h2>
      <v-date-picker v-model="dateSelected" @change="loadData" type="month" color="grey" full-width landscape first-day-of-week="1" reactive />
    </v-flex>

    <v-flex xs12>
      <h2>Monthly Project Report</h2>
    </v-flex>
    <v-flex xs12>
      <v-data-table
        :headers="tableHeaders"
        :pagination.sync="pagination"
        :items="filteredBookings"
        :rows-per-page-items="[10,20,{'text': 'All', 'value' :-1}]"
        item-key="name"
        class="elevation-1"
      >
        <template slot="headers" slot-scope="props">
          <!-- TODO: add a free text filter for description -->
          <tr>
            <th
              v-for="header in props.headers"
              :key="header.text"
              :class="['column sortable', pagination.descending ? 'desc' : 'asc', header.value === pagination.sortBy ? 'active' : '', header.align ? 'text-xs-' + header.align : '']"
              :width="header.width"
              @click="changeSort(header.value)"
            >
              <v-icon small>arrow_upward</v-icon>
              {{ header.text }}
            </th>
          </tr>
          <tr class="grey lighten-3">
            <th
              v-for="header in props.headers"
              :key="header.text"
            >
              <div v-if="filters.hasOwnProperty(header.value)">
                <v-select flat hide-details multiple clearable :items="columnValueList(header.value)" v-model="filters[header.value]">
                </v-select>
              </div>
            </th>
          </tr>
        </template>
        <v-alert slot="no-results" :value="true" color="error" icon="warning">
          Your search found no results.
        </v-alert>
        <template slot="items" slot-scope="b">
          <td class="text-xs-right">{{ (new Date(b.item._date)).toLocaleDateString("de-de", { weekday: 'short', year: 'numeric', month: '2-digit', day: '2-digit' }) }}</td>
          <td>{{ b.item.project }}</td>
          <td>{{ b.item.task }}</td>
          <td class="text-xs-right">{{ durationAsHours(b.item._duration) }}</td>
          <td>{{ b.item._billable }}</td>
          <td>{{ b.item.description }}</td>
        </template>
        <template slot="footer">
          <td :colspan="3">
            <strong>Sum</strong>
          </td>
          <td class="text-xs-right">
            <strong>{{ durationAsHours(totalDuration) }}</strong>
          </td>
          <td :colspan="2">
            &nbsp;
          </td>
        </template>
      </v-data-table>
    </v-flex>
  </v-layout></v-container></v-content>

</template>

<style scoped>
  .v-list__tile {
    font-size: 1em;
  }
  .v-input {
    font-size: 13px;
  }
  table.v-table thead th {
    font-size: 13px;
  }
  table.v-table thead th:first-child, table.v-table thead th:not(:first-child),
  table.v-table tbody td:first-child, table.v-table tbody td:not(:first-child),
  table.v-table tfoot td:first-child, table.v-table tfoot td:not(:first-child) {
    padding: 0 15px
  }
</style>

*/

// <script>
  import Vue from 'vue'
  // eslint-disable-next-line
  import DurationTextfield from '@/components/DurationTextfield.vue'
  import {Duration} from 'luxon'
  import dateUtils from '@/utils/dateUtils.js'
  import pageMixin from '@/views/PageMixin.js'

  // eslint-disable-next-line
  const x2jsBookings = new X2JS({
    arrayAccessFormPaths : [
      "bookings.booking"
    ]
  });

  // using a global vue filter to reuse code for multiple computed values
  Vue.filter('filterBookings', function(bookings, filters) {
    return (bookings) ? bookings.filter(d => {
      return Object.keys(filters).every(f => {
        return filters[f].length < 1 || filters[f].includes(d[f])
      })
    }) : []
  })

  export default Vue.component('report-projects-page', {
    mixins: [dateUtils, pageMixin],
    data: function() {
      return {
        bookings: {},
        dateSelected: this.dateToLocalISOString(new Date()).split('T')[0],
        pagination: {
          sortBy: 'name'
        },
        selected: [],
        tableHeaders: [
          {
            text: 'Date',
            align: 'right',
            sortable: false,
            width: '14%',
            value: '_date'
          },
          {
            text: 'Project',
            align: 'left',
            sortable: false,
            width: '21%',
            value: 'project'
          },
          { text: 'Task',
            align: 'left',
            sortable: false,
            width: '14%',
            value: 'task'
          },
          { text: 'Duration',
            align: 'right',
            sortable: false,
            width: '7%',
            value: '_duration'
          },
          { text: 'Billable',
            align: 'left',
            sortable: false,
            width: '7%',
            value: '_billable'
          },
          { text: 'Description',
            align: 'left',
            sortable: false,
            width: '36%',
            value: 'description'
          }
        ],
        filters: {
          project: [],
          task: [],
          _billable: []
        },
      };
    },
    computed:  {
      filteredBookings() {
        return Vue.filter('filterBookings')(this.bookings.booking, this.filters)
      },
      totalDuration() {
        const fbs = Vue.filter('filterBookings')(this.bookings.booking, this.filters)
        return (fbs) ? fbs.reduce((total, b) => {
          return total.plus(Duration.fromISO(b._duration))
        }, Duration.fromISO('PT0H')) : "PT0H";
      }
    },
    created: function () {
      this.loadData()
    },
    methods: {
      loadData: function() {
        console.log("loadData")
        console.log("today string: " + this.dateSelected)
        const today = new Date(this.dateSelected)
        const monthBegin = new Date(today.getFullYear(), today.getMonth(), 1)
        const nextMonthBegin = new Date(monthBegin.getFullYear(), monthBegin.getMonth() + 1, 1)
        this.bookings = {
          _dateFrom: this.dateToLocalISOString(monthBegin),
          _dateTo: this.dateToLocalISOString(nextMonthBegin)
        }
        const urlDates = "/" + this.bookings._dateFrom + "/" + this.bookings._dateTo
        const self = this
        self.server.get('../api/report/bookings' + urlDates).then(function(reportResponse) {
          const bs = x2jsBookings.xml_str2json(reportResponse.data).bookings;
          self.bookings = bs

          self.showMessage('fetched!', 'info')
        }).catch(function (error) {
          // TODO: handle errors generically as in POST + alert/snackbar/..-dialog
          console.log(error);
          self.showMessage("ERROR: " + error, 'error')
        });
      },
      changeSort (column) {
        if (this.pagination.sortBy === column) {
          this.pagination.descending = !this.pagination.descending
        } else {
          this.pagination.sortBy = column
          this.pagination.descending = false
        }
      },
      columnValueList(val) {
        return (this.bookings.booking) ? this.bookings.booking.map(d => d[val]) : []
      }
    }
  })
// </script>
