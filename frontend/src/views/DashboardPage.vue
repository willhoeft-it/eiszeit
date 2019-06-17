/* @flow
<template>

  <v-content><v-container fluid><v-layout row wrap>

    <v-toolbar flat>
      <v-toolbar-title>Project Overview</v-toolbar-title>
      <v-spacer />
    </v-toolbar>

    <v-flex xs3>
      <v-select v-model="period" label="Period" :items="periodItems" item-text="text" item-value="value" @change="loadData"/>
    </v-flex>

    <!-- TODO: depending on period, start dates must be aligned. E.g. months to 1st, weeks to Monday, etc. -->
    <v-flex xs3>
      <v-menu
        v-model="datePicker"
        :close-on-content-click="false"
        :nudge-right="40"
        lazy
        offset-y
        full-width
        min-width="290px"
      >
        <template v-slot:activator="{ on }">
          <v-text-field
            v-model="startDate"
            label="Start date"
            prepend-icon="event"
            readonly
            v-on="on"
          ></v-text-field>
        </template>
        <v-date-picker v-model="startDate" @input="datePicker = false" first-day-of-week="1" @change="loadData" />
      </v-menu>
    </v-flex>

    <v-flex xs3>
      <v-select v-model="periods" label="Periods" :items="periodsItems" @change="loadData" />
    </v-flex>

    <!-- TODO add verticle lines to table -->
    <!-- TODO add options to configure yes / depends / no / all columns -->
    <!-- TODO add options to configure durations between : hhh:mm, h.00, d.00 (d=8h), d.00 (d=24h) -->
    <v-flex xs12>
      <v-data-table
        :headers="tableHeaders"
        :items="tableItems"
        class="elevation-1"
        hide-actions
      >
        <!-- TODO add from - to dates to column header -->
        <template slot="headers" slot-scope="props">
          <tr>
            <template v-for="(header, i) in props.headers">
              <th v-if="i == 0" :key="header.value" >
                {{ header.text }}
              </th>
              <th v-else-if="header.topHeader==true" :key="header.value" colspan="3" class="text-xs-left">
                {{ header.text }}
              </th>
            </template>
          </tr>
          <tr>
            <template v-for="(header, i) in props.headers">
              <th v-if="i == 0" :key="header.value" />
              <th v-else-if="header.topHeader==false" :key="header.value" class="text-xs-left">
                {{ header.text }}
              </th>
            </template>
          </tr>
        </template>
        <template slot="items" slot-scope="col">
          <template v-for="(header, i) in tableHeaders">
            <td v-if="i==0" :key="header.value">
              {{ col.item[header.value] }}
            </td>
            <td v-else-if="header.topHeader==false" :key="header.value" class="text-xs-right">
              {{ col.item[header.value] }}
            </td>
          </template>
          <!-- TODO add period totals -->
        </template>
      </v-data-table>
    </v-flex>
  </v-layout></v-container></v-content>

</template>

*/

// <script>
  import Vue from 'vue'
  import _ from 'lodash'
  import X2JS from 'x2js'
  import {durationAsHours} from '@/utils/dateUtils.js'
  import pageMixin from '@/views/PageMixin.js'

  const x2jsReport = new X2JS({
    arrayAccessFormPaths : [
      "projectReport.period",
      "projectReport.period.project",
      "projectReport.period.bookingSum",
      "projectReport.period.project.task",
      "projectReport.period.project.bookingSum",
      "projectReport.period.project.task.bookingSum"
    ]
  });

  export default Vue.component('dashboard-page', {
    mixins: [pageMixin],
    props: {
    },
    data: function() {
      return {
        datePicker: false,
        // TODO: implement sensible start default: today - periods, aligned to weeks
        startDate: '2019-01-01',
        periodItems: [
          { text: 'day', value:'P1D'},
          { text: 'week', value: 'P7D'},
          { text: 'month', value: 'P1M'},
          { text: 'quarter', value: 'P3M'}
        ],
        period: 'P1M',
        periodsItems: ['3', '4', '6', '7', '12', '14', '20'],
        periods: '6',
        report: {},
      };
    },
    computed:  {
      tableHeaders() {
        const headers = [{text: 'Project', value: '_title', topHeader: true}]
        for (var i=1; i <= this.periods; i++) {
          const aggrTitle = _.find(this.periodItems, {value: this.period});
          headers.push({
            text: aggrTitle.text + ' ' + i,
            value: 'period_' + i,
            topHeader: true
          });
          ['yes', 'depends', 'no'].map(b => {
            headers.push({
              text: b,
              value: 'period_' + i + '_' + b,
              topHeader: false
            })
          })
        }
        return headers
      },
      tableItems() {
        // rearrange from period -> project -> bookingSum to project -> period -> bookingSum
        if (! this.report || ! this.report.period  || ! this.report.period[0].project) return []
        const periods = this.report.period
        // assuming first period always contains all needed projects
        const projects = periods[0].project.map(pr => {
          const project = _.pick(pr, ['_id', '_title'])
          periods.map((pe, ipe) => {
            const sums = _.find(pe.project, {'_id': pr._id}).bookingSum
            sums.map(bs => {
              project['period_' + (ipe + 1) + '_' + bs._billable] = bs.__text == 0 ? '' : durationAsHours(bs.__text)
            })

          })
          return project
        })
        return projects

      }
    },
    created: function () {
      this.loadData()
    },
    methods: {
      loadData: function() {
        console.log("loadData")
        const self = this
        Vue.nextTick( function(){
          const url = '../api/report/projects/' + self.startDate + '?aggrPeriod=' + self.period + '&noPeriods=' + self.periods
          self.server.get(url).then(function(reportResponse) {
            const report = x2jsReport.xml2js(reportResponse.data).projectReport;
            self.report = report
            self.showMessage('fetched!', 'info')
          }).catch(self.handleHttpError);
        })
      },
    }
  })
// </script>
