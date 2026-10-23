import QtQuick
import QtTest
import "../../theme" as Lumen
TestCase {
    id: testCase
    name: "LumenSpectrum"
    QtObject {
        id: service
        property int acquisitions: 0
        property int releases: 0
        property bool fail: false
        property var resolvePending: null
        property bool defer: false
        signal event(var message)
        function call(method, request) {
            if (method !== "extensions.call" || request.id !== "nekotune.spectrum") return Promise.reject("wrong target")
            if (request.service === "acquire") {
                ++acquisitions
                if (fail) return Promise.reject("missing")
                if (defer) return new Promise(function(resolve) { service.resolvePending = resolve })
                return Promise.resolve({token: "lease-" + acquisitions, available: true})
            }
            if (request.service === "release") ++releases
            return Promise.resolve({})
        }
    }
    Component { id: controller; Lumen.SpectrumController { serviceApi: service } }
    function init() { service.acquisitions = 0; service.releases = 0; service.fail = false; service.defer = false; service.resolvePending = null }
    function test_framesValidationTimeoutAndRelease() {
        const object = createTemporaryObject(controller, testCase)
        object.active = true
        tryVerify(function() { return object.token !== "" })
        compare(service.acquisitions, 1)
        service.event({event: "extension.other.frame", data: {}})
        compare(object.lastSequence, -1)
        service.event({event: "extension.nekotune.spectrum.frame", data: {version: 1, generation: 2, sequence: 1, bands: Array(48).fill(.5)}})
        compare(object.bands[0], .5)
        service.event({event: "extension.nekotune.spectrum.frame", data: {version: 1, generation: 1, sequence: 2, bands: Array(48).fill(1)}})
        compare(object.bands[0], .5)
        service.event({event: "extension.nekotune.spectrum.frame", data: {version: 1, generation: 2, sequence: 2, bands: Array(48).fill(NaN)}})
        compare(object.bands[0], .5)
        tryCompare(object, "lastFrame", 0, 1000)
        compare(object.bands[0], 0)
        object.active = false
        tryCompare(service, "releases", 1)
        compare(object.token, "")
    }
    function test_missingExtensionAndLateAcquire() {
        const object = createTemporaryObject(controller, testCase)
        service.fail = true; object.active = true
        tryCompare(object, "reason", "extension_unavailable")
        object.active = false; service.fail = false; service.defer = true; object.active = true
        tryVerify(function() { return service.resolvePending !== null })
        object.active = false
        service.resolvePending({token: "late", available: true})
        tryCompare(service, "releases", 1)
        compare(object.token, "")
        compare(object.bands[0], 0)
    }
    function test_statusAndReconnect() {
        const object = createTemporaryObject(controller, testCase, {active: true})
        tryVerify(function() { return object.token !== "" })
        service.event({event: "extension.nekotune.spectrum.status", data: {available: false, analyzing: false, reason: "playback_backend_unsupported"}})
        compare(object.reason, "playback_backend_unsupported")
        object.active = false; object.active = true
        tryCompare(service, "acquisitions", 2)
        tryVerify(function() { return object.token !== "" })
        compare(object.lastSequence, -1)
    }
}
