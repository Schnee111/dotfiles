user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("browser.tabs.drawInTitlebar", true);
user_pref("browser.uidensity", 0);
user_pref("layers.acceleration.force-enabled", true);
user_pref("mozilla.widget.use-argb-visuals", true);
user_pref("widget.gtk.rounded-bottom-corners.enabled", true);
user_pref("svg.context-properties.content.enabled", true);
user_pref("browser.startup.homepage", "about:home");
user_pref("browser.startup.page", 3); /* 3 = Restore previous session & tabs automatically */
user_pref("browser.sessionstore.resume_from_crash", true);
user_pref("browser.newtabpage.enabled", true);

/* Native Vertical Tabs & Tab Groups (Styled to match Chrome) */
user_pref("browser.tabs.groups.enabled", true);
user_pref("browser.tabs.groups.hoverPreview.enabled", true);
user_pref("browser.tabs.groups.smart.enabled", true);
user_pref("sidebar.revamp", true);
user_pref("sidebar.verticalTabs", true);

/* Memory & Performance Tuning */
user_pref("browser.tabs.unloadOnLowMemory", true);         /* Auto-discard background tabs when system memory is constrained */
user_pref("browser.sessionstore.interval", 60000);         /* Session write interval: 60s instead of 15s to reduce disk I/O */

/* GPU Video Decode (Intel Iris Xe + VA-API present) */
user_pref("media.hardware-video-decoding.force-enabled", true);

/* Smooth Scroll (Chrome-like feel: longer stride + momentum) */
user_pref("mousewheel.min_line_scroll_amount", 25);
user_pref("apz.gtk.kinetic_scroll.enabled", true);
user_pref("general.smoothScroll.mouseWheel.durationMaxMS", 150);
