pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui

Item {
    id: root

    property var shell: null
    property var manifest: null
    property bool opened: false

    // Change this if your wallpapers live somewhere other than ~/Pictures.
    // Set recursive to true to also pick up images in subfolders.
    property string picturesDir: "$HOME/Pictures"
    property bool recursive: false

    property int columns: 5
    property int gridSpacing: 14
    property int hoveredIndex: -1
    property bool loading: false
    property string statusText: ""

    readonly property color bg: "#0a0a0a"
    readonly property color fg: "#efe6d2"
    readonly property color muted: "#8c8274"
    readonly property color subtle: "#5c564c"
    readonly property color accent: "#efe6d2"

    ListModel { id: imageModel }

    function extensionFilter() {
        // find -iname is case-insensitive per pattern, so list each once.
        var exts = ["png", "jpg", "jpeg", "webp", "bmp", "gif", "tiff"]
        var parts = []
        for (var i = 0; i < exts.length; i++)
            parts.push("-iname '*." + exts[i] + "'")
        return parts.join(" -o ")
    }

    function reload() {
        root.loading = true
        root.statusText = ""
        imageModel.clear()
        listProc.command = ["bash", "-c",
            "dir=\"" + root.picturesDir + "\"; " +
            "depth=" + (root.recursive ? "99" : "1") + "; " +
            "find \"$dir\" -maxdepth \"$depth\" -type f \\( " + extensionFilter() + " \\) 2>/dev/null | sort"
        ]
        listProc.running = true
    }

    function baseName(path) {
        var parts = path.split("/")
        return parts[parts.length - 1]
    }

    function setWallpaper(path) {
        root.statusText = "Applying " + baseName(path) + "…"
        // Omarchy's own CLI is what actually owns the background symlink +
        // swaybg reload. Shelling that out ourselves (as the first version
        // of this plugin did) fought the CLI over that state and silently
        // no-opped on current Omarchy releases. Let the CLI do it.
        Util.execDetached("omarchy theme bg set " + Util.shellQuote(path))
        applyCloseTimer.restart()
    }

    Timer {
        id: applyCloseTimer
        interval: 240
        repeat: false
        onTriggered: root.dismiss()
    }

    Process {
        id: listProc
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                var lines = text.split("\n").filter(function (l) { return l.length > 0 })
                for (var i = 0; i < lines.length; i++)
                    imageModel.append({ path: lines[i] })
                root.loading = false
                if (lines.length === 0)
                    root.statusText = "No images found in " + root.picturesDir
            }
        }
    }

    function open(payloadJson) {
        root.opened = true
        root.reload()
        Qt.callLater(function () { keyCatcher.forceActiveFocus() })
    }

    function close() { root.opened = false }

    function dismiss() {
        root.opened = false
        if (root.shell && typeof root.shell.hide === "function")
            root.shell.hide((root.manifest && root.manifest.id) || "wallpicker.grid")
    }

    function toggle() {
        if (root.opened) root.dismiss()
        else root.open("{}")
    }

    IpcHandler {
        target: "wallpicker"
        function toggle(): void { root.toggle() }
        function open(): void { root.open("{}") }
        function close(): void { root.dismiss() }
        function status(): string { return root.opened ? "open" : "closed" }
    }

    PanelWindow {
        id: panel
        visible: root.opened
        anchors { top: true; bottom: true; left: true; right: true }
        color: "#0a0a0a"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "wallpicker-grid"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Item {
            id: keyCatcher
            anchors.fill: parent
            focus: true
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: function (event) {
                if (event.key === Qt.Key_Escape) {
                    root.dismiss()
                    event.accepted = true
                }
            }

            Rectangle {
                anchors.fill: parent
                color: root.bg
            }

            Column {
                id: header
                width: parent.width
                topPadding: 22
                leftPadding: 28
                rightPadding: 28
                spacing: 4

                Item {
                    width: parent.width - 56
                    height: 28

                    Text {
                        text: "WALLPAPERS"
                        color: root.muted
                        font.pixelSize: 11
                        font.letterSpacing: 3
                        font.weight: Font.Medium
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: root.loading ? "loading…" : (imageModel.count + " images")
                        color: root.subtle
                        font.pixelSize: 11
                        font.letterSpacing: 1
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    visible: root.statusText.length > 0
                    text: root.statusText
                    color: root.muted
                    font.pixelSize: 12
                }
            }

            GridView {
                id: grid
                anchors.top: header.bottom
                anchors.bottom: footer.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 28
                anchors.topMargin: 14
                cellWidth: (width - (root.columns - 1) * root.gridSpacing) / root.columns + root.gridSpacing
                cellHeight: cellWidth * 9 / 16 + root.gridSpacing
                model: imageModel
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    id: cell
                    required property string path
                    required property int index
                    width: grid.cellWidth - root.gridSpacing
                    height: grid.cellHeight - root.gridSpacing

                    Rectangle {
                        anchors.fill: parent
                        radius: root.hoveredIndex === cell.index ? 0 : 10
                        color: "#141410"
                        border.width: root.hoveredIndex === cell.index ? 2 : 0
                        border.color: root.accent
                        clip: true

                        Image {
                            id: thumb
                            anchors.fill: parent
                            anchors.margins: root.hoveredIndex === cell.index ? 2 : 0
                            source: "file://" + cell.path
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            smooth: true

                            Rectangle {
                                visible: thumb.status !== Image.Ready
                                anchors.fill: parent
                                color: "#1b1b16"

                                Text {
                                    anchors.centerIn: parent
                                    text: thumb.status === Image.Error ? "✕" : "…"
                                    color: root.subtle
                                    font.pixelSize: 20
                                }
                            }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 26
                            visible: root.hoveredIndex === cell.index
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#00000000" }
                                GradientStop { position: 1.0; color: "#c0000000" }
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: 6
                                elide: Text.ElideMiddle
                                text: root.baseName(cell.path)
                                color: root.fg
                                font.pixelSize: 11
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.hoveredIndex = cell.index
                        onExited: if (root.hoveredIndex === cell.index) root.hoveredIndex = -1
                        onClicked: root.setWallpaper(cell.path)
                    }
                }
            }

            Item {
                id: footer
                width: parent.width
                height: 44
                anchors.bottom: parent.bottom

                Text {
                    anchors.centerIn: parent
                    text: "Click a wallpaper to apply it · Esc to close"
                    color: root.subtle
                    font.pixelSize: 12
                }
            }
        }
    }
}
