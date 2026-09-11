import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root
  property var bar: null
  property string metricName: "System"
  property string value: "—"
  property url iconSource
  property color accent: "#6566F1"
  property real tintOpacity: 0.24
  property string displayMode: "full"
  signal pressed(int button)

  readonly property color baseColor: bar ? bar.background : Color.background
  readonly property color compositeColor: Qt.rgba(
    accent.r * tintOpacity + baseColor.r * (1 - tintOpacity),
    accent.g * tintOpacity + baseColor.g * (1 - tintOpacity),
    accent.b * tintOpacity + baseColor.b * (1 - tintOpacity), 1)
  readonly property color textColor: contrastColor(compositeColor)

  function linearChannel(channel) { return channel <= 0.03928 ? channel / 12.92 : Math.pow((channel + 0.055) / 1.055, 2.4) }
  function contrastColor(color) {
    var luminance = 0.2126 * linearChannel(color.r) + 0.7152 * linearChannel(color.g) + 0.0722 * linearChannel(color.b)
    return 1.05 / (luminance + 0.05) >= (luminance + 0.05) / 0.05 ? "#FFFFFF" : "#000000"
  }
  function triggerPress(button) { if (bar) bar.hideTooltip(root); pressed(button) }

  implicitWidth: content.implicitWidth + Style.space(displayMode === "minimal" ? 8 : 12)
  implicitHeight: bar ? bar.barSize : Style.bar.sizeHorizontal

  Rectangle {
    anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
    height: Math.max(Style.space(20), parent.height - Style.space(5)); radius: height / 2
    color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, root.tintOpacity)
  }
  Row {
    id: content; anchors.centerIn: parent; spacing: Style.space(4)
    Image { width: Style.space(14); height: width; anchors.verticalCenter: parent.verticalCenter; source: root.iconSource; fillMode: Image.PreserveAspectFit; smooth: true; mipmap: true }
    Text { visible: root.displayMode !== "minimal"; anchors.verticalCenter: parent.verticalCenter; text: root.value; color: root.textColor; font.family: root.bar ? root.bar.fontFamily : Style.font.family; font.pixelSize: Style.font.caption; font.bold: true }
  }
  MouseArea {
    anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
    onEntered: if (root.bar) root.bar.showTooltip(root, root.metricName + " usage: " + root.value)
    onExited: if (root.bar) root.bar.hideTooltip(root)
    onClicked: function(mouse) { root.triggerPress(mouse.button) }
  }
}
