import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
  PanelWindow {
    id: win

    property int cardWidth: 720
    property int cardHeight: 480
    property int page: 0
    readonly property string ctl: `${Quickshell.shellDir}/ctl.sh`
    property string wifiRadio: "off"
    property var wifiRows: []
    property string ethernetText: ""
    property string airplane: "off"
    property string pendingSsid: ""
    property string pendingSec: ""
    property string brightness: ""
    property var monitors: []
    property string volume: ""
    property string defaultSink: ""
    property var sinks: []
    property string defaultSource: ""
    property var sources: []
    property string btPower: "no"
    property var btDevices: []
    property var batteries: []
    property string timeoutMins: "10"
    property string distro: ""
    property double sliderUntil: 0

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
    WlrLayershell.namespace: "settings-panel"
    WlrLayershell.layer: WlrLayer.Overlay

    Keys.onEscapePressed: Qt.quit()

    function runCtl(args) {
      Quickshell.execDetached([ctl].concat(args))
    }

    function kick(proc) {
      proc.running = false
      Qt.callLater(() => {
        proc.running = true
      })
    }

    function lockSlider() {
      sliderUntil = Date.now() + 1500
    }

    function scanBt() {
      kick(btScanProc)
    }

    function refresh() {
      if (page === 0) {
        kick(wifiRadioProc)
        kick(wifiListProc)
        kick(ethProc)
        kick(airProc)
      } else if (page === 1) {
        kick(brightProc)
        kick(monProc)
      } else if (page === 2) {
        kick(volProc)
        kick(sinkProc)
        kick(srcProc)
      } else if (page === 3) {
        kick(btPowerProc)
        kick(btDevProc)
      } else if (page === 4) {
        kick(batProc)
        kick(timeoutProc)
      } else {
        kick(distroProc)
      }
    }

    function parseLines(text, fn) {
      const out = []
      const lines = String(text || "").split("\n")
      for (let i = 0; i < lines.length; i++) {
        const line = lines[i].replace(/\s+$/, "")
        if (!line)
          continue
        const row = fn(line)
        if (row)
          out.push(row)
      }
      return out
    }

    function afterSet() {
      later.restart()
    }

    onPageChanged: refresh()

    Rectangle {
      anchors.fill: parent
      color: "#32302f"
      border.color: "#d4be98"
      border.width: 2
      radius: 12
      clip: true

      RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Rectangle {
          Layout.preferredWidth: 176
          Layout.fillHeight: true
          radius: 8
          color: "#3c3836"
          border.color: "#504945"
          border.width: 1

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            Text {
              text: "Definições"
              color: "#d4be98"
              font.family: "FiraCode Nerd Font Mono"
              font.pixelSize: 14
              font.bold: true
            }

            NavItem { idx: 0; glyph: "󰖩"; label: "Rede" }
            NavItem { idx: 1; glyph: "󰍹"; label: "Ecrã" }
            NavItem { idx: 2; glyph: "󰕾"; label: "Som" }
            NavItem { idx: 3; glyph: "󰂯"; label: "Bluetooth" }
            NavItem { idx: 4; glyph: "󰁹"; label: "Energia" }
            NavItem { idx: 5; glyph: "󰣇"; label: "Sobre" }
            Item { Layout.fillHeight: true }
          }
        }

        StackLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          currentIndex: win.page

          NetworkPage {}
          DisplayPage {}
          SoundPage {}
          BluetoothPage {}
          PowerPage {}
          AboutPage {}
        }
      }
    }

    Timer {
      interval: 80
      running: true
      onTriggered: win.refresh()
    }

    Timer {
      id: later
      interval: 500
      onTriggered: win.refresh()
    }

    Timer {
      interval: 4000
      running: true
      repeat: true
      onTriggered: win.refresh()
    }

    Process {
      id: wifiRadioProc
      command: [win.ctl, "wifi-radio"]
      stdout: StdioCollector {
        onStreamFinished: win.wifiRadio = text.trim()
      }
    }

    Process {
      id: wifiListProc
      command: [win.ctl, "wifi-list"]
      stdout: StdioCollector {
        onStreamFinished: {
          win.wifiRows = win.parseLines(text, line => {
            const p = line.split("|")
            return {
              used: p[0] === "1",
              ssid: p[1] || "",
              signal: p[2] || "",
              security: p[3] || ""
            }
          })
        }
      }
    }

    Process {
      id: ethProc
      command: [win.ctl, "ethernet"]
      stdout: StdioCollector {
        onStreamFinished: {
          const line = text.trim()
          if (!line) {
            win.ethernetText = "Nenhum dispositivo"
            return
          }
          const p = line.split("|")
          const name = p[0] || "ethernet"
          const st = p[1] || "desconhecido"
          win.ethernetText = name + " · " + st
        }
      }
    }

    Process {
      id: airProc
      command: [win.ctl, "airplane"]
      stdout: StdioCollector {
        onStreamFinished: win.airplane = text.trim()
      }
    }

    Process {
      id: brightProc
      command: [win.ctl, "brightness"]
      stdout: StdioCollector {
        onStreamFinished: {
          if (Date.now() < win.sliderUntil)
            return
          win.brightness = text.trim()
        }
      }
    }

    Process {
      id: monProc
      command: [win.ctl, "monitors"]
      stdout: StdioCollector {
        onStreamFinished: {
          win.monitors = win.parseLines(text, line => {
            const p = line.split("|")
            const modes = (p[4] || "").split(",").filter(m => m.length > 0)
            return {
              name: p[0] || "",
              res: p[1] || "",
              refresh: p[2] || "",
              scale: p[3] || "1",
              modes: modes
            }
          })
        }
      }
    }

    Process {
      id: volProc
      command: [win.ctl, "volume"]
      stdout: StdioCollector {
        onStreamFinished: {
          if (Date.now() < win.sliderUntil)
            return
          win.volume = text.trim()
        }
      }
    }

    Process {
      id: sinkProc
      command: [win.ctl, "sinks"]
      stdout: StdioCollector {
        onStreamFinished: {
          const sinks = []
          let def = ""
          win.parseLines(text, line => {
            const p = line.split("|")
            if (p[0] === "default")
              def = p[1] || ""
            else if (p[0] === "sink" && p[1])
              sinks.push(p[1])
            return null
          })
          win.defaultSink = def
          win.sinks = sinks
        }
      }
    }

    Process {
      id: srcProc
      command: [win.ctl, "sources"]
      stdout: StdioCollector {
        onStreamFinished: {
          const sources = []
          let def = ""
          win.parseLines(text, line => {
            const p = line.split("|")
            if (p[0] === "default")
              def = p[1] || ""
            else if (p[0] === "source" && p[1])
              sources.push(p[1])
            return null
          })
          win.defaultSource = def
          win.sources = sources
        }
      }
    }

    Process {
      id: btPowerProc
      command: [win.ctl, "bt-power"]
      stdout: StdioCollector {
        onStreamFinished: win.btPower = text.trim() || "no"
      }
    }

    Process {
      id: btDevProc
      command: [win.ctl, "bt-devices"]
      stdout: StdioCollector {
        onStreamFinished: {
          win.btDevices = win.parseLines(text, line => {
            const i = line.indexOf("|")
            if (i < 0)
              return null
            return { mac: line.slice(0, i), name: line.slice(i + 1) }
          })
        }
      }
    }

    Process {
      id: btScanProc
      command: [win.ctl, "bt-scan"]
      stdout: StdioCollector {
        onStreamFinished: {
          win.btDevices = win.parseLines(text, line => {
            const i = line.indexOf("|")
            if (i < 0)
              return null
            return { mac: line.slice(0, i), name: line.slice(i + 1) }
          })
        }
      }
    }

    Process {
      id: batProc
      command: [win.ctl, "battery"]
      stdout: StdioCollector {
        onStreamFinished: {
          win.batteries = win.parseLines(text, line => {
            const p = line.split("|")
            return { name: p[0] || "BAT", cap: p[1] || "?", status: p[2] || "" }
          })
        }
      }
    }

    Process {
      id: timeoutProc
      command: [win.ctl, "timeout"]
      stdout: StdioCollector {
        onStreamFinished: win.timeoutMins = text.trim() || "10"
      }
    }

    Process {
      id: distroProc
      command: [win.ctl, "distro"]
      stdout: StdioCollector {
        onStreamFinished: win.distro = text.trim()
      }
    }
  }

  component NavItem: Rectangle {
    id: nav
    property int idx
    property string glyph
    property string label
    Layout.fillWidth: true
    implicitHeight: 36
    radius: 8
    color: mouse.containsMouse || win.page === idx ? "#504945" : "transparent"
    border.color: win.page === idx ? "#d4be98" : "transparent"
    border.width: 1

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: win.page = nav.idx
    }

    Row {
      anchors.verticalCenter: parent.verticalCenter
      anchors.left: parent.left
      anchors.leftMargin: 10
      spacing: 8

      Text {
        text: nav.glyph
        color: win.page === nav.idx ? "#d4be98" : "#ebdbb2"
        font.family: "FiraCode Nerd Font Mono"
        font.pixelSize: 14
      }

      Text {
        text: nav.label
        color: "#ebdbb2"
        font.family: "FiraCode Nerd Font Mono"
        font.pixelSize: 13
      }
    }
  }

  component Heading: Text {
    color: "#d4be98"
    font.family: "FiraCode Nerd Font Mono"
    font.pixelSize: 13
    font.bold: true
  }

  component Body: Text {
    color: "#ebdbb2"
    font.family: "FiraCode Nerd Font Mono"
    font.pixelSize: 12
    wrapMode: Text.WordWrap
  }

  component EmptyHint: Text {
    color: "#a89984"
    font.family: "FiraCode Nerd Font Mono"
    font.pixelSize: 12
    text: "Nenhum dispositivo"
  }

  component Chip: Rectangle {
    id: chip
    property string label
    property bool selected: false
    property bool enabled: true
    signal clicked

    Layout.fillWidth: true
    implicitHeight: 32
    radius: 8
    color: mouse.containsMouse && enabled ? "#504945" : "#3c3836"
    border.color: selected ? "#d4be98" : "#504945"
    border.width: selected ? 2 : 1
    opacity: enabled ? 1 : 0.45

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: chip.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: if (chip.enabled) chip.clicked()
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: 10
      text: chip.label
      color: chip.selected ? "#d4be98" : "#ebdbb2"
      elide: Text.ElideRight
      font.family: "FiraCode Nerd Font Mono"
      font.pixelSize: 12
    }
  }

  component ToggleChip: Chip {
    property bool on: false
    selected: on
    label: on ? "Ligado" : "Desligado"
  }

  component ToneSlider: Slider {
    id: s
    property color fill: "#e78a4e"
    from: 0
    to: 100
    stepSize: 1
    live: true
    implicitHeight: 22
    background: Rectangle {
      x: s.leftPadding
      y: s.topPadding + s.availableHeight / 2 - 2
      implicitWidth: 120
      implicitHeight: 4
      width: s.availableWidth
      height: 4
      radius: 2
      color: "#3c3836"
      Rectangle {
        width: s.visualPosition * parent.width
        height: parent.height
        radius: 2
        color: s.fill
      }
    }
    handle: Rectangle {
      x: s.leftPadding + s.visualPosition * (s.availableWidth - width)
      y: s.topPadding + s.availableHeight / 2 - height / 2
      implicitWidth: 14
      implicitHeight: 14
      radius: 7
      color: "#d4be98"
      border.color: "#504945"
      border.width: 1
    }
  }

  component NetworkPage: Flickable {
    clip: true
    contentWidth: width
    contentHeight: netCol.implicitHeight
    ColumnLayout {
      id: netCol
      width: parent.width
      spacing: 8

      Heading { text: "Wi-Fi" }
      ToggleChip {
        on: win.wifiRadio === "on"
        onClicked: {
          win.runCtl(["wifi-radio-set", win.wifiRadio === "on" ? "off" : "on"])
          win.afterSet()
        }
      }

      Heading { text: "Redes" }
      EmptyHint { visible: win.wifiRows.length === 0 }
      Repeater {
        model: win.wifiRows
        Chip {
          required property var modelData
          label: (modelData.used ? "● " : "") + modelData.ssid + (modelData.signal ? "  " + modelData.signal + "%" : "")
          selected: modelData.used
          enabled: win.wifiRadio === "on"
          onClicked: {
            const open = !modelData.security || modelData.security === "--"
            if (open) {
              win.runCtl(["wifi-connect", modelData.ssid])
              win.pendingSsid = ""
              win.afterSet()
            } else {
              win.pendingSsid = modelData.ssid
              win.pendingSec = modelData.security
            }
          }
        }
      }

      ColumnLayout {
        visible: win.pendingSsid.length > 0
        spacing: 6
        Body { text: "Palavra-passe · " + win.pendingSsid + (win.pendingSec ? " (" + win.pendingSec + ")" : "") }
        TextField {
          id: wifiPass
          Layout.fillWidth: true
          echoMode: TextInput.Password
          color: "#ebdbb2"
          font.family: "FiraCode Nerd Font Mono"
          font.pixelSize: 12
          background: Rectangle {
            color: "#3c3836"
            border.color: "#504945"
            radius: 8
          }
        }
        Chip {
          label: "Ligar"
          onClicked: {
            win.runCtl(["wifi-connect", win.pendingSsid, wifiPass.text])
            win.pendingSsid = ""
            wifiPass.text = ""
            win.afterSet()
          }
        }
      }

      Heading { text: "Cabo" }
      Body { text: win.ethernetText || "Nenhum dispositivo" }

      Heading { text: "Modo de voo" }
      ToggleChip {
        on: win.airplane === "on"
        onClicked: {
          win.runCtl(["airplane-set", win.airplane === "on" ? "off" : "on"])
          win.afterSet()
        }
      }
    }
  }

  component DisplayPage: Flickable {
    clip: true
    contentWidth: width
    contentHeight: dispCol.implicitHeight
    ColumnLayout {
      id: dispCol
      width: parent.width
      spacing: 8

      Heading { text: "Brilho" }
      EmptyHint { visible: win.brightness.length === 0 }
      ToneSlider {
        id: brightSlider
        visible: win.brightness.length > 0
        Layout.fillWidth: true
        fill: "#d8a657"
        value: Number(win.brightness) || 0
        onMoved: {
          win.lockSlider()
          brightWait.restart()
        }
      }
      Timer {
        id: brightWait
        interval: 80
        onTriggered: {
          win.lockSlider()
          win.runCtl(["brightness-set", String(Math.round(brightSlider.value))])
          win.brightness = String(Math.round(brightSlider.value))
        }
      }

      Heading { text: "Ecrãs" }
      EmptyHint { visible: win.monitors.length === 0 }
      Repeater {
        model: win.monitors
        ColumnLayout {
          id: monBox
          required property var modelData
          spacing: 6
          Body {
            text: monBox.modelData.name + " · " + monBox.modelData.res + " @ " + (Number(monBox.modelData.refresh) || 0).toFixed(0) + " Hz · escala " + monBox.modelData.scale
          }
          Heading { text: "Resolução" }
          Repeater {
            model: monBox.modelData.modes
            Chip {
              required property string modelData
              label: modelData
              selected: modelData.indexOf(monBox.modelData.res) === 0
              onClicked: {
                win.runCtl(["monitor-set", monBox.modelData.name, modelData, monBox.modelData.scale])
                win.afterSet()
              }
            }
          }
          Heading { text: "Escala" }
          RowLayout {
            spacing: 6
            Repeater {
              model: ["1", "1.25", "1.5", "2"]
              Chip {
                required property string modelData
                Layout.fillWidth: true
                label: modelData + "×"
                selected: Number(monBox.modelData.scale) === Number(modelData)
                onClicked: {
                  const mon = monBox.modelData
                  const hit = (mon.modes || []).find(m => m.indexOf(mon.res) === 0)
                  const mode = hit || (mon.res + "@" + mon.refresh)
                  win.runCtl(["monitor-set", mon.name, mode, modelData])
                  win.afterSet()
                }
              }
            }
          }
        }
      }
    }
  }

  component SoundPage: Flickable {
    clip: true
    contentWidth: width
    contentHeight: sndCol.implicitHeight
    ColumnLayout {
      id: sndCol
      width: parent.width
      spacing: 8

      Heading { text: "Volume" }
      EmptyHint { visible: win.volume.length === 0 }
      ToneSlider {
        id: volSlider
        visible: win.volume.length > 0
        Layout.fillWidth: true
        fill: "#e78a4e"
        value: Number(win.volume) || 0
        onMoved: {
          win.lockSlider()
          volWait.restart()
        }
      }
      Timer {
        id: volWait
        interval: 80
        onTriggered: {
          win.lockSlider()
          win.runCtl(["volume-set", String(Math.round(volSlider.value))])
          win.volume = String(Math.round(volSlider.value))
        }
      }

      Heading { text: "Saída" }
      EmptyHint { visible: win.sinks.length === 0 }
      Repeater {
        model: win.sinks
        Chip {
          required property string modelData
          label: modelData
          selected: modelData === win.defaultSink
          onClicked: {
            win.runCtl(["sink-set", modelData])
            win.afterSet()
          }
        }
      }

      Heading { text: "Microfone" }
      EmptyHint { visible: win.sources.length === 0 }
      Repeater {
        model: win.sources
        Chip {
          required property string modelData
          label: modelData
          selected: modelData === win.defaultSource
          onClicked: {
            win.runCtl(["source-set", modelData])
            win.afterSet()
          }
        }
      }
    }
  }

  component BluetoothPage: Flickable {
    clip: true
    contentWidth: width
    contentHeight: btCol.implicitHeight
    ColumnLayout {
      id: btCol
      width: parent.width
      spacing: 8

      Heading { text: "Bluetooth" }
      ToggleChip {
        on: win.btPower === "yes"
        onClicked: {
          win.runCtl(["bt-power-set", win.btPower === "yes" ? "off" : "on"])
          win.afterSet()
        }
      }
      Chip {
        label: "Procurar dispositivos"
        enabled: win.btPower === "yes"
        onClicked: win.scanBt()
      }
      Heading { text: "Dispositivos" }
      EmptyHint { visible: win.btDevices.length === 0 }
      Repeater {
        model: win.btDevices
        Chip {
          required property var modelData
          label: (modelData.name || modelData.mac) + "  " + modelData.mac
          enabled: win.btPower === "yes"
          onClicked: {
            win.runCtl(["bt-connect", modelData.mac])
            win.afterSet()
          }
        }
      }
    }
  }

  component PowerPage: Flickable {
    clip: true
    contentWidth: width
    contentHeight: pwrCol.implicitHeight
    ColumnLayout {
      id: pwrCol
      width: parent.width
      spacing: 8

      Heading { text: "Bateria" }
      EmptyHint { visible: win.batteries.length === 0 }
      Repeater {
        model: win.batteries
        Body {
          required property var modelData
          text: modelData.name + " · " + modelData.cap + "% · " + modelData.status
        }
      }

      Heading { text: "Desligar o ecrã após" }
      Repeater {
        model: [
          { mins: "0", label: "Nunca" },
          { mins: "5", label: "5 minutos" },
          { mins: "10", label: "10 minutos" },
          { mins: "15", label: "15 minutos" },
          { mins: "30", label: "30 minutos" }
        ]
        Chip {
          required property var modelData
          label: modelData.label
          selected: win.timeoutMins === modelData.mins
          onClicked: {
            win.runCtl(["timeout-set", modelData.mins])
            win.timeoutMins = modelData.mins
            win.afterSet()
          }
        }
      }
    }
  }

  component AboutPage: Item {
    ColumnLayout {
      anchors.centerIn: parent
      spacing: 12

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: "󰣇"
        color: "#d4be98"
        font.family: "FiraCode Nerd Font Mono"
        font.pixelSize: 56
      }

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: win.distro || "Arch Linux"
        color: "#ebdbb2"
        font.family: "FiraCode Nerd Font Mono"
        font.pixelSize: 16
        font.bold: true
      }

      Body {
        Layout.alignment: Qt.AlignHCenter
        text: "Hyprland · Gruvbox"
      }
    }
  }
}
