/* @flow
<template>
  <v-content><v-container fluid grid-list-md><v-layout wrap>
    <v-flex xs6>
      <h2>User: {{staffmember.givenName}} {{staffmember.name}}</h2>
      <v-date-picker v-model="workingday._date" @change="loadData" @update:pickerDate="loadWdInfos($event)" :events="wdInfos" color="grey" full-width landscape show-week first-day-of-week="1" reactive v-show="$vuetify.breakpoint.mdAndUp"/>
      <v-date-picker v-model="workingday._date" @change="loadData" @update:pickerDate="loadWdInfos($event)" :events="wdInfos" color="grey" first-day-of-week="1" reactive v-show="$vuetify.breakpoint.smAndDown"/>
    </v-flex>
    <v-flex xs12>
      <h2>Working Time</h2>
    </v-flex>
    <v-flex xs12>
      <v-alert :value="unbookedTime.valueOf() > 0" type="warning" :outline="isDirty">{{durationAsHours(unbookedTime)}} unbooked time</v-alert>
      <v-alert :value="unbookedTime.valueOf() < 0" type="warning" :outline="isDirty">{{durationAsHours(unbookedTime.negate())}} overbooked time</v-alert>
      <v-alert :value="unbookedTime.valueOf() == 0" type="success" :outline="isDirty" >All day booked!</v-alert>
    </v-flex>
    <v-layout v-for="wt in workingday.workingtime" :key="wt.$key" row wrap>
      <v-flex md1 xs4>
        <daily-time-picker v-model="wt._start" @change="updateOnTimeChange(wt, $event, null)" label="begin" />
      </v-flex>
      <v-flex md1 xs4>
        <daily-time-picker v-model="wt._end" @change="updateOnTimeChange(wt, null, $event)" label="end" />
      </v-flex>
      <v-flex md1 xs4>
        <duration-textfield v-model="wt._duration" @change="updateOnDurationChange(wt, $event)" />
      </v-flex>
      <v-flex md8 xs11>
        <v-textarea v-model="wt.description" label="comment" auto-grow rows="1"></v-textarea>
      </v-flex>
      <v-flex md1 xs1>
        <v-btn @click="removeWorkingTime(wt)" flat><v-icon>clear</v-icon></v-btn>
      </v-flex>
    </v-layout>
    <v-flex xs11></v-flex>
    <v-flex xs1 v-show="$vuetify.breakpoint.mdAndUp">
        <v-btn @click="addWorkingTime"><v-icon>add</v-icon></v-btn>
    </v-flex>
    <v-flex xs12>
      <h2>Breaks</h2>
    </v-flex>
    <v-layout v-for="b in workingday.break" :key="b.$key" row wrap>
      <v-flex md1 xs4>
        <daily-time-picker v-model="b._start" @change="updateOnTimeChange(b, $event, null)" label="begin" />
      </v-flex>
      <v-flex md1 xs4>
        <daily-time-picker v-model="b._end" @change="updateOnTimeChange(b, null, $event)" label="end" />
      </v-flex>
      <v-flex md1 xs4>
        <duration-textfield v-model="b._duration" @change="updateOnDurationChange(b, $event)" />
      </v-flex>
      <v-flex md8 xs11 >
        <v-textarea v-model="b.description" label="comment" auto-grow rows="1"></v-textarea>
      </v-flex>
      <v-flex md1 xs1>
        <v-btn @click="removeBreak(b)" flat><v-icon>clear</v-icon></v-btn>
      </v-flex>
    </v-layout>
    <v-flex xs11></v-flex>
    <v-flex xs1 v-show="$vuetify.breakpoint.mdAndUp">
        <v-btn @click="addBreak"><v-icon>add</v-icon></v-btn>
    </v-flex>
    <v-flex xs12>
      <h2>Bookings</h2>
    </v-flex>
    <!-- TODO: sort to top or highlight tasks that have recently been used -->
    <v-layout v-for="booking in workingday.booking" :key="booking.$key" row wrap>
      <v-flex md3 xs12>
        <v-select v-model="booking._taskId" label="Task" :items="availableTasks" item-text="_title" item-value="_id"  @input="setBillableToDefault(booking)">
          <template slot="prepend-inner" >
            <v-icon v-if="isTaskLocked(booking._taskId)" small>fas fa-lock</v-icon>
          </template>
          <template slot="label">
            <span v-if="! booking._taskId" class="caption">Task</span>
            <span v-else class="caption">{{ taskPathString(booking._taskId) }}</span>
          </template>
          <template slot="item" slot-scope="{ item }">
            <v-list-tile-content>
              <v-list-tile-sub-title>{{ taskPathString(item._id) }}</v-list-tile-sub-title>
              <v-list-tile-title><v-icon v-if="item._status === 'locked'" small>fas fa-lock</v-icon> {{ item._title }}</v-list-tile-title>
            </v-list-tile-content>
          </template>
        </v-select>
      </v-flex>
      <v-flex md1 xs3>
        <daily-time-picker v-model="booking._start" @change="updateOnTimeChange(booking, $event, null)" label="begin" />
      </v-flex>
      <v-flex md1 xs3>
        <daily-time-picker v-model="booking._end" @change="updateOnTimeChange(booking, null, $event)" label="end" />
      </v-flex>
      <v-flex md1 xs3>
        <duration-textfield v-model="booking._duration" @change="updateOnDurationChange(booking, $event)"></duration-textfield>
      </v-flex>
      <v-flex md1 xs3>
        <v-select v-model="booking._billable" label="billable" :items="billableOptions">
        </v-select>
      </v-flex>
      <v-flex md4 xs11>
        <v-textarea v-model="booking.description" label="description" auto-grow rows="1"></v-textarea>
      </v-flex>
      <v-flex md1 xs1>
        <v-btn @click="removeBooking(booking)" flat><v-icon>clear</v-icon></v-btn>
      </v-flex>
    </v-layout>
    <v-flex xs11></v-flex>
    <v-flex xs1 v-show="$vuetify.breakpoint.mdAndUp">
        <v-btn @click="addBooking"><v-icon>add</v-icon></v-btn>
    </v-flex>
    <v-flex xs12>
      <v-btn color="green" @click="submitWorkingtimes">submit</v-btn>
      <v-btn @click="loadData">reset</v-btn>
    </v-flex>

    </v-layout>
  </v-container>

  <v-speed-dial
    v-model="fab"
    fixed
    bottom
    right
    direction="top"
    transition="scale-transition"
    v-show="$vuetify.breakpoint.smAndDown"
  >
    <!-- TODO: when an entry has been added. Scroll to its position, with "$vuetify.goTo(target, options)" and select the comment or time field -->
    <v-btn
      slot="activator"
      v-model="fab"
      color="blue darken-2"
      dark
      fab
    >
      <v-icon>add_circle</v-icon>
      <v-icon>close</v-icon>
    </v-btn>
    <v-tooltip
      color="blue"
      left
      :disabled="tooltipsDisabled"
      :value="tooltips">
      <v-btn
        slot="activator"
        fab
        color="blue"
        dark
        @click="addBooking">
        <v-icon>note_add</v-icon>
      </v-btn>
      <span>add booking</span>
    </v-tooltip>
    <v-tooltip
      color="green"
      left
      :disabled="tooltipsDisabled"
      :value="tooltips">
      <v-btn
        slot="activator"
        fab
        dark
        small
        color="green"
        @click="addBreak"
      >
        <v-icon>free_breakfast</v-icon>
      </v-btn>
      <span>add break</span>
    </v-tooltip>
    <v-tooltip
      color="indigo"
      left
      :disabled="tooltipsDisabled"
      :value="tooltips">
      <v-btn
        slot="activator"
        fab
        dark
        small
        color="indigo"
        @click="addWorkingTime"
      >
        <v-icon>alarm_add</v-icon>
      </v-btn>
      <span>add working time</span>
    </v-tooltip>
  </v-speed-dial>
</v-content>
</template>
*/

// <script>
  import Vue from 'vue'
  // eslint-disable-next-line
  import DurationTextfield from '@/components/DurationTextfield.vue'
  // eslint-disable-next-line
  import DailyTimePicker from '@/components/DailyTimePicker.vue'
  import {Duration} from 'luxon'
  import axios from 'axios'
  import X2JS from 'x2js'
  import _ from 'lodash'
  import binarySearch from 'binary-search'
  import deepFilter from 'deep-filter'
  import dateUtils from '@/utils/dateUtils.js'
  import pageMixin from '@/views/PageMixin.js'

  // page scope unique key generator
  let pskey = 0

  const x2jsTasks = new X2JS({
    arrayAccessFormPaths : [
      "tasks.task", "tasks.task.path"
    ]
  });
  const x2jsTimetrack = new X2JS({
    arrayAccessFormPaths : [
      "workingday.workingtime", "workingday.break", "workingday.booking"
    ]
  });
  const x2jsWdReport = new X2JS({
    arrayAccessFormPaths : [
      "workingdays.workingday"
    ]
  });

  export default Vue.component('daily-booking-page', {
    mixins: [dateUtils, pageMixin],
    props: {
      staffmember: Object
    },
    data: function() {
      return {
        workingday: {},
        workingdayUnchanged: {},
        tasks: {
          task: []
        },
        wdReport: {},
        fab: false,
        tooltips: false,
        tooltipsDisabled: false
      };
    },
    watch: {
      // fix so that tooltips work with the speed dial animation
      fab (val) {
        this.tooltips = false
        this.tooltipsDisabled = false
        val && setTimeout(() => {
          this.tooltips = true
          this.$nextTick(() => this.tooltipsDisabled = true)
        }, 250)
      }
    },
    computed: {
      unbookedTime() {
        if (! this.workingday.workingtime)
          return Duration.fromISO('PT0H')
        const wtsum = this.workingday.workingtime.reduce((total, wt) => {
          return wt._duration ? total.plus(Duration.fromISO(wt._duration)) : total
        }, Duration.fromISO('PT0H'));
        const netwtsum = (this.workingday.break) ? this.workingday.break.reduce((total, b) => {
          return b._duration ? total.minus(Duration.fromISO(b._duration)) : total
        }, wtsum) : wtsum;
        const unbooked = (this.workingday.booking) ? this.workingday.booking.reduce((total, b) => {
          return b._duration ? total.minus(Duration.fromISO(b._duration)) : total
        }, netwtsum) : netwtsum;
        return unbooked;
      },
      availableTasks() {
        return this.tasks.task.filter(t => (t._status === "open" || this.workingday.booking.some(b => (b._taskId === t._id))))
      },
      isDirty() {
        return !_.isEqual(this.workingday, this.workingdayUnchanged)
      }
    },
    created: function () {
      const self = this
      window.addEventListener('beforeunload', (event) => {
        if (self.isDirty) event.returnValue = 'You have unfinished changes!'
      })
      this.loadData();
    },
    methods: {
      resetDirty: function() {
        this.workingdayUnchanged = _.cloneDeep(this.workingday)
      },
      loadData: function() {
        if (! this.staffmember._id) {
          return
        }

        const urlDate = (this.workingday && this.workingday._date) ? ("/" + this.workingday._date) : ""
        const self = this
        axios.all([
          self.server.get('../api/tasks/' + this.staffmember._id),
          self.server.get('../api/timetrack' + urlDate),
        ]).then(axios.spread(function(taskResponse, timetrackResponse) {
          const t = x2jsTasks.xml2js(taskResponse.data).tasks;
          self.tasks = t
          const d = x2jsTimetrack.xml2js(timetrackResponse.data).workingday;
          if (! d.workingtime) {
            self.addDefaultWorkingTime(d);
          }
          if (! d.break) {
            self.addDefaultBreak(d);
          }
          if (! d.booking) {
            self.addDefaultBooking(d);
          }
          self.workingday = d
          self.resetDirty()
          self.showMessage('fetched!', 'info')
        })).catch(this.handleHttpError);
      },
      // loading monthly working day booking overview for date picker event markers
      loadWdInfos: function(month) {
        const start = month + "-01"
        const endDate = new Date(start)
        endDate.setMonth(endDate.getMonth() + 1)
        const end = this.dateToLocalISOString(endDate).slice(0, 10)
        const self = this
        self.server.get('../api/report/days/' + start + '/' + end).then(function(wdReportResponse) {
          self.wdReport = x2jsWdReport.xml2js(wdReportResponse.data).workingdays;
        }).catch(this.handleHttpError);
      },
      // TODO: validate or don't submit. Avoid backend error on bookings without task id
      submitWorkingtimes: function () {
        const outjs = deepFilter(this.workingday, function(_, prop) {
          return ! prop.toString().startsWith('$')
        })
        const xmlDocStr = x2jsTimetrack.js2xml(
          {
            workingday: outjs
          }
        );
        const self = this
        self.server.post('../api/timetrack', xmlDocStr)
          .then(function () {
            self.showMessage("posted!", 'success')
            self.resetDirty()
            self.loadWdInfos(self.workingday._date.slice(0, 7))
          })
          .catch(this.handleHttpError);
      },
      // interpreting working day booking overview as colors for date picker event markers
      wdInfos: function(date) {
        if (! this.wdReport.workingday) return false
        const s = {_date: date}
        const wdi = binarySearch(this.wdReport.workingday, s, function(el, needle) {
          if (el._date === needle._date) return 0
          return el._date < needle._date ? -1 : 1
        })
        if (wdi < 0) return false
        const wd = this.wdReport.workingday[wdi]
        return (Duration.fromISO(wd.workingtimeSum) - Duration.fromISO(wd.breakSum) - Duration.fromISO(wd.bookingSum) == 0) ? 'green' : 'yellow'
      },
      updateOnTimeChange: function(wt, newStart, newEnd) {
        const start = newStart ? newStart : wt._start
        const end = newEnd ? newEnd : wt._end
        if (start && end) {
          const startDt = this.toDateTime(this.workingday._date, start)
          const endDt = this.toDateTime(this.workingday._date, end)
          wt._duration = endDt.diff(startDt, ['hours', 'minutes']).toISO()
        }
      },
      updateOnDurationChange: function(wt, newDuration) {
        if (newDuration && wt._start) {
          const duration = Duration.fromISO(newDuration)
          const startDt = this.toDateTime(this.workingday._date, wt._start)
          wt._end = startDt.plus(duration).toFormat("HH:mm")
        }
      },
      addDefaultWorkingTime: function(wd) {
        const wt = {
          _start: "10:00",
          _duration: "PT9H30M",
          description: "",
          $key: pskey++
        }
        if (! wd.workingtime) {
          Vue.set(wd, "workingtime", [])
        }
        wd.workingtime.push(wt)
      },
      addDefaultBreak: function(wd) {
        const b = {
          _duration: "PT0H30M",
          description: "",
          $key: pskey++
        }
        if (! wd.break) {
          Vue.set(wd, "break", [])
        }
        wd.break.push(b)
      },
      addDefaultBooking: function(wd) {
        const b = {
          _duration: "PT0H",
          _billable: "depends",
          description: "",
          $key: pskey++
        }
        if (! wd.booking) {
          Vue.set(wd, "booking", [])
        }
        wd.booking.push(b)
      },
      addWorkingTime: function() {
        this.addDefaultWorkingTime(this.workingday)
      },
      removeWorkingTime: function(wt) {
        this.workingday.workingtime.splice(this.workingday.workingtime.indexOf(wt), 1)
        if (this.workingday.workingtime.length==0) {
          this.addDefaultWorkingTime(this.workingday)
        }
      },
      addBreak: function() {
        this.addDefaultBreak(this.workingday)
      },
      removeBreak: function(b) {
        this.workingday.break.splice(this.workingday.break.indexOf(b), 1)
        if (this.workingday.break.length==0) {
          this.addDefaultBreak(this.workingday)
        }
      },
      removeBooking: function(b) {
        this.workingday.booking.splice(this.workingday.booking.indexOf(b), 1)
        if (this.workingday.booking.length==0) {
          this.addDefaultBooking(this.workingday)
        }
      },
      addBooking: function() {
        this.addDefaultBooking(this.workingday)
      },
      setBillableToDefault: function(booking) {
        if (! booking._taskId) return;
        const task = this.tasks.task.find((value) => {
          return value._id == booking._taskId
        })
        booking._billable = task._billableDefault
      },
      taskPathString: function(taskId) {
        const task = this.tasks.task.find((t) => {
          return t._id == taskId
        })
        if (! task) return "unknown task " + taskId
        return task.path.reduce((s, p, i, arr) => {
          return s + p._title + ((i < arr.length - 1) ? " » " : "")
        }, "")
      },
      isTaskLocked: function(taskId) {
        if (typeof (taskId) === 'undefined') return false
        const task = this.tasks.task.find(t => (t._id === taskId))
        return (! task || task._status === 'locked')
      }
    }
  })
// </script>
