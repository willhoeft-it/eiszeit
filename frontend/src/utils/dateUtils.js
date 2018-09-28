import {Duration} from 'luxon'

export default {
  methods: {
    durationAsHours: function (s) {
      const d = Duration.fromISO(s)
      if (!d) return d
      return d.toFormat("hh:mm")
    },
    hoursAsDuration: function(s) {
      if (!s) return null
      return s.replace(/(\d?\d):(\d?\d).*/, "PT$1H$2M")
    },
  }
}
