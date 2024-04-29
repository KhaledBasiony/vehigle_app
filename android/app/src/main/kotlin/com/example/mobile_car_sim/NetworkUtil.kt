package com.example.mobile_car_sim

import android.content.Context
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager

class NetworkUtils {
    companion object {
        fun getDeviceIPAddress(context: Context): String {
            val wifiManager = context.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val wifiInfo: WifiInfo = wifiManager.connectionInfo
            val ip = wifiInfo.ipAddress
            return String.format(
                "%d.%d.%d.%d",
                ip and 0xff,
                ip shr 8 and 0xff,
                ip shr 16 and 0xff,
                ip shr 24 and 0xff
            )
        }
    }
}
