<template>
  <v-text-field
          v-bind:value="durationAsHours(value)"
          @change.native="updateValue($event)"
          label="duration"
          type="text" >
  </v-text-field>
</template>

<script>
  import Vue from 'vue'
  import {Duration} from 'luxon'
  import dateUtils from '@/utils/dateUtils.js'

  // TODO: handle validation errors correctly
  export default Vue.component('duration-textfield', {
    mixins: [dateUtils],
    props: ['value'],
    methods: {
      // Instead of updating the value directly, this
      // method is used to format and place constraints
      // on the input's value
      updateValue: function (event) {
        // Emit the number value through the input event
        const value = event.target.value
        this.$emit('input', this.hoursAsDuration(value))
      }
    }
  })
</script>
