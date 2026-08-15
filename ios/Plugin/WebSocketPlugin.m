#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

// Define the plugin using the CAP_PLUGIN Macro, and
// each method the plugin supports using the CAP_PLUGIN_METHOD macro.
CAP_PLUGIN(WebSocketPlugin, "WebSocket",
           CAP_PLUGIN_METHOD(connect, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(close, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(send, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(onOpen, CAPPluginReturnCallback);
           CAP_PLUGIN_METHOD(onMessage, CAPPluginReturnCallback);
           CAP_PLUGIN_METHOD(onClose, CAPPluginReturnCallback);
           CAP_PLUGIN_METHOD(onError, CAPPluginReturnCallback);
)
