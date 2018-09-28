<template>
 
  <v-content><v-container grid-list-md><v-layout row wrap>
    <v-flex xs6>
      <h2>User: {{staffmember.givenName}} {{staffmember.name}}</h2>
      <input v-model="workingday._date" @change="loadData" type="date" overflow="hidden" text-overflow="ellipsis"/>
    </v-flex>

    <v-flex xs12>
      <h2>Working Time</h2>
    </v-flex>
    <v-flex xs12>
      <v-alert :value="unbookedTime.valueOf() > 0" type="warning" outline>{{durationAsHours(unbookedTime)}} unbooked time</v-alert>
      <v-alert :value="unbookedTime.valueOf() < 0" type="warning" outline>{{durationAsHours(unbookedTime)}} overbooked time</v-alert>
      <v-alert :value="unbookedTime.valueOf() == 0" type="success" outline>All day booked!</v-alert>
    </v-flex>
    
    <v-layout v-for="wt in workingday.workingtime" :key="wt.key">
      <v-flex xs1>
        <!-- TODO: combine with time-picker in a dedicated component and reuse-->
        <v-text-field v-model="wt._start" @blur="updateOnTimeChange(wt)" label="begin" type="time" ></v-text-field>
      </v-flex>
      <v-flex xs1>
        <v-text-field v-model="wt._end" @blur="updateOnTimeChange(wt)" label="end" type="time" ></v-text-field>
      </v-flex>
      <v-flex xs1>
        <duration-textfield v-model="wt._duration" @change.native="updateOnDurationChange(wt)" ></duration-textfield>
      </v-flex>
      <v-flex xs8>
        <v-textarea v-model="wt.description" label="comment" auto-grow rows="1"></v-textarea>
      </v-flex>
      <v-flex xs1>
        <v-btn @click="removeWorkingTime(wt)"><v-icon>delete</v-icon></v-btn>
      </v-flex>
    </v-layout>
    <v-flex xs11></v-flex>
    <v-flex xs1>
      <!-- TODO: use a "floating button" here that actually floats -->
        <v-btn @click="addWorkingTime"><v-icon>add</v-icon></v-btn>
    </v-flex>
    <v-flex xs12>
      <h3>Breaks</h3>
    </v-flex>
    <v-layout v-for="b in workingday.break" :key="b.key">
      <v-flex xs1>
        <v-text-field v-model="b._start" label="begin" type="time" @blur="updateOnTimeChange(b)"></v-text-field>
      </v-flex>
      <v-flex xs1>
        <v-text-field v-model="b._end" label="end" type="time" @blur="updateOnTimeChange(b)"></v-text-field>
      </v-flex>
      <v-flex xs1>
        <duration-textfield v-model="b._duration" @change.native="updateOnDurationChange(b)"></duration-textfield>
      </v-flex>
      <v-flex xs8>
        <v-textarea v-model="b.description" label="comment" auto-grow rows="1"></v-textarea>
      </v-flex>
      <v-flex xs1>
        <v-btn @click="removeBreak(b)"><v-icon>delete</v-icon></v-btn>
      </v-flex>
    </v-layout>
    <v-flex xs11></v-flex>
    <v-flex xs1>
      <!-- TODO: use a "floating button" here that actually floats -->
        <v-btn @click="addBreak"><v-icon>add</v-icon></v-btn>
    </v-flex>
    <v-flex xs12>
      <h2>Bookings</h2>
    </v-flex>
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
        <v-text-field v-model="booking._start" label="begin" type="time" @blur="updateOnTimeChange(booking)"></v-text-field>
      </v-flex>
      <v-flex xs1>
        <v-text-field v-model="booking._end" label="end" type="time" @blur="updateOnTimeChange(booking)"></v-text-field>
      </v-flex>
      <v-flex xs1>
        <duration-textfield v-model="booking._duration" @change.native="updateOnDurationChange(booking)"></duration-textfield>
      </v-flex>
      <v-flex xs1>
        <v-select v-model="booking._billable" label="billable" :items="billableOptions">
        </v-select>
      </v-flex>
      <v-flex xs4>
        <v-textarea v-model="booking.description" label="description" auto-grow rows="1"></v-textarea>
      </v-flex>
      <v-flex xs1>
        <v-btn @click="removeBooking(booking)"><v-icon>delete</v-icon></v-btn>
      </v-flex>
    </v-layout>
    <v-flex xs11></v-flex>
    <v-flex xs1>
      <!-- TODO: use a "floating button" here that actually floats -->
        <v-btn @click="addBooking"><v-icon>add</v-icon></v-btn>
    </v-flex>
    <v-flex xs12>
      <v-btn @click="submitWorkingtimes" raised>submit</v-btn>
      <v-btn @click="loadData">reset</v-btn>
    </v-flex>
    </v-layout></v-container>
  </v-content>
</template>


<script>
  import Vue from 'vue'
  import DurationTextfield from '@/components/DurationTextfield.vue'
  import {DateTime, Duration} from 'luxon'
  import axios from 'axios'
  import dateUtils from '@/utils/dateUtils.js'
  
  // page scope unique key generator
  var pskey = 0

  const x2jsTasks = new X2JS({
    arrayAccessFormPaths : [
      "tasks.task", "tasks.task.path"
    ]
  });
  
  const x2jsTimetrack = new X2JS({
    arrayAccessFormPaths : [
      "workingday.workingtime", "workingday.break", "workingday.booking"
    ]
    // TODO: check if "datetimeAccessFormPaths : []" can be used instead of conversion in model
  });
      
  const server = axios.create({
    timeout: 1000,
    headers: {'Content-Type': 'application/xml; charset=UTF-8'}
  });
  
  export default Vue.component('daily-booking-page', {
    mixins: [dateUtils],
    data: function() {
      return {
        staffmember: {
          _id: "joern",
          name: "Willhöft",
          givenName: "Jörn"
        },
        workingday: {},
        tasks: {
          task: []
        },
        billableOptions: [
          'yes', 'no', 'depends'
        ]
      };
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
      showMessage: function(text, level) {
        this.$emit('pageMessageEvent', {text, level})
      },
      loadData: function() {
        console.log("loadData")
        const urlDate = (this.workingday && this.workingday._date) ? ("/" + this.workingday._date) : ""
        const self = this
        axios.all([
          server.get('../api/tasks/' + this.staffmember._id),
          server.get('../api/timetrack' + urlDate),
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
      submitWorkingtimes: function () {
        console.log("submitWorkingTimes")
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
        server.post('../api/timetrack', xmlDocStr)
          .then(function (response) {
            console.log(response);
            self.showMessage("posted!", 'success')
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
      updateOnTimeChange: function(wt) {
        if (wt._end && wt._start) {
          const endDt = DateTime.fromISO(this.workingday._date + "T" + wt._end)
          const startDt = DateTime.fromISO(this.workingday._date + "T" + wt._start)
          wt._duration = endDt.diff(startDt, ['hours', 'minutes']).toISO()
          console.log("updateOnEndChange: " + endDt.toISO() + " - " + startDt.toISO() + " = " + wt._duration)
        }
      },
      updateOnDurationChange: function(wt) {
        console.log("updateOnDurationChange: " + wt._duration + " / " + wt._start)
        if (wt._duration && wt._start) {
          const duration = Duration.fromISO(wt._duration)
          const startDt = DateTime.fromISO(this.workingday._date + "T" + wt._start)
          wt._end = startDt.plus(duration).toFormat("HH:mm")
          console.log("updateOnDurationChange: " + startDt.toISO() + " + " + wt._duration + " = " + wt._end)
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
          wd.workingtime = []
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
          wd.break = []
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
          wd.booking = []
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
</script>
