/* @flow
<template>

  <v-content><v-container fluid><v-layout row wrap>
    <v-flex xs12 sm8 md6>
      <h2>User: {{staffmember.givenName}} {{staffmember.name}}</h2>
      <v-date-picker v-model="dateSelected" @change="loadData" type="month" color="grey" full-width landscape first-day-of-week="1" reactive />
    </v-flex>
    <v-toolbar flat>
      <v-toolbar-title>Monthly Project Report</v-toolbar-title>
      <v-spacer></v-spacer>
      <v-toolbar-items>
        <v-menu v-model="accessTokenUrl" :close-on-content-click="false" :nudge-width="400" left >
          <template v-slot:activator="{ on }">
            <v-btn small icon v-on="on" @click="getAccessToken">
              <v-icon small>fas fa-key</v-icon>
            </v-btn>
          </template>
          <v-card tile>
            <v-text-field
              outline
              single-line
              v-model="accessTokenUrl"
              @focus="clipboardAccessTokenUrl($event)"
              append-icon="fas fa-paste"
            />
          </v-card>
        </v-menu>
      </v-toolbar-items>
    </v-toolbar>
    <v-flex xs12>
      <v-data-table
        :headers="tableHeaders"
        :pagination.sync="pagination"
        :custom-sort="customSort"
        :items="filteredBookings"
        :rows-per-page-items="[15,30,{'text': 'All', 'value' :-1}]"
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
  /* fix filter combo-box position */
  .v-text-field.v-text-field--enclosed {
    margin-top: 4px;
    padding-top: 12px;
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
  import X2JS from 'x2js'
  import dateUtils from '@/utils/dateUtils.js'
  import pageMixin from '@/views/PageMixin.js'

  const x2jsBookings = new X2JS({
    arrayAccessFormPaths : [
      "bookings.booking"
    ]
  });
  const x2js = new X2JS();

  // using a global vue filter to reuse code for multiple computed values
  Vue.filter('filterBookings', function(bookings, filters) {
    return (bookings) ? bookings.filter(b => {
      return Object.keys(filters).every(f => {
        if (filters[f].items.length < 1) return true
        switch(filters[f].type) {
          case "selection": return filters[f].items.includes(b[f])
          case "text": return filters[f].items.every(txt =>
            b[f].toLowerCase().includes(txt.toLowerCase()))
        }
        return true
      })
    }) : []
  })

  export default Vue.component('report-projects-page', {
    mixins: [dateUtils, pageMixin],
    props: {
      staffmember: Object
    },
    data: function() {
      return {
        bookings: {},
        dateSelected: this.dateToLocalISOString(new Date()).split('T')[0],
        pagination: {
          sortBy: '_date'
        },
        selected: [],
        tableHeaders: [
          {
            text: 'Date',
            align: 'right',
            sortable: true,
            width: '14%',
            value: '_date'
          },
          {
            text: 'Project',
            align: 'left',
            sortable: true,
            width: '21%',
            value: 'project'
          },
          { text: 'Task',
            align: 'left',
            sortable: true,
            width: '14%',
            value: 'task'
          },
          { text: 'Duration',
            align: 'right',
            sortable: true,
            width: '7%',
            value: '_duration'
          },
          { text: 'Billable',
            align: 'left',
            sortable: true,
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
          project: {
            type: 'selection',
            items: [] },
          task: {
            type: 'selection',
            items: [] },
          _billable: {
            type: 'selection',
            items: [] },
          description: {
            type: 'text',
            items: [] }
        },
        accessTokenPath: "",
        accessTokenUrl: ""
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
        const url = '../api/report/bookings/' + this.bookings._dateFrom + '/' + this.bookings._dateTo
        const self = this
        self.server.get(url).then(function(reportResponse) {
          const bs = x2jsBookings.xml2js(reportResponse.data).bookings;
          self.bookings = bs
          self.accessTokenPath = url
          self.accessTokenUrl = ""
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
          if ('_duration' === index) {
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
        return (this.bookings.booking) ? this.bookings.booking.map(d => d[val]) : []
      },
      getAccessToken() {
        const url = new URL(this.accessTokenPath, window.location.href)
        const accessPath = url.pathname
        const self = this
        self.server.get('../api/token?path=' + encodeURIComponent(accessPath)).then(function(tokenResponse) {
          self.accessTokenUrl = url.href + "?accessToken=" + encodeURIComponent(x2js.xml2js(tokenResponse.data).token);
        }).catch(this.handleHttpError);
      },
      clipboardAccessTokenUrl(event) {
        event.target.select()
        const success = document.execCommand('copy');
        if (success) this.showMessage('copied to clipboard', 'success')
        else this.showMessage('copy to clipboard failed', 'error')
        this.accessTokenUrl = ""
      },
    }
  })
// </script>
