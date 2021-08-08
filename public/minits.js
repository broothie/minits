const { DateTime } = luxon

document.addEventListener('alpine:init', () => {
  Alpine.data('minits', (id) => ({
    text: null,
    start: null,
    status: 'saved',
    records: [],
    currentTime: DateTime.now(),

    async init() {
      const response = await fetch(`/${id}/minutes.json`)
      const minutes = await response.json()

      this.start = DateTime.fromISO(minutes.start)
      this.records = minutes.records.map((record) => {
        record.time = DateTime.fromISO(record.time)
        return record
      })

      setInterval(() => this.tick(), 1000)
    },

    async record() {
      if (!this.text) return

      this.records.push({ time: DateTime.now(), text: this.text })
      this.text = null

      this.status = 'not saved'
      this.sync().catch(console.error)
    },

    async sync() {
      this.status = 'saving'

      const response = await fetch(`/${id}/sync`, {
        method: 'POST',
        body: JSON.stringify({ start: this.start, records: this.records })
      })

      if (response.ok) this.status = 'saved'
    },

    formatOffset(time) {
      return time.diff(this.start).toFormat('mm:ss')
    },

    tick() {
      this.currentTime = DateTime.now()
    },

    getCurrentOffset() {
      if (!this.start) return null

      return this.formatOffset(this.currentTime)
    }
  }))
})
