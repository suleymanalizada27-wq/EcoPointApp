package az.ecopoint.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
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
 * Four entries in the widget picker (2x1, 2x2, 3x2, 4x2). The 2x2 one adapts
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

        val num = str("balance_num", "—")
        val unit = str("unit", "EP")
        val streak = str("streak", "")
        val goalText = str("goal_text", "")
        val pct = (data.getString("goal_pct", "0") ?: "0").toIntOrNull() ?: 0
        val has = streak.isNotEmpty()
        val motto = str("motto", "")
        val tier = (data.getString("tier", "0") ?: "0").toIntOrNull() ?: 0
        // Small layouts show the motivational line in place of the brand label.
        val mottoInLabel = layoutName == "ep_widget_xs" || layoutName == "ep_widget_s"
        setText("ep_widget_label", if (has && mottoInLabel && motto.isNotEmpty()) motto else str("label", "EcoPoint"))
        setText("ep_widget_motto", motto)
        vis("ep_widget_motto", has && !mottoInLabel && motto.isNotEmpty())
        // Flame changes with the streak: lime -> amber -> orange -> gold star.
        val flameId = rid("ep_widget_flame", "id")
        if (flameId != 0 && has) {
            val res = rid(if (tier <= 0) "ep_widget_flame" else "ep_widget_flame_$tier", "drawable")
            if (res != 0) views.setImageViewResource(flameId, res)
        }
        setText("ep_widget_balance", num)
        setText("ep_widget_unit", unit)
        setText("ep_widget_streak", streak)
        setText("ep_widget_goal", goalText)

        // Streak chip / panel / progress exist only when there is a streak.
        vis("ep_widget_streak_chip", has)
        vis("ep_widget_panel", has)
        vis("ep_widget_bar_row", has)
        // Segmented progress bar: 10 segments, filled ones are shown.
        val filled = ((pct + 5) / 10).coerceIn(0, 10)
        for (i in 0 until 10) vis("ep_widget_seg_$i", has && i < filled)

        val rootId = rid("ep_widget_root", "id")
        views.setContentDescription(rootId, "EcoPoint $num $unit" + if (has) ", $streak" else "")

        val launch = context.packageManager.getLaunchIntentForPackage(pkg)
        if (launch != null) {
            val pending = PendingIntent.getActivity(
                context, 0, launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(rootId, pending)
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
