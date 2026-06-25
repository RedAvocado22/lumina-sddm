import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects
import SddmComponents 2.0

Item {
    id: root

    FontLoader { id: fontRubik;   source: Qt.resolvedUrl("assets/fonts/Rubik.ttf") }
    FontLoader { id: fontSymbols; source: Qt.resolvedUrl("assets/fonts/MaterialSymbolsRounded.ttf") }


    // ====== PALETTE ======
    QtObject {
        id: pal
        property color primary:        Qt.rgba(0.36, 0.72, 0.94, 1)
        property color primaryBright:  Qt.rgba(0.49, 0.79, 0.96, 1)
        property color primaryDim:     Qt.rgba(0.26, 0.60, 0.83, 1)
        property color onPrimary:      Qt.rgba(0.10, 0.14, 0.18, 1)
        property color surface0:       Qt.rgba(0.068, 0.072, 0.090, 1)
        property color surface1:       Qt.rgba(0.110, 0.116, 0.140, 1)
        property color surface2:       Qt.rgba(0.155, 0.163, 0.192, 1)
        property color surface3:       Qt.rgba(0.205, 0.215, 0.252, 1)
        property color onSurface:      Qt.rgba(0.937, 0.940, 0.945, 1)
        property color onSurfaceDim:   Qt.rgba(0.720, 0.730, 0.760, 1)
        property color onSurfaceFaint: Qt.rgba(0.480, 0.500, 0.540, 1)
        property color error:          Qt.rgba(0.860, 0.373, 0.373, 1)
        property color success:        Qt.rgba(0.369, 0.859, 0.620, 1)
        property real  scrimK:         0.35
    }

    // ====== COLOR ENGINE ======
    function _srgbToLinear(c) {
        c /= 255.0
        return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)
    }
    function _rgbToOklch(r, g, b) {
        var lr = _srgbToLinear(r), lg = _srgbToLinear(g), lb = _srgbToLinear(b)
        var l  = 0.4122214708*lr + 0.5363325363*lg + 0.0514459929*lb
        var m  = 0.2119034982*lr + 0.6806995451*lg + 0.1073969566*lb
        var s  = 0.0883024619*lr + 0.2817188376*lg + 0.6299787005*lb
        var l_ = Math.cbrt(l), m_ = Math.cbrt(m), s_ = Math.cbrt(s)
        var L  = 0.2104542553*l_ + 0.7936177850*m_ - 0.0040720468*s_
        var a  = 1.9779984951*l_ - 2.4285922050*m_ + 0.4505937099*s_
        var bb = 0.0259040371*l_ + 0.7827717662*m_ - 0.8086757660*s_
        var C  = Math.sqrt(a*a + bb*bb)
        var h  = Math.atan2(bb, a) * 180.0 / Math.PI
        if (h < 0) h += 360.0
        return { L:L, C:C, h:h }
    }
    function _oklchToQt(L, C, h) {
        var a  = C * Math.cos(h * Math.PI / 180.0)
        var b  = C * Math.sin(h * Math.PI / 180.0)
        var l_ = L + 0.3963377774*a + 0.2158037573*b
        var m_ = L - 0.1055613458*a - 0.0638541728*b
        var s_ = L - 0.0894841775*a - 1.2914855480*b
        var l3=l_*l_*l_, m3=m_*m_*m_, s3=s_*s_*s_
        var lr = +4.0767416621*l3 - 3.3077115913*m3 + 0.2309699292*s3
        var lg = -1.2684380046*l3 + 2.6097574011*m3 - 0.3413193965*s3
        var lb = -0.0041960863*l3 - 0.7034186147*m3 + 1.7076147010*s3
        function s2(c) {
            if (c <= 0) return 0; if (c >= 1) return 1
            return c <= 0.0031308 ? 12.92*c : 1.055*Math.pow(c, 1/2.4) - 0.055
        }
        return Qt.rgba(s2(lr), s2(lg), s2(lb), 1.0)
    }
    function _buildPalette(hDeg, cSeed, bgL) {
        var Cp = Math.max(0.045, Math.min(0.155, cSeed))
        var Cs = Cp*0.42, Co = Cp*0.30
        pal.primary        = _oklchToQt(0.815, Cp,               hDeg)
        pal.primaryBright  = _oklchToQt(0.880, Cp*0.95,          hDeg)
        pal.primaryDim     = _oklchToQt(0.700, Cp,               hDeg)
        pal.onPrimary      = _oklchToQt(0.205, Math.min(Cp,.05), hDeg)
        pal.surface0       = _oklchToQt(0.135, Cs*0.7,           hDeg)
        pal.surface1       = _oklchToQt(0.190, Cs,               hDeg)
        pal.surface2       = _oklchToQt(0.235, Cs,               hDeg)
        pal.surface3       = _oklchToQt(0.285, Cs,               hDeg)
        pal.onSurface      = _oklchToQt(0.945, Co,               hDeg)
        pal.onSurfaceDim   = _oklchToQt(0.760, Co*1.4,           hDeg)
        pal.onSurfaceFaint = _oklchToQt(0.580, Co*1.4,           hDeg)
        pal.success        = _oklchToQt(0.800, Cp,               hDeg)
        if (bgL !== undefined)
            pal.scrimK = Math.max(0, Math.min(1, (bgL-0.30)/0.45))
    }

    // ====== STATE ======
    property string authState:          "idle"
    property bool   showPw:             false
    property bool   capsOn:             keyboard.capsLock
    property int    currentSession:     0
    property string currentSessionName: "Hyprland"
    property string currentUser:        ""
    property string brandLabel:         "lumina"
    property string hintText:           ""
    property bool   hour24:             false

    // power confirm: null | { icon, label, action, danger }
    property var    powerConfirm:       null

    // battery
    property int  batteryLevel:    -1
    property bool batteryCharging: false

    // network / bluetooth
    property string wifiIface:     ""
    property bool   wifiRadioOn:   true
    property bool   wifiConnected: false
    property bool   btRadioOn:     true

    function _readFile(path) {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + path, false)
        try { xhr.send() } catch(e) { return "" }
        return (xhr.status === 200 || xhr.status === 0) ? xhr.responseText.trim() : ""
    }
    function _updateBattery() {
        var paths = ["/BAT0", "/BAT1", "/BAT2"]
        for (var i = 0; i < paths.length; i++) {
            var base = "/sys/class/power_supply" + paths[i]
            var cap = _readFile(base + "/capacity")
            if (cap !== "") {
                batteryLevel    = parseInt(cap)
                batteryCharging = (_readFile(base + "/status") === "Charging")
                return
            }
        }
        batteryLevel = -1
    }
    function _rfkillOn(type) {
        for (var i = 0; i < 8; i++) {
            var base = "/sys/class/rfkill/rfkill" + i
            if (_readFile(base + "/type") === type)
                return _readFile(base + "/state") === "1"
        }
        return true
    }
    function _detectWifiIface() {
        var candidates = ["wlp4s0", "wlan0", "wlo1", "wlp2s0", "wlp3s0", "wlp1s0", "wlp5s0"]
        for (var i = 0; i < candidates.length; i++) {
            if (_readFile("/sys/class/net/" + candidates[i] + "/operstate") !== "")
                return candidates[i]
        }
        return ""
    }
    function _updateNetwork() {
        wifiRadioOn = _rfkillOn("wlan")
        if (wifiIface === "") wifiIface = _detectWifiIface()
        wifiConnected = wifiRadioOn && wifiIface !== ""
            && _readFile("/sys/class/net/" + wifiIface + "/operstate") === "up"
    }
    function _updateBluetooth() {
        btRadioOn = _rfkillOn("bluetooth")
    }

    onCurrentSessionChanged: {
        if (sessionModel.count > 0)
            currentSessionName = sessionModel.data(sessionModel.index(currentSession, 0), Qt.DisplayRole) || "Hyprland"
    }

    Component.onCompleted: {
        if (sessionModel.lastIndex >= 0) currentSession = sessionModel.lastIndex
        currentSessionName = sessionModel.count > 0
            ? (sessionModel.data(sessionModel.index(currentSession, 0), Qt.DisplayRole) || "Hyprland")
            : "Hyprland"

        if (userModel.lastUser && userModel.lastUser !== "")
            currentUser = userModel.lastUser
        else {
            for (var i = 0; i < userModel.count; i++) {
                var n = userModel.data(userModel.index(i, 0), Qt.DisplayRole)
                if (n && n !== "") { currentUser = n; break }
            }
        }
        if (!currentUser || currentUser === "") {
            if (config.user && config.user !== "") currentUser = config.user
            else currentUser = "user"
        }
        if (config.label && config.label !== "") brandLabel = config.label
        if (config.hint  && config.hint  !== "") hintText  = config.hint
        hour24 = (config.hour24 === "true")
        _updateBattery()
        _updateNetwork()
        _updateBluetooth()
        root.requestActivate()
    }

    Timer {
        interval: 60000; running: true; repeat: true
        onTriggered: { _updateBattery(); _updateNetwork(); _updateBluetooth() }
    }

    property string greeting: {
        var h = new Date().getHours()
        return h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening"
    }

    Timer {
        id: clockTimer; interval: 1000; running: true; repeat: true
        property var now: new Date()
        onTriggered: now = new Date()
    }
    Timer {
        id: errorTimer; interval: 620
        onTriggered: { authState = "idle"; passwordField.text = "" }
    }
    Connections {
        target: sddm
        function onLoginFailed()    { authState = "error";   errorTimer.restart() }
        function onLoginSucceeded() { authState = "success" }
    }
    function doLogin() {
        if (authState === "checking" || authState === "success") return
        if (!passwordField.text) { authState = "error"; errorTimer.restart(); return }
        authState = "checking"
        sddm.login(currentUser, passwordField.text, currentSession)
    }

    // ====== BACKGROUND LAYER (z:0) ======
    Item {
        id: bgLayer
        anchors.fill: parent
        z: 0

        Image {
            id: wallpaperImg
            anchors.fill: parent
            source: (config.background && config.background !== "") ? "file://" + config.background : ""
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: true
            onStatusChanged: {
                if (status === Image.Ready) {
                    colorCanvas.wallUrl = source.toString()
                    colorCanvas.loadImage(source.toString())
                }
            }
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0;  color: Qt.rgba(0,0,0, 0.38 + 0.32*pal.scrimK) }
                GradientStop { position: 0.28; color: Qt.rgba(0,0,0, 0.06 + 0.22*pal.scrimK) }
                GradientStop { position: 0.62; color: Qt.rgba(0,0,0, 0.12 + 0.26*pal.scrimK) }
                GradientStop { position: 1.0;  color: Qt.rgba(0,0,0, 0.52 + 0.32*pal.scrimK) }
            }
        }
    }

    // Canvas for color extraction (hidden)
    Canvas {
        id: colorCanvas
        width: 96; height: 96; visible: false; z: -1
        property string wallUrl: ""
        onImageLoaded: requestPaint()
        onPaint: {
            if (!wallUrl || !isImageLoaded(wallUrl)) return
            var ctx = getContext("2d")
            ctx.drawImage(wallUrl, 0, 0, 96, 96)
            var px = ctx.getImageData(0, 0, 96, 96).data
            var sx=0, sy=0, wsum=0, cAcc=0, cw=0, lSum=0, lN=0
            for (var i = 0; i < px.length; i += 4) {
                if (px[i+3] < 128) continue
                var okl = _rgbToOklch(px[i], px[i+1], px[i+2])
                lSum += okl.L; lN++
                var litW = Math.max(0, 1 - Math.abs(okl.L-0.55)*1.6)
                var w = okl.C*okl.C*litW; if (w <= 0) continue
                var rad = okl.h*Math.PI/180
                sx += Math.cos(rad)*w; sy += Math.sin(rad)*w
                wsum += w; cAcc += okl.C*w; cw += w
            }
            if (wsum < 1e-6) { _buildPalette(255, 0.03, lN ? lSum/lN : 0.3) }
            else {
                var h = Math.atan2(sy, sx)*180/Math.PI; if (h < 0) h += 360
                _buildPalette(h, (cAcc/cw)*1.35, lN ? lSum/lN : 0.3)
            }
        }
    }

    // ====== STATUS PILLS (top-right, z:6) ======
    Row {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 24
        anchors.rightMargin: 26
        spacing: 8
        z: 6

        // wifi
        Rectangle {
            height: 34; radius: 17
            color: Qt.rgba(pal.surface1.r, pal.surface1.g, pal.surface1.b, 0.70)
            border.color: Qt.rgba(1,1,1, 0.10); border.width: 1
            width: pillWifi.implicitWidth + 24
            Row {
                id: pillWifi; anchors.centerIn: parent; spacing: 6
                Text {
                    text: !wifiRadioOn ? "wifi_off" : wifiConnected ? "wifi" : "wifi_off"
                    font.family: "Material Symbols Rounded"; font.pixelSize: 16
                    color: pal.onSurfaceDim; anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: !wifiRadioOn ? "Off" : wifiConnected ? "Connected" : "No network"
                    font.family: "Rubik"; font.pixelSize: 15; font.weight: Font.Bold
                    color: pal.onSurfaceDim; anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // bluetooth
        Rectangle {
            height: 34; radius: 17
            color: Qt.rgba(pal.surface1.r, pal.surface1.g, pal.surface1.b, 0.70)
            border.color: Qt.rgba(1,1,1, 0.10); border.width: 1
            width: pillBt.implicitWidth + 24
            Row {
                id: pillBt; anchors.centerIn: parent; spacing: 6
                Text {
                    text: btRadioOn ? "bluetooth" : "bluetooth_disabled"
                    font.family: "Material Symbols Rounded"; font.pixelSize: 16
                    color: pal.onSurfaceDim; anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: btRadioOn ? "On" : "Off"
                    font.family: "Rubik"; font.pixelSize: 15; font.weight: Font.Bold
                    color: pal.onSurfaceDim; anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // battery
        Rectangle {
            visible: batteryLevel >= 0
            height: 34; radius: 17
            color: Qt.rgba(pal.surface1.r, pal.surface1.g, pal.surface1.b, 0.70)
            border.color: Qt.rgba(1,1,1, 0.10); border.width: 1
            width: pillBat.implicitWidth + 24
            Row {
                id: pillBat; anchors.centerIn: parent; spacing: 6
                Text {
                    text: batteryCharging ? "battery_charging_full"
                        : batteryLevel > 80 ? "battery_full"
                        : batteryLevel > 60 ? "battery_5_bar"
                        : batteryLevel > 40 ? "battery_3_bar"
                        : batteryLevel > 20 ? "battery_2_bar"
                        : "battery_1_bar"
                    font.family: "Material Symbols Rounded"; font.pixelSize: 16
                    color: batteryLevel <= 20 ? pal.error : pal.onSurfaceDim
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: batteryLevel + "%"
                    font.family: "Rubik"; font.pixelSize: 15; font.weight: Font.Bold
                    color: batteryLevel <= 20 ? pal.error : pal.onSurfaceDim
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // keyboard
        Rectangle {
            height: 34; radius: 17
            color: Qt.rgba(pal.surface1.r, pal.surface1.g, pal.surface1.b, 0.70)
            border.color: Qt.rgba(1,1,1, 0.10); border.width: 1
            width: pillKbd.implicitWidth + 24
            Row {
                id: pillKbd; anchors.centerIn: parent; spacing: 6
                Text { text: "keyboard"; font.family: "Material Symbols Rounded"; font.pixelSize: 16; color: pal.onSurfaceDim; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: (keyboard.layouts.length > keyboard.currentLayout && keyboard.layouts[keyboard.currentLayout])
                        ? keyboard.layouts[keyboard.currentLayout].shortName.toUpperCase() : "??"
                    font.family: "Rubik"; font.pixelSize: 15; font.weight: Font.Bold; color: pal.onSurfaceDim; anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // ====== SPLIT LAYOUT (z:4) ======
    Item {
        anchors.fill: parent
        z: 4

        // ---- LEFT PANE ----
        Item {
            id: leftPane
            x: 0; y: 0
            width: parent.width * 0.55
            height: parent.height

            // subtle frosted glass — helps readability on bright wallpapers
            ShaderEffectSource {
                id: leftBlurSrc
                anchors.fill: parent
                sourceItem: bgLayer
                sourceRect: Qt.rect(0, 0, leftPane.width, leftPane.height)
                hideSource: false
                live: true
            }
            FastBlur {
                anchors.fill: parent
                source: leftBlurSrc
                radius: 24
                transparentBorder: false
            }
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(pal.surface0.r, pal.surface0.g, pal.surface0.b, 0.42)
            }

            Column {
                anchors.centerIn: parent
                spacing: 26

                // brand
                Row {
                    spacing: 12
                    Canvas {
                        id: starMark; width: 26; height: 26
                        property color c: pal.primary
                        onCChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, 26, 26)
                            ctx.strokeStyle = Qt.rgba(c.r, c.g, c.b, 1)
                            ctx.lineWidth = 1.5; ctx.lineJoin = "round"
                            var p = [[50,5],[52.3,44.5],[66,34],[55.5,47.7],[95,50],[55.5,52.3],
                                     [66,66],[52.3,55.5],[50,95],[47.7,55.5],[34,66],[44.5,52.3],
                                     [5,50],[44.5,47.7],[34,34],[47.7,44.5]]
                            ctx.beginPath(); ctx.moveTo(p[0][0]*.26, p[0][1]*.26)
                            for (var i=1; i<p.length; i++) ctx.lineTo(p[i][0]*.26, p[i][1]*.26)
                            ctx.closePath(); ctx.stroke()
                        }
                        RotationAnimation on rotation { from:0; to:360; duration:60000; loops:Animation.Infinite; running:true }
                    }
                    Text {
                        text: brandLabel
                        color: pal.onSurfaceDim
                        font.family: "Rubik"; font.pixelSize: 19; font.weight: Font.Medium; font.letterSpacing: 1.5
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // clock
                Column {
                    spacing: 4
                    Row {
                        id: clockRow
                        spacing: 0
                        property int sz: Math.min(168, Math.round(root.width * 0.11))

                        Text {
                            color: pal.onSurface
                            font.family: "Rubik"; font.pixelSize: clockRow.sz; font.weight: Font.Light
                            style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.40)
                            text: {
                                var h = clockTimer.now.getHours()
                                if (!hour24) { h = h%12; if (h===0) h=12 }
                                return String(h)
                            }
                        }
                        Text {
                            color: Qt.rgba(pal.onSurface.r, pal.onSurface.g, pal.onSurface.b, 0.35)
                            font.family: "Rubik"; font.pixelSize: clockRow.sz; font.weight: Font.Light
                            text: ":"
                            SequentialAnimation on opacity {
                                running: true; loops: Animation.Infinite
                                NumberAnimation { to: 0.1; duration: 1000 }
                                NumberAnimation { to: 1.0; duration: 1000 }
                            }
                        }
                        Text {
                            color: pal.onSurface
                            font.family: "Rubik"; font.pixelSize: clockRow.sz; font.weight: Font.Light
                            style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.40)
                            text: String(clockTimer.now.getMinutes()).padStart(2, "0")
                        }
                        Text {
                            visible: !hour24
                            text: clockTimer.now.getHours() >= 12 ? "PM" : "AM"
                            color: pal.primaryBright
                            font.family: "Rubik"; font.pixelSize: Math.round(clockRow.sz * 0.36); font.weight: Font.Bold; font.letterSpacing: 1.5
                            anchors.verticalCenter: parent.verticalCenter
                            leftPadding: 8
                            style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.45)
                        }
                    }
                    Text {
                        text: clockTimer.now.toLocaleDateString(Qt.locale("en_US"), "dddd, MMMM d")
                        color: pal.onSurface
                        font.family: "Rubik"; font.pixelSize: 22; font.weight: Font.Bold
                        style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.45)
                    }
                }

                // meta pills
                Row {
                    spacing: 10
                    Rectangle {
                        height: 38; radius: 19
                        color: Qt.rgba(pal.surface1.r, pal.surface1.g, pal.surface1.b, 0.55)
                        border.color: Qt.rgba(1,1,1, 0.08); border.width: 1
                        width: metaHost.implicitWidth + 28
                        Row {
                            id: metaHost; anchors.centerIn: parent; spacing: 7
                            Text { text: "computer"; font.family: "Material Symbols Rounded"; font.pixelSize: 17; color: pal.onSurfaceDim; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: sddm.hostName || "localhost"; font.family: "Rubik"; font.pixelSize: 15; font.weight: Font.Bold; color: pal.onSurfaceDim; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }
                    Rectangle {
                        height: 38; radius: 19
                        color: Qt.rgba(pal.surface1.r, pal.surface1.g, pal.surface1.b, 0.55)
                        border.color: Qt.rgba(1,1,1, 0.08); border.width: 1
                        width: metaLock.implicitWidth + 28
                        Row {
                            id: metaLock; anchors.centerIn: parent; spacing: 7
                            Text { text: "lock"; font.family: "Material Symbols Rounded"; font.pixelSize: 17; color: pal.onSurfaceDim; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "locked"; font.family: "Rubik"; font.pixelSize: 15; font.weight: Font.Bold; color: pal.onSurfaceDim; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }
                }
            }
        }

        // ---- RIGHT PANE: frosted glass ----
        Item {
            id: rightPane
            x: parent.width * 0.55
            y: 0
            width: parent.width * 0.45
            height: parent.height

            // Capture wallpaper area for blur
            ShaderEffectSource {
                id: blurSrc
                anchors.fill: parent
                sourceItem: bgLayer
                sourceRect: Qt.rect(rightPane.x, rightPane.y, rightPane.width, rightPane.height)
                hideSource: false
                live: true
            }

            // Blur
            FastBlur {
                anchors.fill: parent
                source: blurSrc
                radius: 48
                transparentBorder: false
            }

            // Dark tint
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(pal.surface0.r, pal.surface0.g, pal.surface0.b, 0.55)
            }

            // Left border line
            Rectangle {
                anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.left: parent.left
                width: 1
                color: Qt.rgba(1,1,1, 0.08)
            }

            // ---- LOGIN CONTENT ----
            Column {
                anchors.centerIn: parent
                spacing: 20
                width: Math.min(400, Math.round(rightPane.width * 0.86))

                // avatar — canvas-based circular clip with multi-layer glow
                Item {
                    width: 134; height: 134
                    anchors.horizontalCenter: parent.horizontalCenter

                    // glow layers (outermost → innermost)
                    Rectangle {
                        anchors.centerIn: parent; width: 134; height: 134; radius: 67
                        color: Qt.rgba(pal.primary.r, pal.primary.g, pal.primary.b, 0.07)
                    }
                    Rectangle {
                        anchors.centerIn: parent; width: 118; height: 118; radius: 59
                        color: Qt.rgba(pal.primary.r, pal.primary.g, pal.primary.b, 0.11)
                    }
                    Rectangle {
                        anchors.centerIn: parent; width: 104; height: 104; radius: 52
                        color: Qt.rgba(pal.primary.r, pal.primary.g, pal.primary.b, 0.17)
                    }
                    // bright border ring
                    Rectangle {
                        anchors.centerIn: parent; width: 97; height: 97; radius: 49
                        color: "transparent"
                        border.color: Qt.rgba(pal.primary.r, pal.primary.g, pal.primary.b, 0.55)
                        border.width: 1
                    }

                    Image {
                        id: avatarSrc
                        source: Qt.resolvedUrl("assets/avatar.jpg")
                        visible: false
                        asynchronous: true
                        onStatusChanged: if (status === Image.Ready) avatarCanvas.requestPaint()
                    }

                    Canvas {
                        id: avatarCanvas
                        width: 92; height: 92
                        anchors.centerIn: parent
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, 92, 92)

                            if (avatarSrc.status === Image.Ready) {
                                ctx.save()
                                ctx.beginPath()
                                ctx.arc(46, 46, 46, 0, Math.PI*2)
                                ctx.clip()
                                ctx.drawImage(avatarSrc, 0, 0, 92, 92)
                                ctx.restore()
                            } else {
                                var g = ctx.createRadialGradient(30, 20, 0, 46, 46, 60)
                                g.addColorStop(0, Qt.rgba(pal.primaryBright.r, pal.primaryBright.g, pal.primaryBright.b, 1))
                                g.addColorStop(1, Qt.rgba(pal.primaryDim.r, pal.primaryDim.g, pal.primaryDim.b, 1))
                                ctx.beginPath(); ctx.arc(46, 46, 46, 0, Math.PI*2)
                                ctx.fillStyle = g; ctx.fill()
                            }
                        }
                        property color watchPrimary: pal.primary
                        onWatchPrimaryChanged: requestPaint()
                    }
                }

                // greeting + username
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 5
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: greeting
                        color: pal.onSurfaceDim
                        font.family: "Rubik"; font.pixelSize: 16
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 0
                        Text {
                            id: uNameTxt
                            text: currentUser
                            color: pal.onSurface
                            font.family: "Rubik"; font.pixelSize: 28; font.weight: Font.SemiBold
                        }
                        Text {
                            text: " @" + (sddm.hostName || "local")
                            color: pal.onSurfaceDim
                            font.family: "Rubik"; font.pixelSize: 17; font.weight: Font.Normal
                            anchors.bottom: uNameTxt.bottom; anchors.bottomMargin: 3
                        }
                    }
                }

                // password field
                Rectangle {
                    id: pwWrap
                    width: parent.width; height: 62; radius: 31
                    color: Qt.rgba(pal.surface2.r, pal.surface2.g, pal.surface2.b, 0.70)
                    border.width: 1
                    border.color: authState === "error"   ? pal.error
                                : authState === "success" ? pal.success
                                : passwordField.activeFocus
                                    ? Qt.rgba(pal.primary.r, pal.primary.g, pal.primary.b, 0.80)
                                    : Qt.rgba(1,1,1, 0.12)
                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    SequentialAnimation {
                        running: authState === "error"
                        NumberAnimation { target: pwWrap; property: "x"; from: -8; to:  8; duration: 55 }
                        NumberAnimation { target: pwWrap; property: "x"; from:  8; to: -6; duration: 55 }
                        NumberAnimation { target: pwWrap; property: "x"; from: -6; to:  6; duration: 55 }
                        NumberAnimation { target: pwWrap; property: "x"; from:  6; to:  0; duration: 55 }
                    }

                    // Layout: [lock 20] [8] [input flex] [8] [eye 32] [6] [go 46] [8]
                    Item {
                        anchors.fill: parent
                        anchors.leftMargin: 18; anchors.rightMargin: 8

                        // lock icon
                        Text {
                            id: lockIcon
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: authState === "success" ? "lock_open" : "lock"
                            font.family: "Material Symbols Rounded"; font.pixelSize: 20
                            color: authState === "error"   ? pal.error
                                 : authState === "success" ? pal.success
                                 : passwordField.activeFocus ? pal.primary
                                 : pal.onSurfaceFaint
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }

                        // submit button (right)
                        Rectangle {
                            id: goBtn
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 46; height: 46; radius: 23
                            color: authState === "success" ? pal.success : pal.primary
                            Behavior on color { ColorAnimation { duration: 300 } }

                            Text {
                                anchors.centerIn: parent
                                visible: authState !== "checking"
                                text: authState === "success" ? "check" : "arrow_forward"
                                font.family: "Material Symbols Rounded"; font.pixelSize: 20; font.weight: Font.Medium
                                color: pal.onPrimary
                            }
                            // spinner
                            Rectangle {
                                anchors.centerIn: parent
                                visible: authState === "checking"
                                width: 22; height: 22; radius: 11
                                color: "transparent"
                                border.width: 2
                                border.color: Qt.rgba(pal.onPrimary.r, pal.onPrimary.g, pal.onPrimary.b, 0.30)
                                Rectangle {
                                    width: 2; height: 9; x: 10; y: 1
                                    color: pal.onPrimary; transformOrigin: Item.Bottom
                                    RotationAnimation on rotation { from:0; to:360; duration:700; loops:Animation.Infinite; running: authState==="checking" }
                                }
                            }
                            MouseArea { anchors.fill: parent; enabled: authState !== "checking"; onClicked: doLogin() }
                        }

                        // eye toggle
                        Rectangle {
                            id: eyeBtn
                            anchors.right: goBtn.left; anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 32; height: 32; radius: 16
                            color: eyeMa.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: showPw ? "visibility_off" : "visibility"
                                font.family: "Material Symbols Rounded"; font.pixelSize: 19
                                color: pal.onSurfaceFaint
                            }
                            MouseArea { id: eyeMa; anchors.fill: parent; hoverEnabled: true; onClicked: showPw = !showPw }
                        }

                        // text input (fills between lock icon and eye)
                        Item {
                            anchors.left: lockIcon.right; anchors.leftMargin: 10
                            anchors.right: eyeBtn.left; anchors.rightMargin: 4
                            anchors.top: parent.top; anchors.bottom: parent.bottom

                            TextInput {
                                id: passwordField
                                anchors.fill: parent
                                verticalAlignment: TextInput.AlignVCenter
                                color: pal.onSurface
                                font.family: "Rubik"; font.pixelSize: 17
                                echoMode: showPw ? TextInput.Normal : TextInput.Password
                                enabled: authState !== "checking" && authState !== "success"
                                focus: true
                                Keys.onReturnPressed: doLogin()
                                Keys.onEnterPressed:  doLogin()
                            }
                            Text {
                                anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                                visible: passwordField.text === ""
                                text: "Enter password"
                                color: pal.onSurfaceFaint
                                font.family: "Rubik"; font.pixelSize: 17
                            }
                        }
                    }
                }

                // caps lock
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 7; visible: capsOn
                    Text { text: "warning"; font.family: "Material Symbols Rounded"; font.pixelSize: 15; color: pal.error; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Caps Lock is on"; font.family: "Rubik"; font.pixelSize: 13; font.weight: Font.Medium; color: pal.error }
                }

                // hint
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: hintText !== "" && authState !== "success"
                    text: hintText; color: pal.onSurfaceFaint
                    font.family: "Rubik"; font.pixelSize: 13
                }
            }
        }
    }

    // ====== BOTTOM BAR (z:6) ======
    Item {
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.leftMargin: 28; anchors.rightMargin: 28; anchors.bottomMargin: 24
        height: 46; z: 6

        // session picker
        Rectangle {
            id: sessionBtn
            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
            height: 38; radius: 19
            width: sessionBtnRow.implicitWidth + 28
            color: sArea.containsMouse ? Qt.rgba(pal.surface2.r,pal.surface2.g,pal.surface2.b,0.80)
                                       : Qt.rgba(pal.surface2.r,pal.surface2.g,pal.surface2.b,0.55)
            border.color: Qt.rgba(1,1,1,0.09); border.width: 1

            Row {
                id: sessionBtnRow; anchors.centerIn: parent; spacing: 8
                Text { text: "dynamic_form"; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: pal.onSurface; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: currentSessionName
                    font.family: "Rubik"; font.pixelSize: 14; font.weight: Font.Medium; color: pal.onSurface; anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "expand_less"; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: pal.onSurface; anchors.verticalCenter: parent.verticalCenter
                    rotation: sessionMenu.visible ? 0 : 180
                    Behavior on rotation { NumberAnimation { duration: 200 } }
                }
            }
            MouseArea { id: sArea; anchors.fill: parent; hoverEnabled: true; onClicked: sessionMenu.visible = !sessionMenu.visible }
        }

        // power buttons
        Row {
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            Repeater {
                model: ListModel {
                    ListElement { icon: "bedtime";            action: "suspend";  danger: false }
                    ListElement { icon: "restart_alt";        action: "reboot";   danger: false }
                    ListElement { icon: "power_settings_new"; action: "shutdown"; danger: true  }
                }
                Rectangle {
                    width: 46; height: 46; radius: 12
                    color: pMa.containsMouse ? (model.danger ? Qt.rgba(pal.error.r,pal.error.g,pal.error.b,0.16) : Qt.rgba(pal.surface3.r,pal.surface3.g,pal.surface3.b,0.80))
                                             : Qt.rgba(pal.surface1.r,pal.surface1.g,pal.surface1.b,0.60)
                    border.color: pMa.containsMouse && model.danger ? Qt.rgba(pal.error.r,pal.error.g,pal.error.b,0.45) : Qt.rgba(1,1,1,0.08)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 180 } }
                    Text {
                        anchors.centerIn: parent; text: model.icon
                        font.family: "Material Symbols Rounded"; font.pixelSize: 22; font.weight: Font.Medium
                        color: pMa.containsMouse && model.danger ? pal.error : pal.onSurfaceDim
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }
                    MouseArea {
                        id: pMa; anchors.fill: parent; hoverEnabled: true
                        onClicked: powerConfirm = { icon: model.icon, label: model.action === "suspend" ? "Suspend" : model.action === "reboot" ? "Restart" : "Shut down", action: model.action, danger: model.danger }
                    }
                }
            }
        }
    }

    // ====== SESSION DROPDOWN (z:30 — above everything) ======
    Rectangle {
        id: sessionMenu
        visible: false
        z: 30
        x: 28
        y: root.height - 24 - 46 - height - 10
        width: 240
        height: Math.min(sessionModel.count * 46 + 14, 230)
        radius: 14
        color: Qt.rgba(pal.surface1.r, pal.surface1.g, pal.surface1.b, 0.96)
        border.color: Qt.rgba(1,1,1,0.10); border.width: 1
        clip: true

        ListView {
            anchors.fill: parent; anchors.margins: 7
            model: sessionModel; spacing: 2
            delegate: Rectangle {
                width: ListView.view.width; height: 44; radius: 9
                color: index === currentSession
                       ? Qt.rgba(pal.primary.r,pal.primary.g,pal.primary.b,0.14)
                       : (itemMa.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent")
                Row {
                    anchors.fill: parent; anchors.leftMargin: 12; spacing: 10
                    Text {
                        text: "dynamic_form"
                        font.family: "Material Symbols Rounded"; font.pixelSize: 18
                        color: index === currentSession ? pal.primary : pal.onSurfaceDim
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: model.name || model.display || ""
                        font.family: "Rubik"; font.pixelSize: 14; font.weight: Font.Medium
                        color: index === currentSession ? pal.onSurface : pal.onSurfaceDim
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea {
                    id: itemMa; anchors.fill: parent; hoverEnabled: true
                    onClicked: {
                        currentSession = index
                        currentSessionName = model.name || model.display || sessionModel.data(sessionModel.index(index,0), Qt.DisplayRole) || "Hyprland"
                        sessionMenu.visible = false
                    }
                }
            }
        }
    }

    // dismiss session menu when clicking outside
    MouseArea {
        anchors.fill: parent
        z: 29
        visible: sessionMenu.visible
        onClicked: sessionMenu.visible = false
    }

    // force cursor shape without blocking clicks
    MouseArea {
        anchors.fill: parent
        z: 9999
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        cursorShape: Qt.ArrowCursor
    }

    // ====== POWER CONFIRM OVERLAY (z:20) ======
    Rectangle {
        anchors.fill: parent
        z: 20
        visible: powerConfirm !== null
        color: Qt.rgba(0, 0, 0, 0.50)

        // click outside to cancel
        MouseArea { anchors.fill: parent; onClicked: powerConfirm = null }

        Rectangle {
            anchors.centerIn: parent
            width: 360; radius: 22
            height: confirmCol.implicitHeight + 56
            color: Qt.rgba(pal.surface1.r, pal.surface1.g, pal.surface1.b, 0.96)
            border.color: Qt.rgba(1,1,1, 0.10); border.width: 1

            // eat clicks so they don't bubble to the dismiss area above
            MouseArea { anchors.fill: parent }

            Column {
                id: confirmCol
                anchors.centerIn: parent
                width: parent.width - 48
                spacing: 12

                // icon circle
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 72; height: 72; radius: 36
                    color: powerConfirm && powerConfirm.danger
                           ? Qt.rgba(pal.error.r, pal.error.g, pal.error.b, 0.18)
                           : Qt.rgba(pal.primary.r, pal.primary.g, pal.primary.b, 0.18)
                    Text {
                        anchors.centerIn: parent
                        text: powerConfirm ? powerConfirm.icon : ""
                        font.family: "Material Symbols Rounded"; font.pixelSize: 34; font.weight: Font.Medium
                        color: powerConfirm && powerConfirm.danger ? pal.error : pal.primary
                    }
                }

                // title
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: powerConfirm ? (powerConfirm.label + "?") : ""
                    color: pal.onSurface
                    font.family: "Rubik"; font.pixelSize: 22; font.weight: Font.SemiBold
                }

                // description
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: {
                        if (!powerConfirm) return ""
                        if (powerConfirm.action === "suspend")  return "The system will sleep and resume where you left off."
                        if (powerConfirm.action === "reboot")   return "All applications will close and the system will restart."
                        return "All applications will close and the system will power off."
                    }
                    color: pal.onSurfaceDim
                    font.family: "Rubik"; font.pixelSize: 14
                }

                // buttons
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12
                    topPadding: 6

                    // cancel
                    Rectangle {
                        width: 130; height: 46; radius: 23
                        color: cancelMa.containsMouse ? Qt.rgba(pal.surface3.r,pal.surface3.g,pal.surface3.b,0.80)
                                                      : Qt.rgba(pal.surface2.r,pal.surface2.g,pal.surface2.b,0.60)
                        border.color: Qt.rgba(1,1,1,0.12); border.width: 1
                        Text { anchors.centerIn: parent; text: "Cancel"; color: pal.onSurface; font.family: "Rubik"; font.pixelSize: 15; font.weight: Font.Medium }
                        MouseArea { id: cancelMa; anchors.fill: parent; hoverEnabled: true; onClicked: powerConfirm = null }
                    }

                    // confirm
                    Rectangle {
                        width: 130; height: 46; radius: 23
                        color: powerConfirm && powerConfirm.danger ? pal.error : pal.primary
                        Text { anchors.centerIn: parent; text: powerConfirm ? powerConfirm.label : ""; color: pal.onPrimary; font.family: "Rubik"; font.pixelSize: 15; font.weight: Font.Medium }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                var a = powerConfirm ? powerConfirm.action : ""
                                powerConfirm = null
                                if      (a === "suspend")  sddm.suspend()
                                else if (a === "reboot")   sddm.reboot()
                                else if (a === "shutdown") sddm.powerOff()
                            }
                        }
                    }
                }
            }
        }
    }
}
