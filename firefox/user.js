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
user_pref("browser.sessionhistory.max_total_viewers", 2);  /* Limit back/forward cached pages in RAM (default -1 hoards up to 8 per tab) */
user_pref("browser.cache.memory.capacity", 262144);        /* Cap memory cache to 256MB */
user_pref("browser.tabs.unloadOnLowMemory", true);         /* Auto-discard background tabs when system memory is constrained */
user_pref("image.mem.discardable", true);                  /* Discard decoded images of inactive tabs */
user_pref("browser.sessionstore.interval", 60000);         /* Session write interval: 60s instead of 15s */
