const { DateTime } = luxon

document.addEventListener('alpine:init', () => {
  Alpine.data('minits', (id) => ({
    text: null,
    start: null,
    minutes: [],

    async init() {
      const response = await fetch(`/${id}/minutes.json`)
      const minits = await response.json()

      this.start = minits.start ? DateTime.fromISO(minits.start) : DateTime.now()
      this.minutes = minits.minutes.map((minute) => {
        minute.time = DateTime.fromISO(minute.time)
        return minute
      })

      this.sync().catch(console.error)
    },

    async record() {
      if (!this.text) return

      this.minutes.push({ time: DateTime.now(), text: this.text })
      this.text = null

      this.sync().catch(console.error)
    },

    offsetString(time) {
      return time.diff(this.start).toFormat('mm:ss')
    },

    async sync() {
      await fetch(`/${id}/sync.json`, {
        method: 'POST',
        body: JSON.stringify({ start: this.start, minutes: this.minutes })
      })
    }
  }))
})
