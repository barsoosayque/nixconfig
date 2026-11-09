{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkMerge mkEnableOption;
  inherit (builtins) hashString replaceStrings substring;

  cfg = config.modules.programs.quickshell;
  colors = config.system.pretty.theme.colors;

  quickshell = "${pkgs.quickshell}/bin/quickshell";
  daemon = "${quickshell} -c panels -d";

  shellQmlBody = ''
    pragma ComponentBehavior: Bound
    
    import QtQuick
    import Quickshell
    import Quickshell.Bluetooth
    import Quickshell.Io
    import Quickshell.Networking
    import Quickshell.Services.Pipewire
    
    ShellRoot {
      id: root
    
      readonly property color bg: "${colors.bar.background.hexARGB}"
      readonly property color fg: "${colors.bar.foreground.hexRGB}"
      readonly property color dim: "${colors.bright.black.hexRGB}"
      readonly property color accent: "${colors.normal.yellow.hexRGB}"
      readonly property color danger: "${colors.normal.red.hexRGB}"
    
      // ------------------------------------------------------------ audio
    
      readonly property PwNode sink: Pipewire.defaultAudioSink
      readonly property var streams: Pipewire.nodes.values.filter(function (n) {
        return n.isStream && n.audio !== null;
      })
    
      // Volume and mute are only live on nodes that are explicitly bound.
      PwObjectTracker {
        objects: root.sink ? [root.sink].concat(root.streams) : root.streams
      }
    
      // ------------------------------------------------------------- wifi
    
      readonly property WifiDevice wifi: Networking.devices.values.find(function (d) {
        return d.type === DeviceType.Wifi;
      }) ?? null
    
      // Only burn radio time on scanning while the panel is open.
      Binding {
        target: root.wifi
        property: "scannerEnabled"
        value: wifiPanel.open
        when: root.wifi !== null
      }
    
      // -------------------------------------------------------- bluetooth
    
      readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    
      Binding {
        target: root.adapter
        property: "discovering"
        value: bluetoothPanel.open && root.adapter.enabled
        when: root.adapter !== null
      }
    
      // -------------------------------------------------------------- ipc
    
      IpcHandler {
        target: "audio"
    
        function toggle(): void { audioPanel.open = !audioPanel.open; }
        function show(): void { audioPanel.open = true; }
        function hide(): void { audioPanel.open = false; }
      }
    
      IpcHandler {
        target: "wifi"
    
        function toggle(): void { wifiPanel.open = !wifiPanel.open; }
        function show(): void { wifiPanel.open = true; }
        function hide(): void { wifiPanel.open = false; }
      }
    
      IpcHandler {
        target: "bluetooth"
    
        function toggle(): void { bluetoothPanel.open = !bluetoothPanel.open; }
        function show(): void { bluetoothPanel.open = true; }
        function hide(): void { bluetoothPanel.open = false; }
      }
    
      // Lets the toggle scripts notice an instance left over from an older
      // generation, which quickshell cannot see for itself: the config path is a
      // symlink into the store, so its file watcher never fires on a rebuild.
      IpcHandler {
        target: "shell"
    
        property string revision: "@revision@"
      }
    
      // ---------------------------------------------------------- pieces
    
      // The window covers the whole output so that a click anywhere
      // outside the panel dismisses it; only the panel is painted.
      component Popup: PanelWindow {
        id: win
    
        property bool open: false
        readonly property int contentWidth: 316
        default property alias content: body.data
    
        visible: win.open
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
    
        anchors {
          top: true
          bottom: true
          left: true
          right: true
        }
    
        Item {
          anchors.fill: parent
          focus: true
    
          Keys.onEscapePressed: win.open = false
    
          MouseArea {
            anchors.fill: parent
            onClicked: win.open = false
          }
    
          Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 48
            anchors.rightMargin: 20
            width: win.contentWidth + 24
            height: body.implicitHeight + 24
            radius: 15
            color: root.bg
    
            // Clicks on the panel must not dismiss it. Declared before the
            // content so the rows still get their events first.
            MouseArea {
              anchors.fill: parent
            }
    
            Column {
              id: body
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.margins: 12
              spacing: 6
            }
          }
        }
      }
    
      component Heading: Text {
        color: root.dim
        font.pixelSize: 12
        font.capitalization: Font.AllUppercase
      }
    
      // Panel header: a title on the left, a radio on/off switch right.
      component Header: Item {
        id: header
    
        required property string title
        required property bool on
        property bool switchable: true
    
        signal toggled
    
        implicitHeight: 24
    
        Heading {
          anchors.verticalCenter: parent.verticalCenter
          text: header.title
        }
    
        Text {
          id: state
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          font.pixelSize: 12
          font.capitalization: Font.AllUppercase
          color: header.on ? root.accent : root.dim
          text: header.on ? "on" : "off"
          visible: header.switchable
        }
    
        MouseArea {
          anchors.fill: state
          anchors.margins: -8
          enabled: header.switchable
          onClicked: header.toggled()
        }
      }
    
      component Separator: Rectangle {
        height: 1
        color: root.dim
      }
    
      // One labelled volume bar: click or drag the bar to set the volume,
      // click the name to toggle mute.
      component VolumeRow: Item {
        id: row
    
        required property PwNode node
        required property string label
    
        implicitHeight: 46
    
        Text {
          id: name
          anchors.left: parent.left
          anchors.right: percent.left
          anchors.rightMargin: 8
          elide: Text.ElideRight
          color: row.node?.audio?.muted ? root.dim : root.fg
          font.pixelSize: 14
          text: row.label
        }
    
        Text {
          id: percent
          anchors.right: parent.right
          color: root.dim
          font.pixelSize: 14
          text: Math.round((row.node?.audio?.volume ?? 0) * 100) + "%"
        }
    
        MouseArea {
          anchors.fill: name
          onClicked: row.node.audio.muted = !row.node.audio.muted
        }
    
        Rectangle {
          id: track
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 8
          height: 6
          radius: 3
          color: root.dim
    
          Rectangle {
            width: Math.max(0, Math.min(1, row.node?.audio?.volume ?? 0)) * track.width
            height: parent.height
            radius: parent.radius
            color: row.node?.audio?.muted ? root.dim : root.accent
          }
    
          MouseArea {
            anchors.fill: parent
            anchors.margins: -10
            onPressed: function (mouse) { row.node.audio.volume = mouse.x / track.width; }
            onPositionChanged: function (mouse) { row.node.audio.volume = mouse.x / track.width; }
          }
        }
      }
    
      // One network: click to connect or disconnect. Secured networks we
      // have no saved profile for ask for a password first, as does any
      // network NetworkManager rejects for missing secrets.
      component WifiRow: Item {
        id: netRow
    
        required property WifiNetwork network
        property bool asking: false
    
        readonly property bool needsPassword: {
          const s = netRow.network.security;
          return s !== WifiSecurityType.Open && s !== WifiSecurityType.Owe;
        }
    
        implicitHeight: 26 + (netRow.asking ? 34 : 0)
    
        Connections {
          target: netRow.network
    
          function onConnectionFailed(reason: int): void {
            if (reason === ConnectionFailReason.NoSecrets) netRow.asking = true;
          }
        }
    
        Text {
          id: ssid
          anchors.left: parent.left
          anchors.right: signal.left
          anchors.rightMargin: 8
          elide: Text.ElideRight
          font.pixelSize: 14
          color: netRow.network.connected ? root.accent : root.fg
          text: netRow.network.name
            + (netRow.network.state === ConnectionState.Connecting ? "  ..." : "")
            + (netRow.network.known && !netRow.network.connected ? "  *" : "")
        }
    
        Text {
          id: signal
          anchors.right: parent.right
          color: root.dim
          font.pixelSize: 14
          text: Math.round(netRow.network.signalStrength * 100) + "%"
            + (netRow.needsPassword ? "  #" : "")
        }
    
        MouseArea {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          height: 26
    
          onClicked: {
            const network = netRow.network;
    
            if (network.connected) {
              network.disconnect();
            } else if (network.known || !netRow.needsPassword) {
              network.connect();
            } else {
              netRow.asking = !netRow.asking;
            }
          }
        }
    
        Rectangle {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 4
          height: 26
          radius: 4
          color: root.bg
          border.width: 1
          border.color: root.dim
          visible: netRow.asking
    
          TextInput {
            id: psk
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            verticalAlignment: TextInput.AlignVCenter
            echoMode: TextInput.Password
            font.pixelSize: 13
            color: root.fg
            selectionColor: root.accent
            selectByMouse: true
    
            onVisibleChanged: if (visible) psk.forceActiveFocus()
    
            onAccepted: {
              netRow.network.connectWithPsk(psk.text);
              psk.text = "";
              netRow.asking = false;
            }
          }
        }
      }
    
      // One bluetooth device: left click connects, disconnects, or pairs
      // an unpaired one; right click forgets a paired one. Pairing that
      // needs a PIN is answered by the blueman agent, as before.
      component BtRow: Item {
        id: btRow
    
        required property BluetoothDevice device
    
        readonly property string hint: {
          const device = btRow.device;
    
          if (device.pairing) return "pairing...";
          if (device.state === BluetoothDeviceState.Connecting) return "...";
          if (device.state === BluetoothDeviceState.Disconnecting) return "...";
          if (device.connected && device.batteryAvailable) {
            return Math.round(device.battery * 100) + "%";
          }
          if (device.connected) return "connected";
          if (device.paired || device.bonded) return "paired";
          return "new";
        }
    
        implicitHeight: 26
    
        Text {
          anchors.left: parent.left
          anchors.right: hint.left
          anchors.rightMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          elide: Text.ElideRight
          font.pixelSize: 14
          color: btRow.device.connected ? root.accent : root.fg
          text: btRow.device.deviceName || btRow.device.address
        }
    
        Text {
          id: hint
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          font.pixelSize: 14
          color: root.dim
          text: btRow.hint
        }
    
        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton | Qt.RightButton
    
          onClicked: function (mouse) {
            const device = btRow.device;
    
            if (mouse.button === Qt.RightButton) {
              if (device.paired || device.bonded) device.forget();
              return;
            }
    
            if (device.pairing) device.cancelPair();
            else if (device.connected) device.disconnect();
            else if (device.paired || device.bonded) device.connect();
            else device.pair();
          }
        }
      }
    
      // ---------------------------------------------------------- panels
    
      Popup {
        id: audioPanel
    
        VolumeRow {
          width: audioPanel.contentWidth
          visible: root.sink !== null
          node: root.sink
          label: root.sink ? (root.sink.description || root.sink.name) : ""
        }
    
        Separator {
          width: audioPanel.contentWidth
          visible: root.streams.length > 0
        }
    
        Repeater {
          model: root.streams
    
          VolumeRow {
            required property PwNode modelData
    
            width: audioPanel.contentWidth
            node: modelData
            label: modelData?.properties["application.name"] || modelData?.name || ""
          }
        }
      }
    
      Popup {
        id: wifiPanel
    
        Header {
          width: wifiPanel.contentWidth
          title: root.wifi ? root.wifi.name : "no wifi device"
          on: Networking.wifiEnabled
          onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
        }
    
        Separator {
          width: wifiPanel.contentWidth
        }
    
        Text {
          width: wifiPanel.contentWidth
          color: root.dim
          font.pixelSize: 13
          visible: Networking.wifiEnabled && (!root.wifi || root.wifi.networks.values.length === 0)
          text: "scanning..."
        }
    
        Repeater {
          model: ScriptModel {
            values: root.wifi && Networking.wifiEnabled
              ? [...root.wifi.networks.values].sort(function (a, b) {
                  if (a.connected !== b.connected) return b.connected - a.connected;
                  return b.signalStrength - a.signalStrength;
                })
              : []
          }
    
          WifiRow {
            required property WifiNetwork modelData
    
            width: wifiPanel.contentWidth
            network: modelData
          }
        }
      }
    
      Popup {
        id: bluetoothPanel
    
        Header {
          width: bluetoothPanel.contentWidth
          title: root.adapter ? root.adapter.name : "no adapter"
          on: root.adapter ? root.adapter.enabled : false
          switchable: root.adapter !== null
          onToggled: root.adapter.enabled = !root.adapter.enabled
        }
    
        Separator {
          width: bluetoothPanel.contentWidth
        }
    
        Text {
          width: bluetoothPanel.contentWidth
          color: root.dim
          font.pixelSize: 13
          visible: root.adapter !== null && root.adapter.enabled
            && root.adapter.devices.values.length === 0
          text: "searching..."
        }
    
        Repeater {
          model: ScriptModel {
            values: root.adapter && root.adapter.enabled
              ? [...root.adapter.devices.values].sort(function (a, b) {
                  if (a.connected !== b.connected) return b.connected - a.connected;
                  const aKnown = a.paired || a.bonded;
                  const bKnown = b.paired || b.bonded;
                  if (aKnown !== bKnown) return bKnown - aKnown;
                  return (a.deviceName || a.address).localeCompare(b.deviceName || b.address);
                })
              : []
          }
    
          BtRow {
            required property BluetoothDevice modelData
    
            width: bluetoothPanel.contentWidth
            device: modelData
          }
        }
      }
    }
  '';

  # Stamped into the QML and into the scripts below, so a running instance can
  # be told apart from the generation it was started with.
  revision = substring 0 12 (hashString "sha256" shellQmlBody);
  shellQml = replaceStrings [ "@revision@" ] [ revision ] shellQmlBody;

  # All panels live in one instance, started lazily by whichever toggle is
  # pressed first. NOTE: it deliberately does not autostart from
  # system.events.onWMLoaded — those commands run sequentially and waybar
  # never returns, so anything ordered after it would never run.
  mkToggle =
    target:
    pkgs.writeShellScriptBin "qs-${target}" ''
      # A leftover instance from an older generation still runs the old QML:
      # the config path is a symlink into the store, so quickshell's file
      # watcher never fires on a rebuild. Retire it before talking to it.
      if [ "$(${quickshell} ipc -c panels prop get shell revision 2>/dev/null)" != "${revision}" ]; then
        ${quickshell} kill -c panels 2>/dev/null
      fi

      ${quickshell} ipc -c panels call ${target} toggle 2>/dev/null && exit 0

      ${daemon}
      for _ in $(seq 1 50); do
        ${quickshell} ipc -c panels call ${target} toggle 2>/dev/null && exit 0
        sleep 0.1
      done

      echo "qs-${target}: panels instance did not come up" >&2
      exit 1
    '';

  audioToggle = mkToggle "audio";
  wifiToggle = mkToggle "wifi";
  bluetoothToggle = mkToggle "bluetooth";
in
{
  options.modules.programs.quickshell = {
    enable = mkEnableOption "quickshell (audio, wifi and bluetooth panels)";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = [
        pkgs.quickshell
        audioToggle
        wifiToggle
        bluetoothToggle
      ];
    }

    # Right-clicking an indicator opens its panel. They are layer-shell
    # surfaces covering the output, so they place themselves.
    (mkIf config.modules.services.waybar.enable {
      system.user.hm.programs.waybar.settings.mainBar = {
        "pulseaudio".on-click-right = "${audioToggle}/bin/qs-audio";
        "network".on-click-right = "${wifiToggle}/bin/qs-wifi";
        "bluetooth".on-click-right = "${bluetoothToggle}/bin/qs-bluetooth";
      };
    })

    {
      system.user.hm.xdg.configFile."quickshell/panels/shell.qml".text = shellQml;
    }
  ]);
}
