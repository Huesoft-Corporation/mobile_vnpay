package com.hsmobile.mobile_vnpay

import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.util.Log
import androidx.annotation.NonNull
import com.vnpay.authentication.VNP_AuthenticationActivity

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

/** MobileVnpayPlugin */
class MobileVnpayPlugin: FlutterPlugin, ActivityAware, PluginRegistry.ActivityResultListener, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private var activityBinding: ActivityPluginBinding? = null
  private var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    this.flutterPluginBinding = flutterPluginBinding
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "mobile_vnpay")
    channel.setMethodCallHandler(this)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activityBinding = binding
    binding.addActivityResultListener(this)
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding)
  }

  override fun onDetachedFromActivity() {
    activityBinding?.removeActivityResultListener(this)
    activityBinding = null
  }

  override fun onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity()
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    this.flutterPluginBinding = binding
    channel.setMethodCallHandler(null)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "show") {
      this.handleShow(call)
      result.success(null)
    } else {
      result.notImplemented()
    }
  }

  private fun handleShow(@NonNull call: MethodCall) {
    val params = call.arguments as HashMap<*, *>
    val paymentUrl = params["paymentUrl"] as String
    val scheme = params["scheme"] as String
    val tmnCode = params["tmn_code"] as String
    val intent = Intent(flutterPluginBinding!!.applicationContext, VNP_AuthenticationActivity::class.java).apply {
      putExtra("url", paymentUrl)
      putExtra("scheme", scheme)
      putExtra("tmn_code", tmnCode)
    }
    VNP_AuthenticationActivity.setSdkCompletedCallback { action ->
      Log.wtf("VNP_AuthenticationActivity", "action: $action")
      if (action == "AppBackAction") {
        channel.invokeMethod("PaymentBack", hashMapOf("resultCode" to -1))
      }
      if (action == "CallMobileBankingApp") {
        channel.invokeMethod("PaymentBack", hashMapOf("resultCode" to 10))
      }
      if (action == "WebBackAction") {
        channel.invokeMethod("PaymentBack", hashMapOf("resultCode" to 24))
      }
      if (action == "FaildBackAction") {
        channel.invokeMethod("PaymentBack", hashMapOf("resultCode" to 99))
      }
      if (action == "FailBackAction") {
        channel.invokeMethod("PaymentBack", hashMapOf("resultCode" to 99))
      }
      if (action == "SuccessBackAction") {
        channel.invokeMethod("PaymentBack", hashMapOf("resultCode" to 0))
      }

      //action == AppBackAction
      //Ng?????i d??ng nh???n back t??? sdk ????? quay l???i

      //action == CallMobileBankingApp
      //Ng?????i d??ng nh???n ch???n thanh to??n qua app thanh to??n (Mobile Banking, V??...)
      //l??c n??y app t??ch h???p s??? c???n l??u l???i m?? giao d???ch thanh to??n (vnp_TxnRef). Khi ng?????i d??ng m??? l???i app t??ch h???p v???i cheme th?? s??? g???i ki???m tra tr???ng th??i thanh to??n c???a m?? TxnRef ???? ki???m tra xem ???? thanh to??n hay ch??a ????? th???c hi???n nghi???p v??? k???t th??c thanh to??n / th??ng b??o k???t qu??? cho kh??ch h??ng..

      //action == WebBackAction
      //T???o n??t s??? ki???n cho user click t??? return url c???a merchant chuy???n h?????ng v??? URL: http://cancel.sdk.merchantbackapp
      // vnp_ResponseCode == 24 / Kh??ch h??ng h???y thanh to??n.

      //action == FaildBackAction
      //T???o n??t s??? ki???n cho user click t??? return url c???a merchant chuy???n h?????ng v??? URL: http://fail.sdk.merchantbackapp
      // vnp_ResponseCode != 00 / Giao d???ch thanh to??n kh??ng th??nh c??ng

      //action == SuccessBackAction
      //T???o n??t s??? ki???n cho user click t??? return url c???a merchant chuy???n h?????ng v??? URL: http://success.sdk.merchantbackapp
      //vnp_ResponseCode == 00) / Giao d???ch th??nh c??ng
    }
    activityBinding?.activity?.startActivity(intent)
//        activityBinding?.activity?.startActivityForResult(intent, 99)
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (requestCode == 99) {
      channel.invokeMethod("resultCode", resultCode)
    }
    return false
  }
}
