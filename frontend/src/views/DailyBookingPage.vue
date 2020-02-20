/* @flow
<template>
  <v-content><v-container fluid grid-list-md><v-layout wrap>
    <v-flex xs6>
      <h2>User: {{staffmember.givenName}} {{staffmember.name}}</h2>
      <!-- TODO: current date does not update when window is not reloaded over 24h -->
      <!-- TODO: "Today" button does not update/reset the month calendar view if selected date is still today -->
      <v-date-picker v-show="$vuetify.breakpoint.mdAndUp" :value="workingday._date" @change="loadData($event)" @update:pickerDate="loadWdInfos($event)" :events="wdInfos" color="grey" full-width landscape show-week first-day-of-week="1" reactive>
        <v-flex class="text-xs-center">
          <v-btn @click="goToToday" small flat>Today</v-btn>
        </v-flex>
      </v-date-picker>
      <v-date-picker v-show="$vuetify.breakpoint.smAndDown" :value="workingday._date" @change="loadData($event)" @update:pickerDate="loadWdInfos($event)" :events="wdInfos" color="grey" first-day-of-week="1" reactive>
        <v-flex class="text-xs-center">
          <v-btn @click="goToToday" small flat>Today</v-btn>
        </v-flex>
      </v-date-picker>
    </v-flex>
    <v-flex xs12>
      <h2>Attendance</h2>
    </v-flex>
    <v-flex xs12>
      <v-alert :value="unbookedTime.valueOf() > 0" type="warning" :outline="isDirty">{{durationAsHours(unbookedTime)}} unbooked time</v-alert>
      <v-alert :value="unbookedTime.valueOf() < 0" type="warning" :outline="isDirty">{{durationAsHours(unbookedTime.negate())}} overbooked time</v-alert>
      <v-alert :value="unbookedTime.valueOf() == 0" type="success" :outline="isDirty" >All day booked!</v-alert>
    </v-flex>
    <v-layout v-for="a in workingday.attendance" :key="a.$key" row wrap>
      <v-flex md1 xs4>
        <daily-time-picker v-model="a._start" @change="updateOnTimeChange(a, $event, null)" label="begin" />
      </v-flex>
      <v-flex md1 xs4>
        <daily-time-picker v-model="a._end" @change="updateOnTimeChange(a, null, $event)" label="end" />
      </v-flex>
      <v-flex md1 xs4>
        <duration-textfield v-model="a._duration" @change="updateOnDurationChange(a, $event)" />
      </v-flex>
      <v-flex md8 xs11>
        <v-textarea v-model="a.description" label="comment" auto-grow rows="1"></v-textarea>
      </v-flex>
      <v-flex md1 xs1>
        <v-btn @click="removeAttendance(a)" flat><v-icon>clear</v-icon></v-btn>
      </v-flex>
    </v-layout>
    <v-flex xs11></v-flex>
    <v-flex xs1 v-show="$vuetify.breakpoint.mdAndUp">
        <v-btn @click="addAttendance"><v-icon>add</v-icon></v-btn>
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
      <v-btn color="green" @click="submitWorkingday">submit</v-btn>
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
        @click="addAttendance"
      >
        <v-icon>alarm_add</v-icon>
      </v-btn>
      <span>add attendance</span>
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
      "workingday.attendance", "workingday.break", "workingday.booking"
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
      staffmember: function() {
        // (re)load data when the user logs in
        if (! this.staffmember._id)
          return
        // Hacky way of updating the date picker's event bubbles. The date picker should trigger the load, but does only on explicit click
        this.loadWdInfos(new Date().toISOString().substr(0, 7))
        if (! this.isDirty)
          this.loadData()

      },
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
        if (! this.workingday.attendance)
          return Duration.fromISO('PT0H')
        const asum = this.workingday.attendance.reduce((total, a) => {
          return a._duration ? total.plus(Duration.fromISO(a._duration)) : total
        }, Duration.fromISO('PT0H'));
        const netasum = (this.workingday.break) ? this.workingday.break.reduce((total, b) => {
          return b._duration ? total.minus(Duration.fromISO(b._duration)) : total
        }, asum) : asum;
        const unbooked = (this.workingday.booking) ? this.workingday.booking.reduce((total, b) => {
          return b._duration ? total.minus(Duration.fromISO(b._duration)) : total
        }, netasum) : netasum;
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
      loadData: function(currentDay) {
        if (! this.staffmember._id) {
          return
        }
        const urlDate = currentDay ? ("/" + currentDay) : ""
        const self = this
        axios.all([
          self.server.get('../api/tasks/' + this.staffmember._id),
          self.server.get('../api/timetrack' + urlDate),
        ]).then(axios.spread(function(taskResponse, timetrackResponse) {
          const t = x2jsTasks.xml2js(taskResponse.data).tasks;
          self.tasks = t
          const d = x2jsTimetrack.xml2js(timetrackResponse.data).workingday;
          if (! d.attendance) {
            self.addDefaultAttendance(d);
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
      submitWorkingday: function () {
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
        return (Duration.fromISO(wd.attendanceSum) - Duration.fromISO(wd.breakSum) - Duration.fromISO(wd.bookingSum) == 0) ? 'green' : 'yellow'
      },
      goToToday: function() {
        // TODO: implement
        this.loadData(this.dateToLocalISOString(new Date()).slice(0, 10))
      },
      updateOnTimeChange: function(a, newStart, newEnd) {
        const start = newStart ? newStart : a._start
        const end = newEnd ? newEnd : a._end
        if (start && end) {
          const startDt = this.toDateTime(this.workingday._date, start)
          const endDt = this.toDateTime(this.workingday._date, end)
          a._duration = endDt.diff(startDt, ['hours', 'minutes']).toISO()
        }
      },
      updateOnDurationChange: function(a, newDuration) {
        if (newDuration && a._start) {
          const duration = Duration.fromISO(newDuration)
          const startDt = this.toDateTime(this.workingday._date, a._start)
          a._end = startDt.plus(duration).toFormat("HH:mm")
        }
      },
      addDefaultAttendance: function(wd) {
        const a = {
          _start: "10:00",
          _duration: "PT9H30M",
          description: "",
          $key: pskey++
        }
        if (! wd.attendance) {
          Vue.set(wd, "attendance", [])
        }
        wd.attendance.push(a)
      },
      addDefaultBreak: function(wd, duration) {
        const b = {
          _duration: duration ? duration : "PT0H30M",
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
      addAttendance: function() {
        this.addDefaultAttendance(this.workingday)
      },
      removeAttendance: function(a) {
        this.workingday.attendance.splice(this.workingday.attendance.indexOf(a), 1)
        if (this.workingday.attendance.length==0) {
          this.addDefaultAttendance(this.workingday)
        }
      },
      addBreak: function() {
        this.addDefaultBreak(this.workingday)
      },
      removeBreak: function(b) {
        this.workingday.break.splice(this.workingday.break.indexOf(b), 1)
        if (this.workingday.break.length==0) {
          this.addDefaultBreak(this.workingday, "PT0M")
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
