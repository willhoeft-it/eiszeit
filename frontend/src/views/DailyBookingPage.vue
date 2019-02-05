/* @flow
<template>
  <!-- TODO: warn on leaving the page on unsaved data -->
  <v-card>
  <v-content><v-container grid-list-md><v-layout row wrap>
    <v-flex xs6>
      <h2>User: {{staffmember.givenName}} {{staffmember.name}}</h2>
      <!-- TODO: this takes a lot of vertical space. Reduce it (even if just the white space below). -->
      <v-date-picker v-model="workingday._date" @change="loadData" @update:pickerDate="loadWdInfos($event)" :events="wdInfos" color="grey" full-width landscape show-week first-day-of-week="1" reactive v-show="$vuetify.breakpoint.mdAndUp"/>
      <v-date-picker v-model="workingday._date" @change="loadData" @update:pickerDate="loadWdInfos($event)" :events="wdInfos" color="grey" first-day-of-week="1" reactive v-show="$vuetify.breakpoint.smAndDown"/>
    </v-flex>
    <v-flex xs12>
      <h2>Working Time</h2>
    </v-flex>
    <v-flex xs12>
      <v-alert :value="unbookedTime.valueOf() > 0" type="warning" outline>{{durationAsHours(unbookedTime)}} unbooked time</v-alert>
      <v-alert :value="unbookedTime.valueOf() < 0" type="warning" outline>{{durationAsHours(unbookedTime.negate())}} overbooked time</v-alert>
      <v-alert :value="unbookedTime.valueOf() == 0" type="success" outline>All day booked!</v-alert>
    </v-flex>
    <!-- TODO: being responsive. On small screens put comment on next line -->
    <v-layout v-for="wt in workingday.workingtime" :key="wt.key">
      <v-flex xs1>
        <daily-time-picker v-model="wt._start" @change="updateOnTimeChange(wt, $event, null)" label="begin" />
      </v-flex>
      <v-flex xs1>
        <daily-time-picker v-model="wt._end" @change="updateOnTimeChange(wt, null, $event)" label="end" />
      </v-flex>
      <v-flex xs1>
        <duration-textfield v-model="wt._duration" @change="updateOnDurationChange(wt, $event)" />
      </v-flex>
      <v-flex xs8>
        <v-textarea v-model="wt.description" label="comment" auto-grow rows="1"></v-textarea>
      </v-flex>
      <v-flex xs1>
        <v-btn @click="removeWorkingTime(wt)" flat><v-icon>clear</v-icon></v-btn>
      </v-flex>
    </v-layout>
    <v-flex xs12>
      <h2>Breaks</h2>
    </v-flex>
    <!-- TODO: being responsive. On small screens put comment on next line -->
    <v-layout v-for="b in workingday.break" :key="b.key">
      <v-flex xs1>
        <daily-time-picker v-model="b._start" @change="updateOnTimeChange(b, $event, null)" label="begin" />
      </v-flex>
      <v-flex xs1>
        <daily-time-picker v-model="b._end" @change="updateOnTimeChange(b, null, $event)" label="end" />
      </v-flex>
      <v-flex xs1>
        <duration-textfield v-model="b._duration" @change="updateOnDurationChange(b, $event)" />
      </v-flex>
      <v-flex xs8>
        <v-textarea v-model="b.description" label="comment" auto-grow rows="1"></v-textarea>
      </v-flex>
      <v-flex xs1>
        <v-btn @click="removeBreak(b)" flat><v-icon>clear</v-icon></v-btn>
      </v-flex>
    </v-layout>
    <v-flex xs12>
      <h2>Bookings</h2>
    </v-flex>
    <!-- TODO: being responsive. On small screens put description on next line -->
    <!-- TODO: sort to top or highlight tasks that have recently been used -->
    <v-layout v-for="booking in workingday.booking" :key="booking.key">
      <v-flex xs3>
        <v-select v-model="booking._taskId" label="Task" :items="tasks.task" item-text="_title" item-value="_id"  @input="setBillableToDefault(booking)">
          <template slot="label">
            <span v-if="! booking._taskId" class="caption">Task</span>
            <span v-else class="caption">{{ taskPathString(booking._taskId) }}</span>
          </template>

          <template slot="item" slot-scope="{ item }">
            <v-list-tile-content>
              <v-list-tile-sub-title>{{ taskPathString(item._id) }}</v-list-tile-sub-title>
              <v-list-tile-title>{{ item._title }}</v-list-tile-title>
            </v-list-tile-content>
          </template>
        </v-select>
      </v-flex>
      <v-flex xs1>
        <daily-time-picker v-model="booking._start" @change="updateOnTimeChange(booking, $event, null)" label="begin" />
      </v-flex>
      <v-flex xs1>
        <daily-time-picker v-model="booking._end" @change="updateOnTimeChange(booking, null, $event)" label="end" />
      </v-flex>
      <v-flex xs1>
        <duration-textfield v-model="booking._duration" @change="updateOnDurationChange(booking, $event)"></duration-textfield>
      </v-flex>
      <v-flex xs1>
        <v-select v-model="booking._billable" label="billable" :items="billableOptions">
        </v-select>
      </v-flex>
      <v-flex xs4>
        <v-textarea v-model="booking.description" label="description" auto-grow rows="1"></v-textarea>
      </v-flex>
      <v-flex xs1>
        <v-btn @click="removeBooking(booking)" flat><v-icon>clear</v-icon></v-btn>
      </v-flex>
    </v-layout>
    <v-flex xs11></v-flex>
    <v-flex xs12>
      <v-btn color="green" dark @click="submitWorkingtimes">submit</v-btn>
      <v-btn @click="loadData">reset</v-btn>
    </v-flex>

    </v-layout>
  </v-container></v-content>
  <v-speed-dial
    v-model="fab"
    fixed
    bottom
    right
    direction="top"
    transition="scale-transition"
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
</v-card>
</template>
*/

// <script>
  import Vue from 'vue'
  // eslint-disable-next-line
  import DurationTextfield from '@/components/DurationTextfield.vue'
  // eslint-disable-next-line
  import DailyTimePicker from '@/components/DailyTimePicker.vue'
  import {DateTime, Duration} from 'luxon'
  import axios from 'axios'
  import binarySearch from 'binary-search'
  import dateUtils from '@/utils/dateUtils.js'
  import pageMixin from '@/views/PageMixin.js'

  // page scope unique key generator
  let pskey = 0

  // eslint-disable-next-line
  const x2jsTasks = new X2JS({
    arrayAccessFormPaths : [
      "tasks.task", "tasks.task.path"
    ]
  });
  // eslint-disable-next-line
  const x2jsTimetrack = new X2JS({
    arrayAccessFormPaths : [
      "workingday.workingtime", "workingday.break", "workingday.booking"
    ]
  });
  // eslint-disable-next-line
  const x2jsWdReport = new X2JS({
    arrayAccessFormPaths : [
      "workingdays.workingday"
    ]
  });

  export default Vue.component('daily-booking-page', {
    mixins: [dateUtils, pageMixin],
    data: function() {
      return {
        workingday: {},
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
          return total.plus(Duration.fromISO(wt._duration))

        }, Duration.fromISO('PT0H'));
        const netwtsum = (this.workingday.break) ? this.workingday.break.reduce((total, b) => {
          return total.minus(Duration.fromISO(b._duration))
        }, wtsum) : wtsum;
        const unbooked = (this.workingday.booking) ? this.workingday.booking.reduce((total, b) => {
          return total.minus(Duration.fromISO(b._duration))
        }, netwtsum) : netwtsum;
        return unbooked;
      }
    },
    created: function () {
      this.loadData();
    },
    methods: {
      loadData: function() {
        console.log("loadData")
        const urlDate = (this.workingday && this.workingday._date) ? ("/" + this.workingday._date) : ""
        const self = this
        axios.all([
          self.server.get('../api/tasks/' + this.staffmember._id),
          self.server.get('../api/timetrack' + urlDate),
        ]).then(axios.spread(function(taskResponse, timetrackResponse) {
          console.log("tasks:")
          console.log(taskResponse);
          const t = x2jsTasks.xml_str2json(taskResponse.data).tasks;
          self.tasks = t
          console.log("timetrack:")
          console.log(timetrackResponse);
          const d = x2jsTimetrack.xml_str2json(timetrackResponse.data).workingday;
          if (! d.workingtime) {
            self.addDefaultWorkingTime(d);
          }
          if (! d.break) {
            self.addDefaultBreak(d);
          }
          if (! d.booking) {
            self.addDefaultBooking(d);
          }
          self.workingday = d;
          console.log(self.workingday);

          self.showMessage('fetched!', 'info')
        }))
        .catch(function (error) {
          // TODO: handle errors generically as in POST + alert/snackbar/..-dialog
          console.log(error);
          self.showMessage("ERROR: " + error, 'error')
        });
      },
      // loading monthly working day booking overview for date picker event markers
      loadWdInfos: function(month) {
        const start = month + "-01"
        const endDate = new Date(start)
        endDate.setMonth(endDate.getMonth() + 1)
        const end = this.dateToLocalISOString(endDate).slice(0, 10)
        console.log("fetching wd report for " + start + " to " + end)
        const self = this
        self.server.get('../api/report/days/' + start + '/' + end).then(function(wdReportResponse) {
          self.wdReport = x2jsWdReport.xml_str2json(wdReportResponse.data).workingdays;
          console.log("fetched wd report")
        }).catch(function (error) {
          // TODO: handle errors generically as in POST + alert/snackbar/..-dialog
          console.log(error);
          self.showMessage("ERROR: " + error, 'error')
        });
      },
      submitWorkingtimes: function () {
        console.log("submitWorkingTimes")
        // eslint-disable-next-line
        const outjs = deepFilter(this.workingday, function(_, prop) {
          return prop !== 'key'
        })
        const xmlDocStr = x2jsTimetrack.json2xml_str(
          {
            workingday: outjs
          }
        );
        console.log(xmlDocStr);
        const self = this
        self.server.post('../api/timetrack', xmlDocStr)
          .then(function (response) {
            console.log(response);
            self.showMessage("posted!", 'success')
            self.loadWdInfos(self.workingday._date.slice(0, 7))
          })
          .catch(function (error) {
            if (error.response) {
              // The request was made and the server responded with a status code
              // that falls out of the range of 2xx
              console.log(error.response.data);
              console.log(error.response.status);
              console.log(error.response.headers);
              self.showMessage("ERROR " + error.response.status + ": " + error.response.data, 'error')
            } else if (error.request) {
              // The request was made but no response was received
              // `error.request` is an instance of XMLHttpRequest in the browser and an instance of
              // http.ClientRequest in node.js
              console.log(error.request);
              self.showMessage("ERROR : Failed contacting server", 'error')
            } else {
              // Something happened in setting up the request that triggered an Error
              console.log('Error', error.message);
              self.showMessage("ERROR : Failed setting up server request", 'error')
            }
        });
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
        console.log("updateOnTimeChange", newStart, newEnd)
        const start = newStart ? newStart : wt._start
        const end = newEnd ? newEnd : wt._end
        if (start && end) {
          const startDt = DateTime.fromISO(this.workingday._date + "T" + start)
          const endDt = DateTime.fromISO(this.workingday._date + "T" + end)
          wt._duration = endDt.diff(startDt, ['hours', 'minutes']).toISO()
          console.log("updateOnEndChange: " + endDt.toISO() + " - " + startDt.toISO() + " = " + wt._duration)
        }
      },
      updateOnDurationChange: function(wt, newDuration) {
        console.log("updateOnDurationChange: " + newDuration + " / " + wt._start)
        if (newDuration && wt._start) {
          const duration = Duration.fromISO(newDuration)
          const startDt = DateTime.fromISO(this.workingday._date + "T" + wt._start)
          wt._end = startDt.plus(duration).toFormat("HH:mm")
          console.log("updateOnDurationChange: " + startDt.toISO() + " + " + newDuration + " = " + wt._end)
        }
      },
      addDefaultWorkingTime: function(wd) {
        const wt = {
          _start: "10:00",
          _duration: "PT9H30M",
          description: "",
          key: pskey++
        }
        if (! wd.workingtime) {
          console.log("creating workingtime array")
          Vue.set(wd, "workingtime", [])
        }
        wd.workingtime.push(wt)
      },
      addDefaultBreak: function(wd) {
        const b = {
          _duration: "PT0H30M",
          description: "",
          key: pskey++
        }
        if (! wd.break) {
          console.log("creating break array")
          Vue.set(wd, "break", [])
        }
        wd.break.push(b)
      },
      addDefaultBooking: function(wd) {
        const b = {
          _duration: "PT0H",
          _billable: "depends",
          description: "",
          key: pskey++
        }
        if (! wd.booking) {
          console.log("creating booking array")
          Vue.set(wd, "booking", [])
        }
        wd.booking.push(b)
      },
      addWorkingTime: function() {
        console.log("addWorkingTime")
        this.addDefaultWorkingTime(this.workingday)
      },
      removeWorkingTime: function(wt) {
        this.workingday.workingtime.splice(this.workingday.workingtime.indexOf(wt), 1)
        if (this.workingday.workingtime.length==0) {
          this.addDefaultWorkingTime(this.workingday)
        }
      },
      addBreak: function() {
        console.log("addBreak")
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
        console.log("addBooking")
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
        return this.tasks.task.find((t) => {
          return t._id == taskId
        }).path.reduce((s, p, i, arr) => {
          return s + p._title + ((i < arr.length - 1) ? " » " : "")
        }, "")
      }
    }
  })
// </script>
