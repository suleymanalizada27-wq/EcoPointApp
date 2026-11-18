package az.ecopoint.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.view.View
import android.widget.FrameLayout
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget: EP balance + streak. The Flutter app writes the texts
 * (home_widget plugin); this class only displays them. Resources are looked up
 * by name so it does not depend on the app's package name.
 *
 * EcoFriend: the mascot is a STATIC PNG here (RemoteViews cannot play animated
 * WebP/video). The mood is resolved at render time from values written by the
 * Flutter app (single source of truth, see widget_sync.dart): a recent
 * backend-confirmed event (excited / cheering / proud) wins, then >= 7 days of
 * inactivity -> sad, otherwise normal. Refresh = system AppWidget update
 * (30 min, so the scene follows the time of day; no WorkManager, no wake-locks) + whenever the app pushes new data.
 *
 * Five entries in the widget picker (2x1, 2x2, 3x2, 4x2, 4x4). The 2x2 one adapts
 * to its size; the others (subclasses below) always use their own layout.
 *
 * Safety net: every RemoteViews is test-inflated here (same class whitelist and
 * resources the launcher uses). If a layout cannot be inflated we fall back to
 * the simple 2x1 layout, so the user never sees "Can't load widget".
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
    }

    // Re-render when the user resizes the widget so the layout can switch.
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
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

        // ---- EcoFriend mood (static PNG) -------------------------------
        val now = System.currentTimeMillis()
        val efEvent = str("ef_event", "")
        val efUntil = str("ef_until", "0").toLongOrNull() ?: 0L
        val efLast = str("ef_last_active", "0").toLongOrNull() ?: 0L
        val mood = when {
            (efEvent == "excited" || efEvent == "cheering" || efEvent == "proud") &&
                efUntil > now -> efEvent
            efLast > 0L && now - efLast >= 7L * 24 * 3600 * 1000 -> "sad"
            else -> "normal"
        }
        val mascotId = rid("ep_widget_mascot", "id")
        if (mascotId != 0) {
            var res = rid("ecofriend_$mood", "drawable")
            if (res == 0) res = rid("ecofriend_normal", "drawable")
            if (res != 0) views.setImageViewResource(mascotId, res)
        }
        // Like Duolingo: on a calm day the mascot nudges you (morning / evening)
        // until you have opened the app today. No guilt wording, normal pose.
        val cal = java.util.Calendar.getInstance()
        val hour = cal.get(java.util.Calendar.HOUR_OF_DAY)
        val last = java.util.Calendar.getInstance().apply { timeInMillis = efLast }
        val activeToday = efLast > 0L &&
            last.get(java.util.Calendar.YEAR) == cal.get(java.util.Calendar.YEAR) &&
            last.get(java.util.Calendar.DAY_OF_YEAR) == cal.get(java.util.Calendar.DAY_OF_YEAR)
        // Time-of-day scene (like Duolingo): sunrise / day / sunset / night.
        val theme = when (hour) {
            in 5..9 -> "morning"
            in 10..15 -> "day"
            in 16..19 -> "evening"
            else -> "night"
        }
        run {
            val rootBg = rid("ep_widget_root", "id")
            val bgRes = rid("ep_widget_bg_$theme", "drawable")
            if (rootBg != 0 && bgRes != 0) views.setInt(rootBg, "setBackgroundResource", bgRes)
        }
        val nudge = when {
            mood != "normal" || activeToday -> ""
            hour in 5..11 -> str("ef_msg_morning", "")
            hour in 18..21 -> str("ef_msg_evening", "")
            else -> ""
        }
        val efMsg = when {
            nudge.isNotEmpty() -> nudge
            mood == "normal" && theme == "night" && str("ef_msg_night", "").isNotEmpty() -> str("ef_msg_night", "")
            else -> str("ef_msg_$mood", "")
        }
        setText("ep_widget_msg", efMsg)
        val isXl = layoutName == "ep_widget_xl"

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

        // Daily-goal bar (4x2 and 4x4): 10 chunky segments.
        val dailyText = str("daily_text", "")
        val dailyPct = (data.getString("daily_pct", "0") ?: "0").toIntOrNull() ?: 0
        val showBar = (isXl || layoutName == "ep_widget_l") && dailyText.isNotEmpty()
        vis("ep_widget_bar_row", showBar)
        setText("ep_widget_goal", dailyText)
        val filled = ((dailyPct + 5) / 10).coerceIn(0, 10)
        for (i in 0 until 10) vis("ep_widget_seg_$i", showBar && i < filled)

        if (isXl) {
            // Duolingo-style week row: orange tick = day with confirmed EP.
            val dots = str("week_dots", "0000000")
            for (i in 0 until 7) {
                val id = rid("ep_widget_day_$i", "id")
                if (id == 0) continue
                val on = i < dots.length && dots[i] == '1'
                val bg = rid(if (on) "ep_widget_day_on" else "ep_widget_day_off", "drawable")
                if (bg != 0) views.setInt(id, "setBackgroundResource", bg)
                views.setTextViewText(id, if (on) "✓" else "")
            }
            setText("ep_widget_week", str("week_text", ""))
            setText("ep_widget_level", str("level_text", ""))
            setText("ep_widget_impact", str("impact_text", ""))
            setText("ep_widget_btn_scan", str("lbl_scan", "Scan"))
            setText("ep_widget_btn_missions", str("lbl_missions", "Missions"))
            setText("ep_widget_btn_history", str("lbl_history", "History"))
        }

        val rootId = rid("ep_widget_root", "id")
        views.setContentDescription(rootId, "EcoPoint $num $unit" + (if (has) ", $streak" else "") + (if (efMsg.isNotEmpty()) ". EcoFriend: $efMsg" else ""))

        val launch = context.packageManager.getLaunchIntentForPackage(pkg)
        if (launch != null) {
            val pending = PendingIntent.getActivity(
                context, 0, launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(rootId, pending)
            if (isXl) {
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
                link("ep_widget_btn_missions", "missions", 12)
                link("ep_widget_btn_history", "history", 13)
            }
        }
        return views
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
