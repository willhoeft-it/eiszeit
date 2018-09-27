<template>
  <v-text-field
          v-bind:value="durationAsHours(value)"
          @change.native="updateValue($event)"
          label="duration"
          type="text" >
  </v-text-field>
</template>

<script>
  import luxon from 'luxon'

  // TODO: handle validation errors correctly
  export default {
    props: ['value'],
      methods: {
        // TODO: methods should be reused with those in DailyBookingPage.vue
        durationAsHours: function(s) {
          const d = luxon.Duration.fromISO(s)
          if (!d) return d
          return d.toFormat("hh:mm")
        },
        hoursAsDuration: function(s) {
          if (!s) return null
          return s.replace(/(\d?\d):(\d?\d).*/, "PT$1H$2M")
        },
        // Instead of updating the value directly, this
        // method is used to format and place constraints
        // on the input's value
        updateValue: function (event) {
          // Emit the number value through the input event
          const value = event.target.value
          this.$emit('input', this.hoursAsDuration(value))
        }
      }
  }
</script>
