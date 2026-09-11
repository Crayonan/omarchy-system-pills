import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var consumers: []
  property int cpuPercent: 0
  property int memoryPercent: 0
  property int gpuPercent: -1
  property real previousCpuTotal: 0
  property real previousCpuIdle: 0
  readonly property bool polling: consumers.length > 0
  readonly property int intervalMs: requestedInterval()

  function requestedInterval() {
    var interval = 3000
    for (var i = 0; i < consumers.length; i++) {
      var candidate = Number(consumers[i] && consumers[i].intervalMs)
      if (isFinite(candidate) && candidate >= 1000) interval = Math.min(interval, Math.round(candidate))
    }
    return interval
  }
  function subscribe(consumer) {
    if (!consumer || consumers.indexOf(consumer) >= 0) return
    consumers = consumers.concat([consumer])
    refresh()
  }
  function unsubscribe(consumer) {
    var index = consumers.indexOf(consumer)
    if (index < 0) return
    var next = consumers.slice(); next.splice(index, 1); consumers = next
  }
  function refresh() {
    if (!polling) return
    cpuFile.reload(); memoryFile.reload()
    if (!gpuProcess.running) gpuProcess.running = true
  }
  function parseCpu(raw) {
    var fields = String(raw || "").split("\n")[0].trim().split(/\s+/)
    if (fields.length < 8 || fields[0] !== "cpu") return
    var idle = Number(fields[4] || 0) + Number(fields[5] || 0)
    var total = 0
    for (var i = 1; i < fields.length; i++) total += Number(fields[i] || 0)
    if (previousCpuTotal > 0 && total > previousCpuTotal) {
      cpuPercent = Math.max(0, Math.min(100, Math.round((1 - (idle - previousCpuIdle) / (total - previousCpuTotal)) * 100)))
    }
    previousCpuTotal = total; previousCpuIdle = idle
  }
  function parseMemory(raw) {
    var lines = String(raw || "").split("\n"), total = 0, available = 0
    for (var i = 0; i < lines.length; i++) {
      var parts = lines[i].trim().split(/\s+/)
      if (parts[0] === "MemTotal:") total = Number(parts[1] || 0)
      else if (parts[0] === "MemAvailable:") available = Number(parts[1] || 0)
    }
    if (total > 0) memoryPercent = Math.max(0, Math.min(100, Math.round((1 - available / total) * 100)))
  }
  function parseGpu(raw) {
    var value = Number(String(raw || "").trim().split(/\s+/)[0])
    gpuPercent = isFinite(value) ? Math.max(0, Math.min(100, Math.round(value))) : -1
  }

  Timer { interval: root.intervalMs; running: root.polling; repeat: true; onTriggered: root.refresh() }
  FileView { id: cpuFile; path: "/proc/stat"; watchChanges: false; printErrors: false; onLoaded: root.parseCpu(text()) }
  FileView { id: memoryFile; path: "/proc/meminfo"; watchChanges: false; printErrors: false; onLoaded: root.parseMemory(text()) }
  Process {
    id: gpuProcess
    command: ["nvidia-smi", "--query-gpu=utilization.gpu", "--format=csv,noheader,nounits"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.parseGpu(text) }
    onExited: if (exitCode !== 0) root.gpuPercent = -1
  }
}
