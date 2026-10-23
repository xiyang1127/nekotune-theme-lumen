import QtQuick
// Standalone controller-test double; host integration uses the real resource module.
QtObject {
    signal event(var message)
    function call(method, params) { return Promise.reject("No host") }
}
