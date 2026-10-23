import QtQuick
import NekoTune 1.0
QtObject {
    id: root
    property bool active: false
    property var serviceApi: extensionApi
    property var bands: Array(48).fill(0)
    property string reason: ""
    property string token: ""
    property bool requesting: false
    property int requestEpoch: 0
    property real lastFrame: 0
    property real lastSequence: -1
    property real streamGeneration: -1
    property bool disposed: false
    property ExtensionApi extensionApi: ExtensionApi {}
    function clear() { bands = Array(48).fill(0); lastFrame = 0 }
    function call(service, params) { return serviceApi.call("extensions.call", {id: "nekotune.spectrum", service: service, params: params || {}}) }
    function release() {
        ++requestEpoch
        requesting = false
        const oldToken = token
        token = ""
        clear()
        if (oldToken) call("release", {token: oldToken}).catch(function() {})
    }
    function acquire() {
        if (!active || disposed || token || requesting) return
        requesting = true
        const epoch = ++requestEpoch
        call("acquire", {}).then(function(response) {
            if (disposed || epoch !== requestEpoch || !active) {
                if (response.token) call("release", {token: response.token}).catch(function() {})
                return
            }
            requesting = false
            token = response.token || ""
            reason = response.available ? "" : response.reason || "unavailable"
            lastSequence = -1
            streamGeneration = -1
        }, function() {
            if (disposed || epoch !== requestEpoch) return
            requesting = false
            reason = "extension_unavailable"
        })
    }
    function receive(message) {
        if (!active || !token) return
        const data = message.data || {}
        if (message.event === "extension.nekotune.spectrum.status") {
            reason = data.available ? "" : data.reason || "unavailable"
            if (!data.analyzing) clear()
            return
        }
        if (message.event !== "extension.nekotune.spectrum.frame" || data.version !== 1
            || !data.bands || data.bands.length !== 48
            || !Number.isFinite(data.sequence) || data.sequence <= lastSequence
            || !Number.isFinite(data.generation)) return
        const incoming = []
        for (let i = 0; i < 48; ++i) {
            const value = data.bands[i]
            if (!Number.isFinite(value) || value < 0 || value > 1) return
            incoming.push(value)
        }
        if (streamGeneration >= 0 && data.generation < streamGeneration) return
        lastSequence = data.sequence
        streamGeneration = data.generation
        bands = incoming
        lastFrame = Date.now()
        reason = ""
    }
    onActiveChanged: { if (active) acquire(); else release() }
    property Connections events: Connections {
        target: root.serviceApi
        function onEvent(message) { root.receive(message) }
    }
    property Timer renewal: Timer {
        interval: 5000; repeat: true; running: root.active
        onTriggered: {
            if (!root.token) { root.acquire(); return }
            const token = root.token
            const epoch = root.requestEpoch
            root.call("renew", {token: token}).catch(function() {
                if (root.disposed || epoch !== root.requestEpoch) return
                root.release()
                root.acquire()
            })
        }
    }
    property Timer freshness: Timer {
        interval: 100; repeat: true; running: root.active && root.lastFrame > 0
        onTriggered: if (Date.now() - root.lastFrame > 500) root.clear()
    }
    Component.onCompleted: acquire()
    Component.onDestruction: { disposed = true; release() }
}
