#Requires AutoHotkey v2.0

/**
 * @description A versatile library for capturing screenshots in various ways using CGdip.ahk.
 */

#include dependencies\CGdip.ahk

class Screenshooter {
    /**
     * @description Sets the logging callback
     * @param {function} callback - The callback to be called when logging, must be a function with a single string parameter
     */
    static _loggerCallback := ''
    /**
     * @description Captures the entire screen.
     * @param {String} outputFile Path to save the output file.
     */
    static CaptureFullScreen(outputFile) {
        if Screenshooter._loggerCallback
            Screenshooter._loggerCallback.Call("Capturing full screen")
        if (A_ScreenWidth <= 0 || A_ScreenHeight <= 0) {
            if Screenshooter._loggerCallback
                Screenshooter._loggerCallback.Call("Invalid screen dimensions: " A_ScreenWidth "x" A_ScreenHeight)
            throw Error("Invalid screen dimensions: " A_ScreenWidth "x" A_ScreenHeight)
        }
        this._CaptureRegion(0, 0, A_ScreenWidth, A_ScreenHeight, outputFile, 0)
        if Screenshooter._loggerCallback
            Screenshooter._loggerCallback.Call("Captured full screen")
    }

    /**
     * @description Captures a specific window.
     * @param {Integer} hwnd Handle of the window.
     * @param {String} outputFile Path to save the output file.
     * @param {Integer} margin Additional margin to include around the window (default: 0).
     */
    static CaptureWindow(hwnd, outputFile, margin := 0) {
        if Screenshooter._loggerCallback
            Screenshooter._loggerCallback.Call("Capturing window")
        if (!this.WindowExist(hwnd)) {
            if Screenshooter._loggerCallback
                Screenshooter._loggerCallback.Call("Invalid window handle (hwnd) or window not found.")
            throw Error("Invalid window handle (hwnd) or window not found.")
        }

        ; Ensure the window is activated
        this.EnsureWindowActive(hwnd)
        if Screenshooter._loggerCallback
            Screenshooter._loggerCallback.Call("Window activated")

        WinGetPos(&windowX, &windowY, &width, &height, hwnd)
        if Screenshooter._loggerCallback
            Screenshooter._loggerCallback.Call("Window position retrieved. x: " windowX " y: " windowY " width: " width " height: " height)
        this._CaptureRegion(windowX - margin, windowY - margin, width + 2 * margin, height + 2 * margin, outputFile, margin)
        if Screenshooter._loggerCallback
            Screenshooter._loggerCallback.Call("Captured window")
    }

    /**
     * @description Captures the client area of a window.
     * @param {Integer} hwnd Handle of the window.
     * @param {String} outputFile Path to save the output file.
     * @param {Integer} margin Additional margin to include around the client area (default: 0).
     */
    static CaptureClientArea(hwnd, outputFile, margin := 0) {
        if Screenshooter._loggerCallback
            Screenshooter._loggerCallback.Call("Capturing client area")
        if (!this.WindowExist(hwnd)) {
            if Screenshooter._loggerCallback
                Screenshooter._loggerCallback.Call("Invalid window handle (hwnd) or window not found.")
            throw Error("Invalid window handle (hwnd) or window not found.")
        }

        ; Ensure the window is activated
        this.EnsureWindowActive(hwnd)
        if Screenshooter._loggerCallback
            Screenshooter._loggerCallback.Call("Window activated")

        rect := Buffer(16, 0)
        if (!this.SafeDllCall("User32\GetClientRect", hwnd, rect)) {
            if Screenshooter._loggerCallback
                Screenshooter._loggerCallback.Call("Failed to get client area rectangle.")
            throw Error("Failed to get client area rectangle.")
        }

        if (!this.SafeDllCall("User32\ClientToScreen", hwnd, rect)) {
            if Screenshooter._loggerCallback
                Screenshooter._loggerCallback.Call("Failed to convert client area coordinates to screen coordinates.")
            throw Error("Failed to convert client area coordinates to screen coordinates.")
        }

        x := NumGet(rect, 0, "Int") - margin
        y := NumGet(rect, 4, "Int") - margin
        width := NumGet(rect, 8, "Int") + 2 * margin
        height := NumGet(rect, 12, "Int") + 2 * margin

        if Screenshooter._loggerCallback
            Screenshooter._loggerCallback.Call("Client area position retrieved. x: " x " y: " y " width: " width " height: " height)

        this._CaptureRegion(x, y, width, height, outputFile, margin)
        if Screenshooter._loggerCallback
            Screenshooter._loggerCallback.Call("Captured client area")
    }

    /**
     * @description Captures a specific control within a window.
     * @param {Integer} windowHwnd Handle of the main window.
     * @param {String} controlID Identifier of the control.
     * @param {String} outputFile Path to save the output file.
     * @param {Integer} margin Additional margin to include around the control (default: 0).
     */
    static CaptureControl(windowHwnd, controlID, outputFile, margin := 0) {
        if Screenshooter._loggerCallback
            Screenshooter._loggerCallback.Call("Capturing control")
        if (!this.WindowExist(windowHwnd) || !this.ControlExist(controlID, windowHwnd)) {
            if Screenshooter._loggerCallback
                Screenshooter._loggerCallback.Call("Invalid ControlID or window handle (windowHwnd).")
            throw Error("Invalid ControlID or window handle (windowHwnd).")
        }

        ; Ensure the window is activated
        this.EnsureWindowActive(windowHwnd)
        if Screenshooter._loggerCallback
            Screenshooter._loggerCallback.Call("Window activated")

        try {
            ControlGetPos(&controlX, &controlY, &width, &height, controlID, "ahk_id " windowHwnd)
        } catch {
            if Screenshooter._loggerCallback
                Screenshooter._loggerCallback.Call("Failed to retrieve coordinates of the specified control.")
            throw Error("Failed to retrieve coordinates of the specified control.")
        }

        clientPt := Buffer(8, 0)
        NumPut("Int", controlX, clientPt, 0)
        NumPut("Int", controlY, clientPt, 4)
        if (!this.SafeDllCall("User32\ClientToScreen", windowHwnd, clientPt)) {
            if Screenshooter._loggerCallback
                Screenshooter._loggerCallback.Call("Failed to convert control coordinates to screen coordinates.")
            throw Error("Failed to convert control coordinates to screen coordinates.")
        }
        x := NumGet(clientPt, 0, "Int") - margin
        y := NumGet(clientPt, 4, "Int") - margin

        if Screenshooter._loggerCallback
            Screenshooter._loggerCallback.Call("Control position retrieved. x: " x " y: " y " width: " width " height: " height)

        this._CaptureRegion(x, y, width + 2 * margin, height + 2 * margin, outputFile, margin)
        if Screenshooter._loggerCallback
            Screenshooter._loggerCallback.Call("Captured control")
    }

    /**
     * @description Captures a specific region of the screen.
     * @param {Integer} x Starting X coordinate.
     * @param {Integer} y Starting Y coordinate.
     * @param {Integer} width Width of the region.
     * @param {Integer} height Height of the region.
     * @param {String} outputFile Path to save the output file.
     * @param {Integer} margin Additional margin to include around the region (default: 0).
     */
    static _CaptureRegion(x, y, width, height, outputFile, margin := 0) {
        if Screenshooter._loggerCallback
            Screenshooter._loggerCallback.Call("Capturing region")
        if (width <= 0 || height <= 0) {
            if Screenshooter._loggerCallback
                Screenshooter._loggerCallback.Call("Invalid region dimensions: " width "x" height)
            throw Error("Invalid region dimensions: " width "x" height)
        }

        if (!Screenshooter.InitializeGDI()) {
            if Screenshooter._loggerCallback
                Screenshooter._loggerCallback.Call("Failed to initialize CGdip")
            throw Error("Failed to initialize CGdip")
        }

        try {
            pBitmap := CGdip.Bitmap.FromScreen(x "|" y "|" width "|" height)
            if (!pBitmap) {
                if Screenshooter._loggerCallback
                    Screenshooter._loggerCallback.Call("Failed to create bitmap for capture")
                throw Error("Failed to create bitmap for capture")
            }
            if Screenshooter._loggerCallback
                Screenshooter._loggerCallback.Call("Bitmap created")

            if (pBitmap.Save(outputFile) != 0) {
                if Screenshooter._loggerCallback
                    Screenshooter._loggerCallback.Call("Failed to save file: " outputFile)
                throw Error("Failed to save file: " outputFile)
            }
            if Screenshooter._loggerCallback
                Screenshooter._loggerCallback.Call("Captured region")
        } finally {
            if (pBitmap) {
                pBitmap := ""
                if Screenshooter._loggerCallback
                    Screenshooter._loggerCallback.Call("Bitmap destroyed")
            }
            Screenshooter.ShutdownGDI()
            if Screenshooter._loggerCallback
                Screenshooter._loggerCallback.Call("GDI shutdown")
        }
    }

    /**
     * @description Ensures a window is active. Activates it if not already active and waits for it to fully appear.
     * @param {Integer} hwnd Handle of the window.
     */
    static EnsureWindowActive(hwnd) {
        if Screenshooter._loggerCallback
            Screenshooter._loggerCallback.Call("Ensuring window active")
        if (!WinActive("ahk_id " hwnd)) {
            WinActivate("ahk_id " hwnd)
            Sleep(200) ; Allow some time for animations or transitions to complete
        }
    }

    /**
     * @description Initializes GDI+.
     * @returns {Boolean} True if successfully initialized.
     */
    static InitializeGDI() {
        if Screenshooter._loggerCallback
            Screenshooter._loggerCallback.Call("Initializing GDI+")
        return CGdip.Startup()
    }

    /**
     * @description Shuts down GDI+.
     */
    static ShutdownGDI() {
        if Screenshooter._loggerCallback
            Screenshooter._loggerCallback.Call("Shutting down GDI+")
        CGdip.Shutdown()
    }

    /**
     * @description Checks if a window exists.
     * @param {Integer} hwnd Handle of the window.
     * @returns {Boolean} True if the window exists.
     */
    static WindowExist(hwnd) {
        if Screenshooter._loggerCallback
            Screenshooter._loggerCallback.Call("Checking if window exists")
        return WinExist("ahk_id " hwnd)
    }

    /**
     * @description Checks if a control exists in a window.
     * @param {String} controlID Identifier of the control.
     * @param {Integer} hwnd Handle of the window.
     * @returns {Boolean} True if the control exists.
     */
    static ControlExist(controlID, hwnd) {
        if Screenshooter._loggerCallback
            Screenshooter._loggerCallback.Call("Checking if control exists")
        try {
            ControlGetPos(, , , , controlID, "ahk_id " hwnd)
            return true
        } catch {
            return false
        }
    }

    /**
     * @description Performs a safe DllCall.
     * @param {String} functionName Name of the DLL function.
     * @param {Integer} hwnd Handle of the window.
     * @param {Buffer} buffer Additional argument buffer.
     * @returns {Boolean} True if the call was successful.
     */
    static SafeDllCall(functionName, hwnd, buffer) {
        if Screenshooter._loggerCallback
            Screenshooter._loggerCallback.Call("Performing safe DllCall")
        try {
            return DllCall(functionName, "Ptr", hwnd, "Ptr", buffer)
        } catch {
            if Screenshooter._loggerCallback
                Screenshooter._loggerCallback.Call("Failed to perform safe DllCall")
            return false
        }
    }
}
