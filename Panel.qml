import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "io.github.diogogc.simple-openvpn"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  OpenVpnService {
    id: service
  }

  onOpenedChanged: {
    if (opened) {
      service.refresh()
      if (panelFlick) panelFlick.contentY = 0
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(mainCol.implicitHeight + Style.space(24), Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Flickable {
        id: panelFlick
        anchors.fill: parent
        anchors.margins: Style.spacing.panelPadding
        contentWidth: width
        contentHeight: mainCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: mainCol
          width: panelFlick.width
          spacing: Style.space(12)

        // ------------------------------------------------------------- HERO
        PanelHero {
          id: hero
          width: parent.width
          title: "SimpleOpenVPN"
          meta: service.connected
            ? ("Connected • " + (service.ip !== "" ? service.ip : service.iface))
            : (service.configName !== "" ? service.configName : "Disconnected")
          foreground: root.foreground
          fontFamily: root.fontFamily

          iconComponent: Component {
            Text {
              text: "󰦝"
              color: service.connected ? Color.accent : root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
              verticalAlignment: Text.AlignVCenter
              horizontalAlignment: Text.AlignHCenter
            }
          }

          trailingControl: Component {
            ToggleSwitch {
              id: connectionSwitch
              checked: service.active
              busy: service.busy
              foreground: hero.foreground
              onToggled: service.toggle()

              PanelToolTip {
                visible: connectionSwitch.containsMouse
                text: service.connected ? "Disconnect SimpleOpenVPN" : "Connect SimpleOpenVPN"
                fontFamily: hero.fontFamily
              }
            }
          }
        }

        // -------------------------------------------------- LIVE TUNNEL INFO
        Column {
          visible: service.connected
          width: parent.width
          spacing: Style.space(6)

          PanelSectionHeader {
            text: "Tunnel Status"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          BorderSurface {
            width: parent.width
            padding: Style.space(10)
            radius: Style.cornerRadius
            color: Style.controlFill(false, false, root.foreground, Color.accent)

            Column {
              width: parent.width
              spacing: Style.space(4)

              RowLayout {
                width: parent.width
                Text {
                  text: "Interface:"
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  Layout.preferredWidth: Style.space(90)
                }
                Text {
                  text: service.iface !== "" ? service.iface : "unknown"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: true
                  Layout.fillWidth: true
                }
              }

              RowLayout {
                width: parent.width
                Text {
                  text: "IP Address:"
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  Layout.preferredWidth: Style.space(90)
                }
                Text {
                  text: service.ip !== "" ? service.ip : "assigning…"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: true
                  Layout.fillWidth: true
                }
              }

              RowLayout {
                visible: service.bytesText !== ""
                width: parent.width
                Text {
                  text: "Traffic:"
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  Layout.preferredWidth: Style.space(90)
                }
                Text {
                  text: service.bytesText
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  Layout.fillWidth: true
                }
              }
            }
          }
        }

        PanelSeparator {
          width: parent.width
          foreground: root.foreground
        }

        // ---------------------------------------------------------- PROFILES
        Column {
          width: parent.width
          spacing: Style.space(6)

          PanelSectionHeader {
            text: "VPN Profiles"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          RowLayout {
            width: parent.width
            spacing: Style.space(8)

            Button {
              text: "Add Profile"
              iconText: "󰈔"
              bordered: true
              Layout.fillWidth: true
              foreground: root.foreground
              onClicked: service.addProfile()
            }

            Button {
              text: "Open Folder"
              iconText: ""
              bordered: true
              Layout.fillWidth: true
              foreground: root.foreground
              onClicked: service.openFolder()
            }
          }

          Text {
            visible: service.configs.length === 0
            text: "No .ovpn files found in " + service.configDir
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          Repeater {
            model: service.configs
            delegate: Button {
              required property string modelData
              width: mainCol.width
              leftAlign: true
              bordered: true
              selected: service.config === modelData
              text: {
                var parts = modelData.split("/")
                var name = parts[parts.length - 1]
                if (service.hasSavedAuthFor(modelData)) {
                  name += "  [auth]"
                }
                return name
              }
              iconText: service.config === modelData ? "✓" : (service.hasSavedAuthFor(modelData) ? "󰌆" : "  ")
              foreground: root.foreground
              onClicked: {
                passField.text = ""
                service.setConfig(modelData)
              }
            }
          }
        }

        PanelSeparator {
          width: parent.width
          foreground: root.foreground
        }

        // ------------------------------------------------------- CREDENTIALS
        Column {
          width: parent.width
          spacing: Style.space(8)

          RowLayout {
            width: parent.width
            PanelSectionHeader {
              text: service.configName !== "" ? ("Credentials (" + service.configName + ")") : "Credentials"
              foreground: root.foreground
              fontFamily: root.fontFamily
              Layout.fillWidth: true
            }
            Text {
              text: service.hasAuth ? "✓ Saved" : "No Auth"
              color: service.hasAuth ? Color.accent : root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: service.hasAuth
            }
          }

          TextField {
            id: userField
            width: parent.width
            placeholderText: "VPN Username"
            text: service.username
            foreground: root.foreground
          }

          TextField {
            id: passField
            width: parent.width
            placeholderText: service.hasAuth ? "Password (Saved • Enter to update)" : "VPN Password"
            password: true
            foreground: root.foreground
          }

          RowLayout {
            width: parent.width
            spacing: Style.space(8)

            Button {
              text: "Save for Profile"
              bordered: true
              Layout.fillWidth: true
              foreground: root.foreground
              onClicked: {
                if (userField.text.trim().length > 0) {
                  service.setCredentials(userField.text.trim(), passField.text)
                  passField.text = ""
                }
              }
            }

            Button {
              visible: service.hasAuth
              text: "Clear Auth"
              bordered: true
              foreground: root.urgent
              onClicked: {
                passField.text = ""
                service.clearCredentials()
              }
            }
          }
        }

        // ------------------------------------------------------------- LOGS
        Column {
          visible: service.logTail !== ""
          width: parent.width
          spacing: Style.space(6)

          PanelSeparator {
            width: parent.width
            foreground: root.foreground
          }

          PanelSectionHeader {
            text: "Recent Log"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          BorderSurface {
            width: parent.width
            padding: Style.space(8)
            radius: Style.cornerRadius
            color: Style.controlFill(false, false, root.foreground, Color.accent)

            Text {
              width: parent.width
              text: service.logTail
              color: root.dim
              font.family: "monospace"
              font.pixelSize: Style.font.caption
              wrapMode: Text.WrapAnywhere
            }
          }
        }
      }
    }
  }
}
}
