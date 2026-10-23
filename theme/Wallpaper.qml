pragma ComponentBehavior: Bound
import QtQuick
import NekoTune 1.0
import "qrc:/qml/components" as Builtin

Item {
    id: root
    objectName: "lumenWallpaper"
    anchors.fill: parent
    clip: true
    ExtensionApi { id: api }
    readonly property var wallpaper: api.wallpaper
    readonly property var preferences: wallpaper ? wallpaper.preferences : ({})
    readonly property bool compact: width < 860 || height < 540
    readonly property bool stacked: width < 640 || height > width * 1.2
    readonly property real intensity: Math.max(0, Math.min(1, preferences.intensity ?? 0.35))
    readonly property bool motion: visible && wallpaper && wallpaper.updating && wallpaper.playing
        && !api.theme.reducedMotion && intensity > 0
    readonly property real dpr: wallpaper ? wallpaper.screen.devicePixelRatio || 1 : 1
    readonly property color cyan: "#8ADFF1"
    readonly property real lyricSize: Math.round(Math.max(22, Math.min(44, width / 46)))
    function timeLabel(value) {
        const seconds = Math.floor(Math.max(0, value || 0) / 1000)
        return Math.floor(seconds / 60) + ":" + String(seconds % 60).padStart(2, "0")
    }
    function t(zh, en) { return i18n.language.indexOf("zh") === 0 ? zh : en }
    SpectrumController { id: spectrum; objectName: "lumenSpectrumController"; active: root.motion }

    Column {
        id: lyricsGroup
        objectName: "lumenLyrics"
        width: Math.min(root.width - 48, root.width * (root.stacked ? .9 : .8), 1400)
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(24, Math.min(root.height * .45 - height / 2, card.y - height - 28))
        spacing: root.compact ? 8 : 12
        visible: Boolean(root.preferences.lyrics)
        Text {
            objectName: "lumenPreviousLyric"
            width: parent.width
            text: {
                const previous = lyricView.lines[lyricView.activeIndex - 1]
                return previous ? String(previous.text || (previous.words || []).map(function(word) { return word.text }).join("")) : ""
            }
            height: Math.max(root.lyricSize * 1.2, implicitHeight)
            textFormat: Text.PlainText
            font.family: api.theme.fontFamily
            font.pixelSize: root.lyricSize * .8
            color: "#99E8EDF7"
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
            style: Text.Outline; styleColor: "#40202939"
        }
        Builtin.CompactLyrics {
            id: lyricView
            objectName: "lumenCurrentLyrics"
            width: parent.width
            height: implicitHeight
            song: root.wallpaper ? root.wallpaper.song : ({})
            lyrics: root.wallpaper ? root.wallpaper.lyrics : ({})
            translator: i18n
            position: root.wallpaper ? root.wallpaper.position : 0
            playbackRate: root.wallpaper ? root.wallpaper.playbackRate : 1
            playing: root.wallpaper ? root.wallpaper.playing : false
            connected: root.wallpaper ? root.wallpaper.connected : false
            running: root.wallpaper && root.wallpaper.updating && visible
            reducedMotion: api.theme.reducedMotion
            animateLineChanges: root.intensity > 0
            showNext: Boolean(root.preferences.nextLine)
            updateInterval: root.preferences.updateHz === 60 ? 16 : 33
            wrap: true
            pixelSize: root.lyricSize
            previewPixelSize: root.lyricSize * .8
            textLineHeight: 1.15; lineSpacing: 6
            activeColor: "#FFF8FCFF"
            inactiveColor: "#D6ECF0F8"
            previewColor: "#99E8EDF7"
            outlined: true
        }
    }

    Rectangle {
        id: card
        objectName: "lumenMusicCard"
        width: Math.max(0, root.stacked ? root.width - 32 : Math.min(root.width - 48, Math.max(640, root.width * .64), 1400))
        height: root.stacked ? Math.min(270, root.height * .34) : Math.max(104, Math.min(172, root.height * .155))
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(16, root.height * .85 - height)
        radius: 20
        color: "#A32A2D3C"
        border.width: 1
        border.color: "#627B8AA6"
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 24; rightMargin: 24; topMargin: 1 }
            height: 1; color: "#446FD9ED"
        }
        Item {
            id: coverArea
            width: root.stacked ? 88 : parent.height - 20
            height: width
            x: 10; y: 10
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 1.45; height: width; radius: width / 2
                y: -20; color: "transparent"
                border.color: "#758ADFF1"; border.width: 1
                opacity: .55 + breath * root.intensity * .35
                property real breath: 0
                SequentialAnimation on breath {
                    running: root.motion; loops: Animation.Infinite
                    NumberAnimation { from: 0; to: 1; duration: 3000; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1; to: 0; duration: 3000; easing.type: Easing.InOutSine }
                }
            }
            Rectangle {
                anchors.fill: parent; anchors.margins: -4
                radius: 9; color: "#286ECDE3"; border.color: "#3D96DFEF"
            }
            Builtin.AlbumArt {
                anchors.fill: parent
                minimumDimension: 0; maxDimension: 180; decodeScale: root.dpr
                hasSong: root.wallpaper ? root.wallpaper.hasSong : false
                coverUrl: root.wallpaper ? root.wallpaper.song.cover_url || "" : ""
                playbackState: "paused"
                lavenderColor: root.cyan; roseColor: root.cyan
            }
        }
        Column {
            id: info
            objectName: "lumenTrackInfo"
            x: coverArea.x + coverArea.width + (root.compact ? 14 : 24)
            y: root.stacked ? 20 : (card.height - height) / 2
            width: Math.max(0, (root.stacked ? card.width - 16 : frequency.x - 26) - x)
            spacing: root.compact ? 6 : 10
            Text {
                objectName: "lumenSongTitle"
                width: parent.width
                text: root.wallpaper && root.wallpaper.hasSong
                    ? root.wallpaper.song.title || root.wallpaper.song.file_name || root.t("未命名", "Untitled")
                    : root.t("等待音乐", "Waiting for music")
                font.family: api.theme.fontFamily; font.pixelSize: root.compact ? 16 : 22
                color: "#FFF4F5FC"; textFormat: Text.PlainText; elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: root.wallpaper ? [root.wallpaper.song.artist || "", root.wallpaper.song.album || ""].filter(Boolean).join(" · ") : ""
                font.family: api.theme.fontFamily; font.pixelSize: root.compact ? 11 : 14
                color: "#ABB8C9E1"; textFormat: Text.PlainText; elide: Text.ElideRight
            }
            Rectangle {
                width: parent.width; height: 3; radius: 1.5; color: "#506D7890"
                Rectangle {
                    height: parent.height; radius: parent.radius; color: root.cyan
                    width: parent.width * Math.max(0, Math.min(1, root.wallpaper && root.wallpaper.duration > 0
                        ? root.wallpaper.position / root.wallpaper.duration : 0))
                }
            }
            Text {
                text: root.timeLabel(root.wallpaper ? root.wallpaper.position : 0) + " / " + root.timeLabel(root.wallpaper ? root.wallpaper.duration : 0)
                font.family: api.theme.fontFamilyMonospace; font.pixelSize: root.compact ? 10 : 12
                color: "#A2BACCE5"; textFormat: Text.PlainText
            }
        }
        Item {
            id: frequency
            objectName: "lumenSpectrum"
            width: root.stacked ? card.width - 40 : card.width * .33
            height: root.stacked ? Math.max(28, card.height - coverArea.height - 42) : card.height * .7
            x: root.stacked ? 20 : card.width - width - 26
            y: root.stacked ? coverArea.height + 24 : (card.height - height) / 2
            Row {
                anchors.fill: parent
                Repeater {
                    model: 48
                    delegate: Item {
                        id: bar
                        required property int index
                        width: frequency.width / 48; height: frequency.height
                        readonly property real level: spectrum.bands[index] || 0
                        Rectangle {
                            x: 1; width: Math.max(1, parent.width - 2)
                            height: Math.max(1, (frequency.height - 18) * bar.level)
                            y: frequency.height - 18 - height
                            gradient: Gradient {
                                GradientStop { position: 0; color: "#B2EFF9" }
                                GradientStop { position: 1; color: "#5799B8" }
                            }
                            opacity: root.motion ? .9 : .2
                            Behavior on height { enabled: root.motion; NumberAnimation { duration: 65 } }
                        }
                        Rectangle {
                            x: 1; width: Math.max(1, parent.width - 2); y: frequency.height - 16
                            height: Math.min(14, 14 * bar.level); color: "#7BC6DE"; opacity: .12
                        }
                    }
                }
            }
            Text {
                objectName: "lumenSpectrumStatus"
                anchors.centerIn: parent
                width: parent.width
                visible: spectrum.reason !== "" && root.motion
                text: spectrum.reason === "playback_backend_unsupported"
                    ? root.t("当前播放后端不支持频谱", "Spectrum unavailable with this backend")
                    : spectrum.reason === "audio_output_unavailable" ? root.t("音频设备不可用", "Audio output unavailable")
                    : spectrum.reason === "host_pcm_unsupported" || spectrum.reason === "pcm_unavailable"
                        ? root.t("需要升级支持 PCM 的播放器", "Update NekoTune for PCM support")
                    : root.t("启用频谱扩展以显示动态频谱", "Enable Spectrum to visualize music")
                font.family: api.theme.fontFamily; font.pixelSize: 11
                color: "#ABB8C9E1"; textFormat: Text.PlainText
                wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
