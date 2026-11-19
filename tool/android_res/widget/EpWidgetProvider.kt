package az.ecopoint.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.view.View
import android.widget.FrameLayout
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar

/**
 * EcoPoint home-screen widgets (EcoFriend 2.0).
 *
 * Data: the Flutter app writes ready-to-show texts (home_widget plugin, see
 * widget_sync.dart); real user data only, backend stays the source of truth.
 * This class only DISPLAYS them and picks, at render time, the parts that
 * depend on the clock — so the widget stays right while the app is closed:
 *
 *  - scene (sky art): morning 05-09 / day 10-15 / evening 16-19 / night 20-04
 *  - EcoFriend variant: event (excited / cheering / proud, backend-confirmed and
 *    time-limited) > sad (>= 7 days away, gentle) > the scene's own pose
 *    (sleepy Zzz at night, sunrise sparkle in the morning ...)
 *  - message: rotates every 3 h through the pre-translated pool the app wrote
 *    (`ef_pool_<scene>`); adjacent slots never repeat
 *  - tone: dark glass panels at night, white panels otherwise
 *
 * RemoteViews cannot play animations, so EcoFriend is a static PNG here.
 *
 * Refresh (battery friendly): NO polling. One inexact alarm
 * (setAndAllowWhileIdle, needs no permission) is armed for the next scene /
 * message boundary (<= 12 per day) and re-armed after each tick; the system
 * `updatePeriodMillis` (3 h) is only a safety net; the app pushes data
 * whenever balance / goal / streak change.
 *
 * Safety net: every RemoteViews is test-inflated; if a layout cannot be
 * inflated we fall back to the simple 2x1 layout ("Can't load widget" never
 * shows). Missing ids in a layout are skipped silently by RemoteViews.
 */
open class EpWidgetProvider : HomeWidgetProvider() {

    /** Layout name to always use; null = pick by the widget's current size. */
    protected open val forcedLayout: String? = null

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (id in appWidgetIds) render(context, appWidgetManager, id, widgetData)
        scheduleNextTick(context)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        scheduleNextTick(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        if (!anyWidgets(context)) cancelTick(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_TICK) {
            try {
                val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                val mgr = AppWidgetManager.getInstance(context)
                for (p in allProviders()) {
                    val ids = mgr.getAppWidgetIds(ComponentName(context, p.javaClass))
                    for (id in ids) p.render(context, mgr, id, prefs)
                }
                scheduleNextTick(context)
            } catch (e: Exception) {
                // never crash the process because of a widget
            }
            return
        }
        super.onReceive(context, intent)
    }

    // Re-render when the user resizes the widget so the layout can switch.
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        render(context, appWidgetManager, appWidgetId, prefs)
    }

    private fun render(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        data: SharedPreferences
    ) {
        try {
            val opts = manager.getAppWidgetOptions(widgetId)
            val w = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 180)
            val h = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)
            val layoutName = forcedLayout ?: when {
                h < 100 -> "ep_widget_xs"
                w < 170 -> "ep_widget_s"
                w < 250 -> "ep_widget"
                else -> "ep_widget_l"
            }
            var views = build(context, layoutName, data)
            if (views == null || !inflates(context, views)) {
                views = build(context, "ep_widget_xs", data)
            }
            if (views != null) manager.updateAppWidget(widgetId, views)
        } catch (e: Exception) {
            // Never let a widget problem crash the app process.
        }
    }

    /** True when the views can be inflated here (catches bad classes/resources). */
    private fun inflates(context: Context, views: RemoteViews): Boolean = try {
        views.apply(context, FrameLayout(context))
        true
    } catch (e: Exception) {
        false
    }

    private fun build(context: Context, layoutName: String, data: SharedPreferences): RemoteViews? {
        val pkg = context.packageName
        fun rid(name: String, type: String): Int = context.resources.getIdentifier(name, type, pkg)

        val layoutId = rid(layoutName, "layout")
        if (layoutId == 0) return null
        val views = RemoteViews(pkg, layoutId)

        fun str(key: String, def: String) = data.getString(key, def) ?: def
        fun setText(name: String, value: String) {
            val id = rid(name, "id")
            if (id != 0) views.setTextViewText(id, value)
        }
        fun vis(name: String, show: Boolean) {
            val id = rid(name, "id")
            if (id != 0) views.setViewVisibility(id, if (show) View.VISIBLE else View.GONE)
        }
        fun color(name: String, argb: Int) {
            val id = rid(name, "id")
            if (id != 0) views.setTextColor(id, argb)
        }

        val isXl = layoutName == "ep_widget_xl"
        val isL = layoutName == "ep_widget_l"
        val isS = layoutName == "ep_widget_s"

        // ---- clock ---------------------------------------------------------
        val now = System.currentTimeMillis()
        val cal = Calendar.getInstance()
        val hour = cal.get(Calendar.HOUR_OF_DAY)
        val scene = sceneFor(hour)
        val night = scene == "night"
        val todayKey = dayKey(cal)

        // ---- EcoFriend mood ------------------------------------------------
        val efEvent = str("ef_event", "")
        val efUntil = str("ef_until", "0").toLongOrNull() ?: 0L
        val efLast = str("ef_last_active", "0").toLongOrNull() ?: 0L
        val mood = when {
            (efEvent == "excited" || efEvent == "cheering" || efEvent == "proud") &&
                efUntil > now -> efEvent
            efLast > 0L && now - efLast >= 7L * 24 * 3600 * 1000 -> "sad"
            else -> "calm"
        }
        val last = Calendar.getInstance().apply { timeInMillis = efLast }
        val activeToday = efLast > 0L && dayKey(last) == todayKey

        // mascot variant: event / sad / the scene's own pose
        val variant = if (mood == "calm") scene else mood
        val mascotId = rid("ep_widget_mascot", "id")
        if (mascotId != 0) {
            var res = rid("ecofriend_w_$variant", "drawable")
            if (res == 0) res = rid("ecofriend_" + (if (mood == "calm") "normal" else mood), "drawable")
            if (res == 0) res = rid("ecofriend_normal", "drawable")
            if (res != 0) views.setImageViewResource(mascotId, res)
        }

        // ---- scene art -------------------------------------------------------
        val wide = !(isXl || isS)
        val bgImg = rid("ep_widget_bgimg", "id")
        val artRes = rid("ep_w_bg_${scene}_" + (if (wide) "wide" else "sq"), "drawable")
        if (bgImg != 0 && artRes != 0) {
            views.setImageViewResource(bgImg, artRes)
        } else {
            val rootBg = rid("ep_widget_root", "id")
            val bgRes = rid("ep_widget_bg_$scene", "drawable")
            if (rootBg != 0 && bgRes != 0) views.setInt(rootBg, "setBackgroundResource", bgRes)
        }

        // ---- tone (panel style + text colours) -----------------------------
        val ink = if (night) 0xFFFFFFFF.toInt() else 0xFF1F3D12.toInt()
        val sub = if (night) 0xFFC9D8F0.toInt() else 0xFF5B7A45.toInt()
        val accent = if (night) 0xFFD9FF6B.toInt() else 0xFF2E8B3A.toInt()
        val panelRes = rid(if (night) "ep_w_panel_dark" else "ep_w_panel_light", "drawable")
        for (p in listOf("ep_w_p1", "ep_w_p2")) {
            val id = rid(p, "id")
            if (id != 0 && panelRes != 0) views.setInt(id, "setBackgroundResource", panelRes)
        }
        color("ep_widget_balance", ink)
        color("ep_widget_unit", accent)
        color("ep_widget_label", sub)
        color("ep_widget_level", accent)
        color("ep_widget_week", sub)
        color("ep_widget_impact", sub)
        color("ep_widget_goal_label", ink)
        if (isXl) color("ep_widget_goal", ink)

        // ---- message ---------------------------------------------------------
        val daily = str("daily_text", "")
        val total = daily.substringAfter('/', "").toIntOrNull() ?: 0
        val stale = str("daily_day", "") != todayKey // yesterday's goal is not today's
        val streakN = (data.getString("streak", "") ?: "").toIntOrNull() ?: 0
        val slot = cal.get(Calendar.DAY_OF_YEAR) * 8 + hour / 3
        fun pick(pool: List<String>): String =
            if (pool.isEmpty()) "" else pool[slot % pool.size]
        fun pool(key: String): List<String> =
            str(key, "").split('\u001F').filter { it.isNotEmpty() }

        val efMsg = when {
            mood == "excited" || mood == "cheering" || mood == "proud" -> str("ef_msg_$mood", "")
            mood == "sad" -> str("ef_msg_sad", "")
            streakN > 0 && !activeToday && hour in 16..21 && slot % 2 == 0 &&
                pool("ef_pool_risk").isNotEmpty() -> pick(pool("ef_pool_risk"))
            else -> {
                val p = if (stale) pool("ef_pool_${scene}_base") else pool("ef_pool_$scene")
                pick(p).ifEmpty {
                    str("ef_msg_" + (if (night) "night" else "normal"), "")
                }
            }
        }
        setText("ep_widget_msg", efMsg)

        // ---- numbers ---------------------------------------------------------
        val num = str("balance_num", "—")
        val unit = str("unit", "EP")
        val streak = str("streak", "")
        val has = streak.isNotEmpty()
        val tier = (data.getString("tier", "0") ?: "0").toIntOrNull() ?: 0
        setText("ep_widget_label", str("label", "EcoPoint"))
        // Flame changes with the streak: lime -> amber -> orange -> gold star.
        val flameId = rid("ep_widget_flame", "id")
        if (flameId != 0 && has) {
            val res = rid(if (tier <= 0) "ep_widget_flame" else "ep_widget_flame_$tier", "drawable")
            if (res != 0) views.setImageViewResource(flameId, res)
        }
        setText("ep_widget_balance", num)
        setText("ep_widget_unit", unit)
        setText("ep_widget_streak", streak)
        vis("ep_widget_streak_chip", has)

        // ---- daily goal (4x4, 4x2, 2x2) --------------------------------------
        val dailyPct = if (stale) 0 else (data.getString("daily_pct", "0") ?: "0").toIntOrNull() ?: 0
        val dailyShown = if (stale && total > 0) "0/$total" else daily
        val showBar = (isXl || isL || isS) && daily.isNotEmpty()
        vis("ep_widget_bar_row", showBar)
        vis("ep_w_p2", daily.isNotEmpty())
        setText("ep_widget_goal", dailyShown)
        setText("ep_widget_goal_label", str("goal_label", ""))
        val filled = ((dailyPct + 5) / 10).coerceIn(0, 10)
        for (i in 0 until 10) vis("ep_widget_seg_$i", showBar && i < filled)

        if (isXl) {
            // Week row: orange coin = a day with confirmed EP.
            val dots = str("week_dots", "0000000")
            for (i in 0 until 7) {
                val id = rid("ep_widget_day_$i", "id")
                if (id == 0) continue
                val on = i < dots.length && dots[i] == '1'
                val bg = rid(if (on) "ep_widget_day_on" else "ep_widget_day_off", "drawable")
                if (bg != 0) views.setInt(id, "setBackgroundResource", bg)
            }
            setText("ep_widget_week", str("week_text", ""))
            setText("ep_widget_level", str("level_text", ""))
            setText("ep_widget_impact", str("impact_text", ""))
            setText("ep_widget_btn_missions", str("lbl_missions", "Missions"))
            setText("ep_widget_btn_history", str("lbl_history", "History"))
        }
        if (isXl || isL) setText("ep_widget_btn_scan", str("lbl_scan", "Scan"))

        val rootId = rid("ep_widget_root", "id")
        views.setContentDescription(
            rootId,
            "EcoPoint $num $unit" + (if (has) ", $streak" else "") +
                (if (efMsg.isNotEmpty()) ". EcoFriend: $efMsg" else "")
        )

        val launch = context.packageManager.getLaunchIntentForPackage(pkg)
        if (launch != null) {
            val pending = PendingIntent.getActivity(
                context, 0, launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(rootId, pending)
            if (isXl || isL) {
                // Reuses the app's existing quick_actions handler (ShortcutsHost):
                // same intent a launcher shortcut sends. Unknown type => just opens the app.
                fun link(viewName: String, type: String, code: Int) {
                    val vid = rid(viewName, "id")
                    if (vid == 0) return
                    val i = Intent(launch).apply {
                        action = Intent.ACTION_RUN
                        putExtra("some unique action key", type)
                    }
                    views.setOnClickPendingIntent(
                        vid,
                        PendingIntent.getActivity(
                            context, code, i,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                    )
                }
                link("ep_widget_btn_scan", "scan", 11)
                if (isXl) {
                    link("ep_widget_btn_missions", "missions", 12)
                    link("ep_widget_btn_history", "history", 13)
                }
            }
        }
        return views
    }

    companion object {
        const val PREFS = "HomeWidgetPreferences"
        const val ACTION_TICK = "az.ecopoint.widget.TICK"

        /** Hours at which the scene (05/10/16/20) or the message slot (every 3 h) changes. */
        private val BOUNDARIES = intArrayOf(0, 3, 5, 6, 9, 10, 12, 15, 16, 18, 20, 21)

        fun sceneFor(hour: Int): String = when (hour) {
            in 5..9 -> "morning"
            in 10..15 -> "day"
            in 16..19 -> "evening"
            else -> "night"
        }

        fun dayKey(c: Calendar): String =
            "%04d%02d%02d".format(c.get(Calendar.YEAR), c.get(Calendar.MONTH) + 1, c.get(Calendar.DAY_OF_MONTH))

        private fun allProviders(): List<EpWidgetProvider> = listOf(
            EpWidgetXsProvider(), EpWidgetProvider(), EpWidgetMProvider(),
            EpWidgetLProvider(), EpWidgetXlProvider()
        )

        private fun anyWidgets(context: Context): Boolean {
            val mgr = AppWidgetManager.getInstance(context)
            return allProviders().any {
                mgr.getAppWidgetIds(ComponentName(context, it.javaClass)).isNotEmpty()
            }
        }

        private fun tickIntent(context: Context): PendingIntent {
            val i = Intent(context, EpWidgetProvider::class.java).apply { action = ACTION_TICK }
            return PendingIntent.getBroadcast(
                context, 77, i, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        /** One inexact alarm for the next boundary. No permission, no wake-lock loop. */
        fun scheduleNextTick(context: Context) {
            try {
                val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                val c = Calendar.getInstance()
                val h = c.get(Calendar.HOUR_OF_DAY)
                val next = BOUNDARIES.firstOrNull { it > h }
                val t = Calendar.getInstance().apply {
                    set(Calendar.MINUTE, 0); set(Calendar.SECOND, 5); set(Calendar.MILLISECOND, 0)
                    if (next == null) { add(Calendar.DAY_OF_YEAR, 1); set(Calendar.HOUR_OF_DAY, BOUNDARIES[0]) }
                    else set(Calendar.HOUR_OF_DAY, next)
                }
                am.setAndAllowWhileIdle(AlarmManager.RTC, t.timeInMillis, tickIntent(context))
            } catch (e: Exception) {
                // the 3 h system update still refreshes the widget
            }
        }

        fun cancelTick(context: Context) {
            try {
                (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(tickIntent(context))
            } catch (e: Exception) {
            }
        }
    }
}

/** 2x1 */
class EpWidgetXsProvider : EpWidgetProvider() {
    override val forcedLayout: String? = "ep_widget_xs"
}

/** 3x2 */
class EpWidgetMProvider : EpWidgetProvider() {
    override val forcedLayout: String? = "ep_widget"
}

/** 4x2 */
class EpWidgetLProvider : EpWidgetProvider() {
    override val forcedLayout: String? = "ep_widget_l"
}

/** 4x4 */
class EpWidgetXlProvider : EpWidgetProvider() {
    override val forcedLayout: String? = "ep_widget_xl"
}
