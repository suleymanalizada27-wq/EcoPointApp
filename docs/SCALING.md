# Load and scaling plan

| Layer | Today (free) | Limit / risk | Next step |
|---|---|---|---|
| Render web service | Free plan, sleeps after ~15 min idle; UptimeRobot pings `/health` every 5 min | Cold start 30–60 s if the ping fails; ~750 instance-hours/month; single instance, in-process scheduler | Paid Starter instance (no sleep). Keep exactly **one** instance while the scheduler runs in-process (markers prevent double sends, but more instances = more load on RTDB) |
| Realtime Database (Spark) | 1 GB stored, 10 GB/month download, 100 simultaneous connections | 100 concurrent connections is the first wall; the leaderboards use indexed limited queries | Blaze plan (pay as you go, higher limits) or sharding; watch usage in Firebase console |
| FCM | Free | Dead tokens are pruned automatically | — |
| Backend logic | All money changes are server-side atomic transactions | Hot nodes (`leaderboard`) read by every client | Keep queries `limitToLast(20)`; cache if needed |

Early-warning signs: admin overview shows rising `errors24h`; Render logs show restarts; RTDB usage tab near 80 %.
Load testing has **not** been done; the numbers above are plan limits, not measured capacity.
