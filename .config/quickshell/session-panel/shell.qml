import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris

ShellRoot {
  PanelWindow {
    id: win

    property int cardWidth: 400
    property int cardHeight: 228
    property var player: {
      const list = Mpris.players.values
      if (!list || list.length === 0)
        return null
      for (let i = 0; i < list.length; i++) {
        if (list[i].isPlaying)
          return list[i]
      }
      return list[0]
    }

    anchors.top: true
    anchors.left: true
    margins.top: 52
    margins.left: Math.max(0, Math.round(((screen?.width ?? 1920) - cardWidth) / 2))
    implicitWidth: cardWidth
    implicitHeight: cardHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    focusable: true
    aboveWindows: true
    WlrLayershell.namespace: "session-panel"
    WlrLayershell.layer: WlrLayer.Overlay

    Keys.onEscapePressed: Qt.quit()

    function fmtTime(seconds) {
      if (!seconds || seconds < 0)
        return "0:00"
      const m = Math.floor(seconds / 60)
      const s = Math.floor(seconds % 60)
      return m + ":" + (s < 10 ? "0" : "") + s
    }

    function run(cmd) {
      Quickshell.execDetached(cmd)
      Qt.quit()
    }

    Rectangle {
      anchors.fill: parent
      color: "#32302f"
      border.color: "#d4be98"
      border.width: 2
      radius: 12

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: 12

          Rectangle {
            Layout.preferredWidth: 96
            Layout.preferredHeight: 96
            Layout.alignment: Qt.AlignVCenter
            radius: 8
            color: "#3c3836"
            clip: true

            Image {
              id: art
              anchors.fill: parent
              source: win.player ? (win.player.trackArtUrl || "") : ""
              fillMode: Image.PreserveAspectCrop
              visible: status === Image.Ready
            }

            Text {
              anchors.centerIn: parent
              visible: !win.player || art.status !== Image.Ready
              text: "󰎆"
              color: "#7c6f64"
              font.family: "FiraCode Nerd Font Mono"
              font.pixelSize: 28
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4

            Text {
              Layout.fillWidth: true
              text: win.player ? (win.player.trackTitle || "Sem título") : "Nada a reproduzir"
              color: "#ebdbb2"
              elide: Text.ElideRight
              font.pixelSize: 14
              font.bold: true
              font.family: "FiraCode Nerd Font Mono"
            }

            Text {
              Layout.fillWidth: true
              text: win.player ? (win.player.trackArtist || win.player.identity || "") : "Spotify, Firefox, VLC, …"
              color: "#a89984"
              elide: Text.ElideRight
              font.pixelSize: 12
              font.family: "FiraCode Nerd Font Mono"
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 6

              Text {
                text: win.fmtTime(win.player ? win.player.position : 0)
                color: "#7c6f64"
                font.pixelSize: 10
                font.family: "FiraCode Nerd Font Mono"
              }

              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 4
                radius: 2
                color: "#3c3836"

                Rectangle {
                  width: parent.width * (
                    win.player && win.player.length > 0
                      ? Math.min(1, win.player.position / win.player.length)
                      : 0
                  )
                  height: parent.height
                  radius: 2
                  color: "#d4be98"
                }
              }

              Text {
                text: win.fmtTime(win.player ? win.player.length : 0)
                color: "#7c6f64"
                font.pixelSize: 10
                font.family: "FiraCode Nerd Font Mono"
              }
            }

            Row {
              Layout.alignment: Qt.AlignHCenter
              spacing: 10

              MediaButton {
                glyph: "󰒮"
                label: "Anterior"
                canUse: win.player && win.player.canGoPrevious
                onClicked: if (win.player) win.player.previous()
              }

              MediaButton {
                glyph: win.player && win.player.isPlaying ? "󰏤" : "󰐊"
                label: win.player && win.player.isPlaying ? "Pausar" : "Reproduzir"
                canUse: win.player && win.player.canTogglePlaying
                onClicked: if (win.player) win.player.togglePlaying()
              }

              MediaButton {
                glyph: "󰒭"
                label: "Seguinte"
                canUse: win.player && win.player.canGoNext
                onClicked: if (win.player) win.player.next()
              }
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          Layout.preferredHeight: 48
          spacing: 8

          SysButton {
            glyph: "󰒲"
            label: "Suspender"
            tint: "#d8a657"
            onClicked: win.run(["systemctl", "suspend"])
          }

          SysButton {
            glyph: "󰜉"
            label: "Reiniciar"
            tint: "#e78a4e"
            onClicked: win.run(["systemctl", "reboot"])
          }

          SysButton {
            glyph: "󰐥"
            label: "Desligar"
            tint: "#ea6962"
            onClicked: win.run(["systemctl", "poweroff"])
          }

          SysButton {
            glyph: "󰍃"
            label: "Sessão"
            tint: "#d4be98"
            onClicked: win.run(["hyprctl", "dispatch", "hl.dsp.exit()"])
          }
        }
      }
    }

    Timer {
      running: win.player && win.player.isPlaying
      interval: 500
      repeat: true
      onTriggered: if (win.player) win.player.positionChanged()
    }
  }

  component MediaButton: Rectangle {
    id: mediaBtn
    property string glyph
    property string label
    property bool canUse: true
    signal clicked

    implicitWidth: 32
    implicitHeight: 32
    radius: 8
    color: mouse.containsMouse && canUse ? "#504945" : "#3c3836"
    opacity: canUse ? 1 : 0.4

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: mediaBtn.canUse ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: if (mediaBtn.canUse) mediaBtn.clicked()

      ToolTip {
        visible: mouse.containsMouse
        delay: 250
        contentItem: Text {
          text: mediaBtn.label
          color: "#fbf1c7"
          font.family: "FiraCode Nerd Font Mono"
          font.pixelSize: 14
          font.bold: true
        }
        background: Rectangle {
          color: "#32302f"
          border.color: "#252423"
          border.width: 1
        }
      }
    }

    Text {
      anchors.centerIn: parent
      text: mediaBtn.glyph
      color: "#ebdbb2"
      font.family: "FiraCode Nerd Font Mono"
      font.pixelSize: 16
    }
  }

  component SysButton: Rectangle {
    id: sysBtn
    property string glyph
    property string label
    property color tint
    signal clicked

    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitHeight: 44
    radius: 8
    color: mouse.containsMouse ? "#504945" : "#3c3836"
    border.color: "#504945"
    border.width: 1

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: sysBtn.clicked()

      ToolTip {
        visible: mouse.containsMouse
        delay: 250
        contentItem: Text {
          text: sysBtn.label
          color: "#fbf1c7"
          font.family: "FiraCode Nerd Font Mono"
          font.pixelSize: 14
          font.bold: true
        }
        background: Rectangle {
          color: "#32302f"
          border.color: "#252423"
          border.width: 1
        }
      }
    }

    Text {
      anchors.centerIn: parent
      text: sysBtn.glyph
      color: sysBtn.tint
      font.family: "FiraCode Nerd Font Mono"
      font.pixelSize: 20
      font.bold: true
    }
  }
}
