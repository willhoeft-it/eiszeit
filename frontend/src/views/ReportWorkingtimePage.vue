/* @flow
<template>

  <v-content><v-container fluid><v-layout row wrap>
    <v-flex xs12 sm8 md6>
      <h2>User: {{staffmember.givenName}} {{staffmember.name}}</h2>
      <v-date-picker v-model="dateSelected" @change="loadData" type="month" color="grey" full-width landscape first-day-of-week="1" reactive />
    </v-flex>

    <v-flex xs12>
      <h2>Monthly Working Time Report</h2>
    </v-flex>
    <v-flex xs12>
      <v-data-table
        :headers="tableHeaders"
        :pagination.sync="pagination"
        :items="wdReport.workingday"
        :rows-per-page-items="[10,20,{'text': 'All', 'value' :-1}]"
        expand
        item-key="_date"
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
        </template>
        <v-alert slot="no-results" :value="true" color="error" icon="warning">
          Your search found no results.
        </v-alert>
        <!-- TODO: bug: sort on durations > 10 hrs is wrong. (11:00 < 5:45) -->
        <template slot="items" slot-scope="props">
          <tr @click="props.expanded = !props.expanded">
            <td class="text-xs-right">{{ (new Date(props.item._date)).toLocaleDateString("de-de", { weekday: 'short', year: 'numeric', month: '2-digit', day: '2-digit' }) }}</td>
            <td class="text-xs-right">{{ durationAsHours(props.item.workingtimeSum) }}</td>
            <td class="text-xs-right">{{ durationAsHours(props.item.breakSum) }}</td>
            <td class="text-xs-right">{{ durationAsHours(props.item.bookingSum) }}</td>
            <td>{{ shortDescriptionArr(props.item.workingtime).concat(shortDescriptionArr(props.item.break)).join(", ") }}</td>
          </tr>
        </template>
        <template slot="expand" slot-scope="props">
          <table>
            <tbody>
              <tr v-for="(wt, i) in props.item.workingtime" :key="i">
                <td width="150em"/>
                <td width="130em" class="text-xs-right">{{ durationAsHours(wt._duration) }}</td>
                <td width="100em" />
                <td width="100em" />
                <td>{{ wt.description }}</td>
              </tr>
              <tr v-for="(b, i) in props.item.break" :key="i">
                <td width="150em" />
                <td width="130em" />
                <td width="100em" class="text-xs-right">{{ durationAsHours(b._duration) }}</td>
                <td width="100em" />
                <td>{{ b.description }}</td>
              </tr>
            </tbody>
          </table>
        </template>
        <template slot="footer">
          <td :colspan="3">
            <strong>Sum</strong>
          </td>
          <td class="text-xs-right">
            <strong>{{ durationAsHours(totalBookedDuration) }}</strong>
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
  /* workaround: table and first tr don't get a component class (bug?) elevation-1 is the first element with component class */
  .elevation-1 >>> table.v-table tbody tr {
   border-bottom-style: none;
   border-top: 1px solid rgba(0,0,0,.12);
  }

  .elevation-1 >>> table.v-table thead th:first-child, .elevation-1 >>> table.v-table thead th:not(:first-child),
  .elevation-1 >>> table.v-table tbody td:first-child, .elevation-1 >>> table.v-table tbody td:not(:first-child),
  .elevation-1 >>> table.v-table tfoot td:first-child, .elevation-1 >>> table.v-table tfoot td:not(:first-child) {
    padding: 0 15px;
  }

  .v-datatable__expand-content table {
    border-spacing: 0;
  }
  .v-datatable__expand-content table tbody td {
    height: 36px;
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
  const x2jsWdReport = new X2JS({
    arrayAccessFormPaths : [
      "workingdays.workingday",
      "workingdays.workingday.workingtime",
      "workingdays.workingday.break"
    ]
  });

  export default Vue.component('report-workingtime-page', {
    mixins: [dateUtils, pageMixin],
    data: function() {
      return {
        wdReport: {},
        dateSelected: this.dateToLocalISOString(new Date()).split('T')[0],
        pagination: {
          sortBy: '_date'
        },
        selected: [],
        tableHeaders: [
          {
            text: 'Date',
            align: 'right',
            width: '150em',
            sortable: false,
            value: '_date'
          },
          {
            text: 'Working Time',
            align: 'right',
            width: '130em',
            sortable: false,
            value: 'workingtimeSum'
          },
          { text: 'Breaks',
            align: 'right',
            width: '100em',
            sortable: false,
            value: 'breakSum'
          },
          { text: 'Bookings',
            align: 'right',
            width: '100em',
            sortable: false,
            value: 'bookingSum'
          },
          { text: '',
            align: 'right',
            sortable: false
          }
        ]
      };
    },
    computed:  {
      totalBookedDuration() {
        return (this.wdReport.workingday) ? this.wdReport.workingday.reduce((total, b) => {
          return total.plus(Duration.fromISO(b.bookingSum))
        }, Duration.fromISO('PT0H')) : "PT0H";
      }
    },
    created: function () {
      this.loadData()
    },
    methods: {
      shortDescriptionArr: function (items) {
        return items.filter(i => i.description).map(i =>  (i.description.length > 20) ? i.description.substring(0, 20) + "..." : i.description)
      },
      loadData: function() {
        console.log("loadData")
        console.log("today string: " + this.dateSelected)
        const today = new Date(this.dateSelected)
        const monthBegin = new Date(today.getFullYear(), today.getMonth(), 1)
        const nextMonthBegin = new Date(monthBegin.getFullYear(), monthBegin.getMonth() + 1, 1)
        this.wdReport = {
          _dateFrom: this.dateToLocalISOString(monthBegin),
          _dateTo: this.dateToLocalISOString(nextMonthBegin)
        }
        const urlDates = "/" + this.wdReport._dateFrom + "/" + this.wdReport._dateTo
        const self = this
        self.server.get('../api/report/days' + urlDates).then(function(wdReportResponse) {
          self.wdReport = x2jsWdReport.xml_str2json(wdReportResponse.data).workingdays;
          console.log("fetched wd report")

          self.showMessage('fetched!', 'info')
        }).catch(this.handleHttpError);
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
        return (this.wdReport.workingday) ? this.wdReport.workingday.map(d => d[val]) : []
      }
    }
  })
// </script>
