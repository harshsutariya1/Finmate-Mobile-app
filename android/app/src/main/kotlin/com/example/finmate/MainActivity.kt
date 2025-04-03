package com.example.finmate

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent

class MainActivity: FlutterActivity() {
    private lateinit var channel: MethodChannel
    private lateinit var upiPaymentHandler: UpiPaymentHandler
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        upiPaymentHandler = UpiPaymentHandler(this)
        
        // Register the method channel
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.finmate/upi_payment")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getUpiApps" -> upiPaymentHandler.getUpiApps(call, result)
                "initiateUpiTransaction" -> upiPaymentHandler.initiateUpiTransaction(call, result)
                else -> result.notImplemented()
            }
        }
    }
    
    // Override onActivityResult to forward results to the UPI handler
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        upiPaymentHandler.onActivityResult(requestCode, resultCode, data)
    }
}
