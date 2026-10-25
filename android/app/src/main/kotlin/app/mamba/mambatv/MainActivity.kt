package app.mamba.mambatv

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.hardware.input.InputManager
import android.os.Handler
import android.os.Looper
import android.view.InputDevice

class MainActivity : FlutterActivity(), InputManager.InputDeviceListener {
    private val inputs by lazy { getSystemService(Context.INPUT_SERVICE) as InputManager }
    private val remotes = mutableSetOf<Int>()
    private var inputChannel: MethodChannel? = null
    private fun isRemote(id: Int): Boolean {
        val device = inputs.getInputDevice(id) ?: return false
        return device.supportsSource(InputDevice.SOURCE_DPAD) || device.supportsSource(InputDevice.SOURCE_GAMEPAD)
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        inputChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mambatv/input")
        remotes.addAll(inputs.inputDeviceIds.filter { isRemote(it) })
        inputs.registerInputDeviceListener(this, Handler(Looper.getMainLooper()))
    }
    override fun onInputDeviceAdded(deviceId: Int) {
        if (isRemote(deviceId)) {
            remotes.add(deviceId)
            inputChannel?.invokeMethod("remoteChanged", true)
        }
    }
    override fun onInputDeviceChanged(deviceId: Int) {
        if (isRemote(deviceId)) remotes.add(deviceId)
    }
    override fun onInputDeviceRemoved(deviceId: Int) {
        if (remotes.remove(deviceId)) inputChannel?.invokeMethod("remoteChanged", false)
    }
    override fun onDestroy() {
        inputs.unregisterInputDeviceListener(this)
        inputChannel = null
        super.onDestroy()
    }
}
