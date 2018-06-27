<template>
  <!-- TODO: fix bug: value is not always converted. WF: Type "75" in field, click on field, click on other field. Result: invalid "75" remains. Expected: when focus is lost, should turn to "01:15" (works when using tab-key) -->
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
        if (re.test(value)) {
          this.valueAsDuration = value.replace(re, 'PT0$1H$2M')
          if (this.valueAsDuration !== this.value) {
            this.$emit('change', this.valueAsDuration)
          }
        } else {
          this.valueAsDuration = 'PT0H'
          this.$emit('change', this.valueAsDuration)
        }
        this.$emit('input', this.valueAsDuration)
      }
    }
  })
</script>
