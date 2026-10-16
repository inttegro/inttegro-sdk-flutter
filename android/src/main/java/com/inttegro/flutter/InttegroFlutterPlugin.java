package com.inttegro.flutter;

import android.app.Activity;
import android.content.Intent;
import androidx.annotation.NonNull;
import com.inttegro.payments.PaymentSheetException;
import com.inttegro.payments.PaymentSheetLauncher;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.EventChannel;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import org.json.JSONArray;
import org.json.JSONObject;

public final class InttegroFlutterPlugin implements
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware,
    PluginRegistry.ActivityResultListener {
  private static final String CHANNEL_NAME = "com.inttegro/sdk";
  private static final String EVENT_CHANNEL_NAME = "com.inttegro/sdk/events";
  private static final String TELEMETRY_CHANNEL_NAME = "com.inttegro/sdk/telemetry";
  private static final int REQUEST_CODE = 18_271;

  private MethodChannel channel;
  private EventChannel eventChannel;
  private EventChannel telemetryChannel;
  private EventChannel.EventSink eventSink;
  private EventChannel.EventSink telemetrySink;
  private Activity activity;
  private ActivityPluginBinding activityBinding;
  private String configurationJson;
  private MethodChannel.Result presentationResult;
  private Intent launchIntent;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    channel.setMethodCallHandler(this);
    eventChannel = new EventChannel(binding.getBinaryMessenger(), EVENT_CHANNEL_NAME);
    eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
      @Override
      public void onListen(Object arguments, EventChannel.EventSink events) {
        eventSink = events;
      }

      @Override
      public void onCancel(Object arguments) {
        eventSink = null;
      }
    });
    telemetryChannel = new EventChannel(
        binding.getBinaryMessenger(),
        TELEMETRY_CHANNEL_NAME
    );
    telemetryChannel.setStreamHandler(new EventChannel.StreamHandler() {
      @Override
      public void onListen(Object arguments, EventChannel.EventSink events) {
        telemetrySink = events;
      }

      @Override
      public void onCancel(Object arguments) {
        telemetrySink = null;
      }
    });
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    detachFromActivity();
    PaymentSheetLauncher.release(launchIntent);
    launchIntent = null;
    if (channel != null) {
      channel.setMethodCallHandler(null);
      channel = null;
    }
    if (eventChannel != null) {
      eventChannel.setStreamHandler(null);
      eventChannel = null;
      eventSink = null;
    }
    if (telemetryChannel != null) {
      telemetryChannel.setStreamHandler(null);
      telemetryChannel = null;
      telemetrySink = null;
    }
    rejectPendingPresentation(
        "plugin_detached",
        "The Inttegro plugin detached before the payment sheet completed."
    );
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
    switch (call.method) {
      case "initializePaymentSheet":
        initializePaymentSheet(call.arguments, result);
        break;
      case "presentPaymentSheet":
        presentPaymentSheet(result);
        break;
      default:
        result.notImplemented();
    }
  }

  private void initializePaymentSheet(Object arguments, MethodChannel.Result result) {
    if (presentationResult != null) {
      result.error(
          "payment_sheet_already_presented",
          "The payment sheet is already presented.",
          null
      );
      return;
    }
    if (!(arguments instanceof Map)) {
      result.error(
          "invalid_configuration",
          "The payment sheet configuration must be an object.",
          null
      );
      return;
    }

    try {
      configurationJson = new JSONObject((Map<?, ?>) arguments).toString();
      PaymentSheetLauncher.validateConfiguration(configurationJson);
      result.success(null);
    } catch (PaymentSheetException error) {
      configurationJson = null;
      result.error(error.getCode(), error.getMessage(), null);
    } catch (Exception error) {
      configurationJson = null;
      result.error(
          "invalid_configuration",
          error.getMessage() == null
              ? "The payment sheet configuration is invalid."
              : error.getMessage(),
          null
      );
    }
  }

  private void presentPaymentSheet(MethodChannel.Result result) {
    if (presentationResult != null) {
      result.error(
          "payment_sheet_already_presented",
          "The payment sheet is already presented.",
          null
      );
      return;
    }
    if (configurationJson == null) {
      result.error(
          "payment_sheet_not_initialized",
          "Initialize the payment sheet before presenting it.",
          null
      );
      return;
    }
    if (activity == null) {
      result.error(
          "presentation_unavailable",
          "The payment sheet needs an active Flutter screen.",
          null
      );
      return;
    }

    try {
      presentationResult = result;
      launchIntent = PaymentSheetLauncher.createIntent(
          activity,
          configurationJson,
          payload -> emitLifecycleEvent(payload),
          payload -> emitTelemetryEvent(payload)
      );
      activity.startActivityForResult(launchIntent, REQUEST_CODE);
    } catch (Exception error) {
      presentationResult = null;
      PaymentSheetLauncher.release(launchIntent);
      launchIntent = null;
      result.error(
          "presentation_unavailable",
          error.getMessage() == null
              ? "The payment sheet could not be presented."
              : error.getMessage(),
          null
      );
    }
  }

  @Override
  public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
    if (requestCode != REQUEST_CODE || presentationResult == null) {
      return false;
    }
    MethodChannel.Result result = presentationResult;
    presentationResult = null;
    String payload = PaymentSheetLauncher.resultFrom(data);
    PaymentSheetLauncher.release(launchIntent);
    launchIntent = null;
    try {
      if (payload == null) {
        result.error(
            "invalid_native_result",
            "The native payment sheet returned no terminal event.",
            null
        );
        return true;
      }
      result.success(jsonObjectToMap(new JSONObject(payload)));
    } catch (Exception error) {
      result.error(
          "invalid_native_result",
          "The native payment sheet returned an invalid result.",
          null
      );
    }
    return true;
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    detachFromActivity();
    activityBinding = binding;
    activity = binding.getActivity();
    binding.addActivityResultListener(this);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    detachFromActivity();
  }

  @Override
  public void onReattachedToActivityForConfigChanges(
      @NonNull ActivityPluginBinding binding
  ) {
    onAttachedToActivity(binding);
  }

  @Override
  public void onDetachedFromActivity() {
    detachFromActivity();
    PaymentSheetLauncher.release(launchIntent);
    launchIntent = null;
    rejectPendingPresentation(
        "presentation_unavailable",
        "The Flutter screen closed before the payment sheet completed."
    );
  }

  private void emitLifecycleEvent(String payload) {
    Activity currentActivity = activity;
    EventChannel.EventSink currentSink = eventSink;
    if (currentActivity == null || currentSink == null) {
      return;
    }
    currentActivity.runOnUiThread(() -> {
      EventChannel.EventSink sink = eventSink;
      if (sink == null) {
        return;
      }
      try {
        sink.success(jsonObjectToMap(new JSONObject(payload)));
      } catch (Exception error) {
        sink.error(
            "invalid_native_event",
            "The native payment sheet returned an invalid lifecycle event.",
            null
        );
      }
    });
  }

  private void emitTelemetryEvent(String payload) {
    Activity currentActivity = activity;
    EventChannel.EventSink currentSink = telemetrySink;
    if (currentActivity == null || currentSink == null) {
      return;
    }
    currentActivity.runOnUiThread(() -> {
      EventChannel.EventSink sink = telemetrySink;
      if (sink == null) {
        return;
      }
      try {
        sink.success(jsonObjectToMap(new JSONObject(payload)));
      } catch (Exception error) {
        sink.error(
            "invalid_native_event",
            "The native payment sheet returned an invalid telemetry event.",
            null
        );
      }
    });
  }

  private void detachFromActivity() {
    if (activityBinding != null) {
      activityBinding.removeActivityResultListener(this);
      activityBinding = null;
    }
    activity = null;
  }

  private void rejectPendingPresentation(String code, String message) {
    if (presentationResult == null) {
      return;
    }
    MethodChannel.Result result = presentationResult;
    presentationResult = null;
    result.error(code, message, null);
  }

  private static Map<String, Object> jsonObjectToMap(JSONObject object) {
    Map<String, Object> result = new HashMap<>();
    Iterator<String> keys = object.keys();
    while (keys.hasNext()) {
      String key = keys.next();
      result.put(key, jsonValue(object.opt(key)));
    }
    return result;
  }

  private static List<Object> jsonArrayToList(JSONArray array) {
    List<Object> result = new ArrayList<>();
    for (int index = 0; index < array.length(); index += 1) {
      result.add(jsonValue(array.opt(index)));
    }
    return result;
  }

  private static Object jsonValue(Object value) {
    if (value == null || value == JSONObject.NULL) {
      return null;
    }
    if (value instanceof JSONObject) {
      return jsonObjectToMap((JSONObject) value);
    }
    if (value instanceof JSONArray) {
      return jsonArrayToList((JSONArray) value);
    }
    return value;
  }
}
