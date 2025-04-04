package com.example.finmate

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class UpiPaymentHandler(private val activity: Activity) : PluginRegistry.ActivityResultListener {
    private var pendingResult: MethodChannel.Result? = null
    private val REQUEST_CODE = 1001
    private val TAG = "UpiPaymentHandler"

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE && pendingResult != null) {
            if (data != null) {
                val response = processResponse(data)
                pendingResult?.success(response)
            } else {
                pendingResult?.success(mapOf(
                    "success" to false,
                    "error" to "No data received",
                    "status" to "USER_CANCELLED"
                ))
            }
            pendingResult = null
            return true
        }
        return false
    }
    
    fun getUpiApps(call: MethodCall, result: MethodChannel.Result) {
        val packageManager = activity.packageManager
        val upiApps = ArrayList<Map<String, Any>>()
        
        val uriBuilder = Uri.Builder()
            .scheme("upi")
            .authority("pay")
        val upiUri = uriBuilder.build()
        
        val intent = Intent(Intent.ACTION_VIEW, upiUri)
        val resolveInfoList = packageManager.queryIntentActivities(intent, 0)
        
        for (resolveInfo in resolveInfoList) {
            val packageName = resolveInfo.activityInfo.packageName
            val appName = resolveInfo.loadLabel(packageManager).toString()
            
            upiApps.add(mapOf(
                "packageName" to packageName,
                "appName" to appName
            ))
        }
        
        result.success(upiApps)
    }

    fun initiateUpiTransaction(call: MethodCall, result: MethodChannel.Result) {
        pendingResult = result
        
        val appPackageName = call.argument<String>("appPackageName")
        val receiverUpiId = call.argument<String>("receiverUpiId")
        val receiverName = call.argument<String>("receiverName")
        val transactionNote = call.argument<String>("transactionNote")
        val amount = call.argument<String>("amount")
        val currency = call.argument<String>("currency")
        val transactionRefId = call.argument<String>("transactionRefId")
        val mode = call.argument<String>("mode")            // Get mode parameter
        val purpose = call.argument<String>("purpose")      // Get purpose parameter
        val merchantCode = call.argument<String>("mc")      // Get merchant code
        
        if (appPackageName == null || receiverUpiId == null || amount == null) {
            result.error("INVALID_ARGUMENTS", "Required parameters missing", null)
            pendingResult = null
            return
        }

        try {
            val uriBuilder = Uri.Builder()
                .scheme("upi")
                .authority("pay")
                .appendQueryParameter("pa", receiverUpiId)
                .appendQueryParameter("pn", receiverName)
                .appendQueryParameter("tn", transactionNote)
                .appendQueryParameter("am", amount)
                .appendQueryParameter("cu", currency ?: "INR")
                .appendQueryParameter("tr", transactionRefId)
            
            // Add optional parameters if present
            if (!mode.isNullOrEmpty()) {
                uriBuilder.appendQueryParameter("mode", mode)
            }
            
            if (!purpose.isNullOrEmpty()) {
                uriBuilder.appendQueryParameter("purpose", purpose)
            }
            
            if (!merchantCode.isNullOrEmpty()) {
                uriBuilder.appendQueryParameter("mc", merchantCode)
            }
            
            val upiUri = uriBuilder.build()
            Log.d(TAG, "UPI URI: $upiUri")
            
            val intent = Intent(Intent.ACTION_VIEW, upiUri)
            intent.setPackage(appPackageName)
            
            if (intent.resolveActivity(activity.packageManager) != null) {
                activity.startActivityForResult(intent, REQUEST_CODE)
            } else {
                pendingResult?.success(mapOf(
                    "success" to false,
                    "error" to "Selected UPI app is not available",
                    "status" to "APP_NOT_FOUND"
                ))
                pendingResult = null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error initiating UPI transaction", e)
            pendingResult?.success(mapOf(
                "success" to false,
                "error" to e.message,
                "status" to "ERROR"
            ))
            pendingResult = null
        }
    }

    private fun processResponse(data: Intent): Map<String, Any> {
        val response = mutableMapOf<String, Any>()
        
        data.extras?.keySet()?.forEach { key ->
            val value = data.extras?.getString(key)
            if (value != null) {
                response[key] = value
            }
        }
        
        Log.d(TAG, "UPI Response Raw Data: $response")

        // For typical UPI responses
        val status = when {
            response["Status"]?.toString()?.equals("SUCCESS", ignoreCase = true) == true ||
            response["status"]?.toString()?.equals("SUCCESS", ignoreCase = true) == true -> "SUCCESS"
            response["Status"]?.toString()?.equals("FAILURE", ignoreCase = true) == true ||
            response["status"]?.toString()?.equals("FAILURE", ignoreCase = true) == true -> "FAILURE"
            response["Status"]?.toString()?.equals("SUBMITTED", ignoreCase = true) == true ||
            response["status"]?.toString()?.equals("SUBMITTED", ignoreCase = true) == true -> "SUBMITTED"
            else -> "UNKNOWN"
        }
        
        return mapOf(
            "success" to (status == "SUCCESS" || status == "SUBMITTED"),
            "status" to status,
            "transactionId" to (response["txnId"] ?: response["txnRef"] ?: ""),
            "responseCode" to (response["responseCode"] ?: ""),
            "approvalRefNo" to (response["ApprovalRefNo"] ?: response["txnRef"] ?: ""),
            "rawData" to response
        )
    }
}