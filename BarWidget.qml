import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "bit-dev.system-pills"
  property int cpuPercent: 0
  property int memoryPercent: 0
  property int gpuPercent: -1
  property real previousCpuTotal: 0
  property real previousCpuIdle: 0
  readonly property int intervalMs: Math.max(1000, Number(setting("refreshIntervalSec", 3)) * 1000)
  readonly property real tintOpacity: validOpacity(setting("pillOpacity", 0.24))
  readonly property color cpuAccent: validColor(setting("cpuAccent", "#F59E0B"), "#F59E0B")
  readonly property color memoryAccent: validColor(setting("memoryAccent", "#22C55E"), "#22C55E")
  readonly property color gpuAccent: validColor(setting("gpuAccent", "#8B5CF6"), "#8B5CF6")
  implicitWidth: vertical ? column.implicitWidth : row.implicitWidth
  implicitHeight: vertical ? column.implicitHeight : (bar ? bar.barSize : Style.bar.sizeHorizontal)

  function validColor(value, fallback) { var color = String(value || ""); return /^#[0-9a-fA-F]{6}$/.test(color) ? color : fallback }
  function validOpacity(value) { var number = Number(value); return isFinite(number) ? Math.max(0.08, Math.min(0.85, number)) : 0.24 }
  function parseCpu(raw) {
    var fields = String(raw || "").split("\n")[0].trim().split(/\s+/)
    if (fields.length < 8 || fields[0] !== "cpu") return
    var idle = Number(fields[4] || 0) + Number(fields[5] || 0), total = 0
    for (var i = 1; i < fields.length; i++) total += Number(fields[i] || 0)
    if (previousCpuTotal > 0 && total > previousCpuTotal) cpuPercent = Math.max(0, Math.min(100, Math.round((1 - (idle - previousCpuIdle) / (total - previousCpuTotal)) * 100)))
    previousCpuTotal = total; previousCpuIdle = idle
  }
  function parseMemory(raw) {
    var lines = String(raw || "").split("\n"), total = 0, available = 0
    for (var i = 0; i < lines.length; i++) { var parts = lines[i].trim().split(/\s+/); if (parts[0] === "MemTotal:") total = Number(parts[1] || 0); else if (parts[0] === "MemAvailable:") available = Number(parts[1] || 0) }
    if (total > 0) memoryPercent = Math.max(0, Math.min(100, Math.round((1 - available / total) * 100)))
  }
  function parseGpu(raw) { var value = Number(String(raw || "").trim().split(/\s+/)[0]); gpuPercent = isFinite(value) ? Math.max(0, Math.min(100, Math.round(value))) : -1 }
  function refresh() { cpuFile.reload(); memoryFile.reload(); if (!gpuProcess.running) gpuProcess.running = true }

  Timer { interval: root.intervalMs; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
  FileView { id: cpuFile; path: "/proc/stat"; watchChanges: false; printErrors: false; onLoaded: root.parseCpu(text()) }
  FileView { id: memoryFile; path: "/proc/meminfo"; watchChanges: false; printErrors: false; onLoaded: root.parseMemory(text()) }
  Process {
    id: gpuProcess
    command: ["nvidia-smi", "--query-gpu=utilization.gpu", "--format=csv,noheader,nounits"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseGpu(text)
    }
    onExited: function(code) {
      if (code !== 0) root.gpuPercent = -1
    }
  }

  Row { id: row; visible: !root.vertical; spacing: Style.space(3)
    SystemPill { bar: root.bar; metricName: "CPU"; value: root.cpuPercent + "%"; iconSource: Qt.resolvedUrl("assets/cpu.svg"); accent: root.cpuAccent; tintOpacity: root.tintOpacity; displayMode: "full" }
    SystemPill { bar: root.bar; metricName: "Memory"; value: root.memoryPercent + "%"; iconSource: Qt.resolvedUrl("assets/memory.svg"); accent: root.memoryAccent; tintOpacity: root.tintOpacity; displayMode: "full" }
    SystemPill { bar: root.bar; metricName: "GPU"; value: root.gpuPercent < 0 ? "—" : root.gpuPercent + "%"; iconSource: Qt.resolvedUrl("assets/gpu.svg"); accent: root.gpuAccent; tintOpacity: root.tintOpacity; displayMode: "full" }
  }
  Column { id: column; visible: root.vertical; spacing: Style.space(3)
    SystemPill { bar: root.bar; metricName: "CPU"; value: root.cpuPercent + "%"; iconSource: Qt.resolvedUrl("assets/cpu.svg"); accent: root.cpuAccent; tintOpacity: root.tintOpacity; displayMode: "minimal"; width: root.barSize }
    SystemPill { bar: root.bar; metricName: "Memory"; value: root.memoryPercent + "%"; iconSource: Qt.resolvedUrl("assets/memory.svg"); accent: root.memoryAccent; tintOpacity: root.tintOpacity; displayMode: "minimal"; width: root.barSize }
    SystemPill { bar: root.bar; metricName: "GPU"; value: root.gpuPercent < 0 ? "—" : root.gpuPercent + "%"; iconSource: Qt.resolvedUrl("assets/gpu.svg"); accent: root.gpuAccent; tintOpacity: root.tintOpacity; displayMode: "minimal"; width: root.barSize }
  }
}
