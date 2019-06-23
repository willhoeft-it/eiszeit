import {DateTime, Duration} from 'luxon'

export function durationAsHours (s) {
  const d = Duration.fromISO((s == 0) ? 'PT0H': s)
  if (!d) return d
  return d.toFormat("h:mm")
}

export function hoursAsDuration (s) {
  if (!s) return null
  return s.replace(/(\d?\d):(\d?\d).*/, "PT$1H$2M")
}

/**
 * Date.toISOString() always converts to UTC, this keeps the local time zone.
 **/
export function dateToLocalISOString (d) {
  // based on https://stackoverflow.com/questions/10830357/javascript-toisostring-ignores-timezone-offset
  const tzoffset = d.getTimezoneOffset() * 60000; //offset in milliseconds
  return new Date(d.getTime() - tzoffset).toISOString().slice(0, -1).replace('T00:00:00.000', '');
}

export function toDateTime (isoDate, isoTime) {
  return DateTime.fromISO(isoDate + "T" + isoTime.replace(/^(\d):/, '0$1'))
}

// export for Vue mixin
export default {
  methods: {durationAsHours, hoursAsDuration, dateToLocalISOString, toDateTime}
}
