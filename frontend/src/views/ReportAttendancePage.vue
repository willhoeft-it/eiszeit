/* @flow
<template>

  <v-content><v-container fluid><v-layout row wrap>
    <v-flex xs12 sm8 md6>
      <h2>User: {{staffmember.givenName}} {{staffmember.name}}</h2>
      <v-date-picker v-model="dateSelected" @change="loadData" type="month" color="grey" full-width landscape first-day-of-week="1" reactive />
    </v-flex>

    <v-flex xs12>
      <h2>Monthly Attendance Report</h2>
    </v-flex>
    <v-flex xs12>
      <v-data-table
        :headers="tableHeaders"
        :pagination.sync="pagination"
        :custom-sort="customSort"
        :items="filteredBookings"
        :rows-per-page-items="[15,30,{'text': 'All', 'value' :-1}]"
        expand
        item-key="_date"
        class="elevation-1"
      >
        <template slot="headers" slot-scope="props">
          <tr>
            <th
              v-for="header in props.headers"
              :key="header.text"
              :class="['column sortable', pagination.descending ? 'desc' : 'asc', header.value === pagination.sortBy ? 'active' : '', header.align ? 'text-xs-' + header.align : '']"
              :width="header.width"
              @click="changeSort(header)"
            >
              <v-icon v-if="header.sortable" small>arrow_upward</v-icon>
              {{ header.text }}
            </th>
          </tr>
          <tr>
            <th
              v-for="header in props.headers"
              :key="header.text"
            >
              <div v-if="filters.hasOwnProperty(header.value)">
                <v-select v-if="filters[header.value].type==='selection'" flat hide-details multiple clearable :items="columnValueList(header.value)" v-model="filters[header.value].items" />
                <v-combobox v-if="filters[header.value].type==='text'" placeholder="Filter" flat hide-details append-icon="" multiple clearable small-chips deletable-chips v-model="filters[header.value].items" />
              </div>
            </th>
          </tr>
        </template>
        <v-alert slot="no-results" :value="true" color="error" icon="warning">
          Your search found no results.
        </v-alert>
        <template slot="items" slot-scope="props">
          <tr @click="props.expanded = !props.expanded">
            <td class="text-xs-right">{{ (new Date(props.item._date)).toLocaleDateString("de-de", { weekday: 'short', year: 'numeric', month: '2-digit', day: '2-digit' }) }}</td>
            <td class="text-xs-right">{{ durationAsHours(props.item.attendanceSum) }}</td>
            <td class="text-xs-right">{{ durationAsHours(props.item.breakSum) }}</td>
            <td class="text-xs-right">{{ durationAsHours(props.item.bookingSum) }}</td>
            <td>{{ shortDescriptionArr(props.item.attendance).concat(shortDescriptionArr(props.item.break)).join(", ") }}</td>
          </tr>
        </template>
        <template slot="expand" slot-scope="props">
          <table>
            <tbody>
              <tr v-for="(wt, i) in props.item.attendance" :key="i">
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
  import X2JS from 'x2js'
  import dateUtils from '@/utils/dateUtils.js'
  import pageMixin from '@/views/PageMixin.js'

  const x2jsWdReport = new X2JS({
    arrayAccessFormPaths : [
      "workingdays.workingday",
      "workingdays.workingday.attendance",
      "workingdays.workingday.break"
    ]
  });

  // using a global vue filter to reuse code for multiple computed values
  Vue.filter('filterAttendance', function(bookings, filters) {
    return (bookings) ? bookings.filter(b => {
      return Object.keys(filters).every(f => {
        if (filters[f].items.length < 1) return true
        switch(filters[f].type) {
          case "selection": return filters[f].items.includes(b[f])
          case "text": return filters[f].items.every(txt =>
            (b.attendance || []).concat(b.break || []).some(i =>
              (i.description && i.description.toLowerCase().includes(txt.toLowerCase()))
            )
          )
        }
        return true
      })
    }) : []
  })

  export default Vue.component('report-attendance-page', {
    mixins: [dateUtils, pageMixin],
    props: {
      staffmember: Object
    },
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
            sortable: true,
            value: '_date'
          },
          {
            text: 'Attendance',
            align: 'right',
            width: '130em',
            sortable: true,
            value: 'attendanceSum'
          },
          { text: 'Breaks',
            align: 'right',
            width: '100em',
            sortable: true,
            value: 'breakSum'
          },
          { text: 'Bookings',
            align: 'right',
            width: '100em',
            sortable: true,
            value: 'bookingSum'
          },
          { text: 'Descriptions',
            align: 'left',
            sortable: false,
            value: 'description'
          }
        ],
        filters: {
          description: {
            type: 'text',
            items: [] }
        },
      };
    },
    computed:  {
      filteredBookings() {
        return Vue.filter('filterAttendance')(this.wdReport.workingday, this.filters)
      },
      totalBookedDuration() {
        const fbs = Vue.filter('filterAttendance')(this.wdReport.workingday, this.filters)
        return (fbs) ? fbs.reduce((total, b) => {
          return total.plus(Duration.fromISO(b.bookingSum))
        }, Duration.fromISO('PT0H')) : "PT0H";
      }
    },
    created: function () {
      this.loadData()
    },
    methods: {
      shortDescriptionArr: function (items) {
        if (!items) return []
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
          self.wdReport = x2jsWdReport.xml2js(wdReportResponse.data).workingdays;
          console.log("fetched wd report")

          self.showMessage('fetched!', 'info')
        }).catch(this.handleHttpError);
      },
      changeSort (column) {
        if (!column.sortable) return;
        if (this.pagination.sortBy === column.value) {
          this.pagination.descending = !this.pagination.descending
        } else {
          this.pagination.sortBy = column.value
          this.pagination.descending = false
        }
      },
      customSort (items, index, isDescending) {
        if (index === null) return items

        return items.sort((a, b) => {
          const sortA = isDescending ? b[index] : a[index]
          const sortB = isDescending ? a[index] : b[index]
          // Check if both are numbers
          if (!isNaN(sortA) && !isNaN(sortB)) {
            return sortA - sortB
          }
          // Check if both cannot be evaluated
          if (sortA === null && sortB === null) {
            return 0
          }
          // Check for special duration columns
          if (['attendanceSum', 'breakSum', 'bookingSum'].includes(index)) {
            const [dA, dB] = [sortA, sortB].map(s => (
              Duration.fromISO(s || 'PT0H').valueOf()
            ))
            return dA - dB
          }
          const [strA, strB] = [sortA, sortB].map(s => (
            (s || '').toString()
          ))
          return strA.localeCompare(strB)
        })
      },
      columnValueList(val) {
        return (this.wdReport.workingday) ? this.wdReport.workingday.map(d => d[val]) : []
      }
    }
  })
// </script>
