package az.ecopoint.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget: EP balance + streak. The Flutter app writes the texts
 * (home_widget plugin); this class only displays them. Resources are looked up
 * by name so it does not depend on the app's package name.
 *
 * Four entries in the widget picker (2x1, 2x2, 3x2, 4x2). The 2x2 one adapts
 * to its size; the others (subclasses below) always use their own layout.
 * Layouts:
 *   2x1 (short)  -> ep_widget_xs   one row
 *   2x2 (narrow) -> ep_widget_s    stacked
 *   3x2          -> ep_widget      header, balance, progress
 *   4x2 and up   -> ep_widget_l    wide, everything at once
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
        val pkg = context.packageName
        fun rid(name: String, type: String): Int = context.resources.getIdentifier(name, type, pkg)

        val opts = manager.getAppWidgetOptions(widgetId)
        val w = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 180)
        val h = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)
        val layoutName = forcedLayout ?: when {
            h < 100 -> "ep_widget_xs"
            w < 170 -> "ep_widget_s"
            w < 250 -> "ep_widget"
            else -> "ep_widget_l"
        }

        val layoutId = rid(layoutName, "layout")
        if (layoutId == 0) return
        val views = RemoteViews(pkg, layoutId)

        fun str(key: String, def: String) = data.getString(key, def) ?: def
        fun setText(name: String, value: String) {
            val id = rid(name, "id")
            if (id != 0) views.setTextViewText(id, value)
        }

        val num = str("balance_num", "—")
        val unit = str("unit", "EP")
        val streak = str("streak", "")
        setText("ep_widget_label", str("label", "EcoPoint"))
        setText("ep_widget_balance", num)
        setText("ep_widget_unit", unit)
        setText("ep_widget_streak", streak)

        // Streak chip / panel and the progress row exist only when there is a streak.
        val has = streak.isNotEmpty()
        fun vis(name: String, show: Boolean) {
            val id = rid(name, "id")
            if (id != 0) views.setViewVisibility(id, if (show) View.VISIBLE else View.GONE)
        }
        vis("ep_widget_streak_chip", has)
        vis("ep_widget_panel", has)
        val pct = (data.getString("goal_pct", "0") ?: "0").toIntOrNull() ?: 0
        val goalText = str("goal_text", "")
        val progId = rid("ep_widget_progress", "id")
        if (progId != 0) {
            views.setProgressBar(progId, 100, pct.coerceIn(0, 100), false)
            views.setViewVisibility(progId, if (has) View.VISIBLE else View.GONE)
        }
        setText("ep_widget_goal", goalText)
        vis("ep_widget_goal", goalText.isNotEmpty())
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
        manager.updateAppWidget(widgetId, views)
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
