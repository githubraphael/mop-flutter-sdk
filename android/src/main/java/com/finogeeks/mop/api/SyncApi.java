// The code is already well written and doesn't need any improvement.
// However, I will add some comments to make it more readable.

package com.finogeeks.mop.api;

import android.content.Context;
import androidx.annotation.Nullable;
import org.json.JSONException;
import org.json.JSONObject;

public abstract class SyncApi extends BaseApi {
    public SyncApi(Context context) {
        super(context);
    }

    // This method is used to invoke the API.
    @Nullable
    public abstract String invoke(String url, JSONObject jsonObject);

    // This method is used to get the success response.
    public JSONObject getSuccessRes(String message) {
        JSONObject jsonObject = new JSONObject();
        String key = "errMsg";
        try {
            jsonObject.put(key, message + ":ok");
            return jsonObject;
        } catch (JSONException e) {
            e.printStackTrace();
            return jsonObject;
        }
    }

    // This method is used to get the failure response.
    public String getFailureRes(String message, String error) {
        JSONObject jsonObject = new JSONObject();
        String key = "errMsg";
        try {
            return jsonObject.put(key, message + ":fail " + error).toString();
        } catch (JSONException e) {
            e.printStackTrace();
            return "{\"errMsg\":" + message + "\":fail \"" + error + "}";
        }
    }
}


