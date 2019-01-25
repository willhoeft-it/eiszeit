<template>
  <v-menu
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
      v-model="valueCopy"
      v-on:change="$emit('change', valueCopy)"
      v-on:input="$emit('input', valueCopy)"
      :label="label"
      :append-icon="(valueCopy)?'clear':''"
      @click:append="function(){valueCopy = null}"
      readonly
    ></v-text-field>
    <v-time-picker
      v-if="menu"
      v-model="valueCopy"
      v-on:change="$emit('change', valueCopy)"
      v-on:input="onPickerInput"
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
        valueCopy: this.value,
        allowedMinutes: m => m % 15 === 0
      };
    },
    methods: {
      onPickerInput: function() {
        this.$emit('input', this.valueCopy)
        // close the picker on first click/change when the input is valid
        if (/\d\d:\d\d/.test(this.valueCopy)) {
          this.menu = false
          if (this.valueCopy != this.value) {
            this.$emit('change', this.valueCopy)
          }
        }
      }
    }
  });
</script>
