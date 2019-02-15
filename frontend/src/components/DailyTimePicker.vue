<template>

  <v-text-field
    v-if="$vuetify.breakpoint.mdAndUp"
    v-bind:value="value"
    @change="updateValueFromTextField"
    @focus="$event.target.select()"
    :label="label"
    type="text" >
  </v-text-field>

  <v-menu
    v-else
    :close-on-content-click="false"
    v-model="menu"
    :nudge-right="40"
    lazy
    transition="scale-transition"
    offset-y
    full-width
    max-width="290px"
    min-width="290px"
  >
    <v-text-field
      slot="activator"
      v-bind:value="value"
      :label="label"
      :append-icon="(value)?'clear':''"
      @click:append="onPickerInput('')"
      type="text"
      readonly
    ></v-text-field>
    <!-- unfortunately whether time-picker nor its native root component emit an event if the same time is clicked again -->
    <v-time-picker
      v-if="menu"
      v-bind:value="value"
      v-on:input="onPickerInput($event)"
      full-width
      :allowed-minutes="allowedMinutes"
      format="24hr"
      color="grey"
      >
    </v-time-picker>
  </v-menu>
</template>
<script>
  import Vue from 'vue'
  export default Vue.component('daily-time-picker', {
    props: {
      value: String,
      label: String
    },
    data: function() {
      return {
        menu: false,
        innerValue: null,
        allowedMinutes: m => m % 15 === 0
      };
    },
    methods: {
      // Turn various input formats into a valid time
      updateValueFromTextField: function (v) {
        const re = /^(\d*):?(\d\d)$/
        if (re.test(v)) {
          this.innerValue = v.replace(re, '$1:$2')
          if (this.innerValue !== this.value) {
            this.$emit('change', this.innerValue)
          }
        } else {
          this.innerValue = '00:00'
          this.$emit('change', this.innerValue)
        }
        this.$emit('input', this.innerValue)
      },
      onPickerInput: function(newValue) {
        console.log("onPickerInput: ", newValue)
        if (newValue != this.value) {
          this.$emit('change', newValue)
        }
        this.$emit('input', newValue)
        // close the picker on first click/change when the input is valid
        if (/\d\d:\d\d/.test(newValue)) {
          this.menu = false
        }
      }
    }
  });
</script>
