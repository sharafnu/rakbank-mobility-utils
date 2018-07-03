package com.rakbank.mobility;

import android.net.Uri;
import android.util.Base64;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaResourceApi;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.regex.Pattern;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;


import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.apache.cordova.PluginResult.Status;
import org.json.JSONObject;
import org.json.JSONArray;
import org.json.JSONException;
import android.widget.Toast;
import android.content.Context;

import android.util.Log;

import java.util.Date;

public class MobilityUtils extends CordovaPlugin {
	private static final String TAG = "MobilityUtils";
	private static final String CRYPT_KEY = "";
    private static final String CRYPT_IV = "";

	public void initialize(CordovaInterface cordova, CordovaWebView webView) {
		super.initialize(cordova, webView);
	}

	public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
		if (action.equals("echo")) {
			String phrase = args.getString(0);
			Toast.makeText(webView.getContext(), phrase, Toast.LENGTH_LONG).show();
		} else if (action.equals("getDate")) {
			// An example of returning data back to the web layer
			final PluginResult result = new PluginResult(PluginResult.Status.OK, (new Date()).toString());
			callbackContext.sendPluginResult(result);
		} else if (action.equals("loadProps")) {
			// An example of returning data back to the web layer
			String fileContents = null;
			try {

				String filePath = "assets/props.json";
				
				Uri fileUri = Uri.parse("file:///android_asset/www/assets/props.json");

				CordovaResourceApi.OpenForReadResult readResult =  this.webView.getResourceApi().openForRead(fileUri, true);

				BufferedReader br = new BufferedReader(new InputStreamReader(readResult.inputStream));
        		StringBuilder strb = new StringBuilder();
        		String line = null;
        		while ((line = br.readLine()) != null) {
            		strb.append(line);
        		}

				br.close();

        		byte[] bytes = Base64.decode(strb.toString(), Base64.DEFAULT);
        				        	
            	SecretKey skey = new SecretKeySpec(CRYPT_KEY.getBytes("UTF-8"), "AES");
            	Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
            	cipher.init(Cipher.DECRYPT_MODE, skey, new IvParameterSpec(CRYPT_IV.getBytes("UTF-8")));

            	ByteArrayOutputStream bos = new ByteArrayOutputStream();
            	bos.write(cipher.doFinal(bytes));
            	//byteInputStream = new ByteArrayInputStream(bos.toByteArray());

				fileContents = new String(bos.toByteArray());
        	} catch (Exception ex) {
				ex.printStackTrace();
        	}
			final PluginResult fileContentsResult = new PluginResult(PluginResult.Status.OK, fileContents);
        	callbackContext.sendPluginResult(fileContentsResult);
		}
		return true;
	}
}