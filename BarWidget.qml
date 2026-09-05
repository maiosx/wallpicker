import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
    id: root
    moduleName: "wallpicker.grid"
    implicitWidth: glyph.implicitWidth
    implicitHeight: glyph.implicitHeight

    function toggleWallpicker() {
        if (!root.bar) return
        if (typeof root.bar.run === "function") {
            root.bar.run("omarchy-shell shell toggle wallpicker.grid")
            return
        }
        if (root.bar.shell && typeof root.bar.shell.toggle === "function")
            root.bar.shell.toggle("wallpicker.grid", "{}")
    }

    BarIconButton {
        id: glyph
        anchors.fill: parent
        bar: root.bar
        text: "\u25A6"
        tooltipText: "Wallpapers"
        onPressed: function (mouseButton) {
            root.toggleWallpicker()
        }
    }
}
