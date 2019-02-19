import {DateTime, Duration} from 'luxon'

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
    /**
     * Date.toISOString() always converts to UTC, this keeps the local time zone.
     **/
    dateToLocalISOString: function(d) {
      // based on https://stackoverflow.com/questions/10830357/javascript-toisostring-ignores-timezone-offset
      const tzoffset = d.getTimezoneOffset() * 60000; //offset in milliseconds
      return new Date(d.getTime() - tzoffset).toISOString().slice(0, -1).replace('T00:00:00.000', '');
    },
    toDateTime: function(isoDate, isoTime) {
      return DateTime.fromISO(isoDate + "T" + isoTime.replace(/^(\d):/, '0$1'))
    }
  }
}
