<template>
  <v-text-field
    v-bind:value="valueAsHours"
    @change="updateValue"
    @focus="$event.target.select()"
    label="duration"
    type="text" >
  </v-text-field>
</template>

<script>
  import Vue from 'vue'
  import dateUtils from '@/utils/dateUtils.js'

  export default Vue.component('duration-textfield', {
    mixins: [dateUtils],
    props: {
      value: String
    },
    computed: {
      valueAsHours: function () {
        return this.durationAsHours(this.value)
      }
    },
    data: function() {
      return {
        valueAsDuration: null
      }
    },
    methods: {
      // Turn various input formats into a valid ISO duration
      updateValue: function (value) {
        const re = /^(\d*):?(\d\d)$/
        const v = (re.test(value)) ? value.replace(re, 'PT0$1H$2M') : 'PT0H'
        this.valueAsDuration = this.hoursAsDuration(v)
        this.$emit('input', this.valueAsDuration)
        if (this.valueAsDuration != this.value) {
          this.$emit('change', this.valueAsDuration)
        }
      }
    }
  })
</script>
