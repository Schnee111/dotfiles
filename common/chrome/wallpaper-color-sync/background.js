// Wallpaper Color Sync
//
// Chrome has no chrome.theme API, so the live-sync mechanism is:
//   1. The native host (wallpaper-color-host) watches the matugen palette and
//      rewrites THIS extension's manifest.json "theme" colors when it changes.
//   2. The host then pings us with {type: "reload"}.
//   3. We call chrome.runtime.reload(), Chrome re-reads the manifest and
//      repaints the frame/toolbar/tabs with the new theme colors.
//
// The native port also keeps this service worker alive.

const HOST = "com.schnee.wallpaper_color";
let port = null;

function connect() {
  if (port) return;
  try {
    port = chrome.runtime.connectNative(HOST);
  } catch (e) {
    port = null;
    setTimeout(connect, 5000);
    return;
  }
  console.log("WCS v2 connected to host");
  port.onMessage.addListener((msg) => {
    if (!msg) return;
    if (msg.type === "reload") {
      console.log("WCS v2 reload requested (" + (msg.reason || "?") + ")");
      chrome.runtime.reload();
    }
  });
  port.onDisconnect.addListener(() => {
    port = null;
    setTimeout(connect, 5000);
  });
}

chrome.alarms.create("wcs-reconnect", { periodInMinutes: 1 });
chrome.alarms.onAlarm.addListener((a) => {
  if (a.name === "wcs-reconnect" && !port) connect();
});
chrome.runtime.onStartup.addListener(connect);
chrome.runtime.onInstalled.addListener(connect);
connect();
console.log("WCS v2 start");
