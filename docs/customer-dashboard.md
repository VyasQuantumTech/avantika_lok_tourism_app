# Customer dashboard and favourites

The home repository now uses `HomeRemoteDataSource` and authenticated `GET /api/v1/dashboard`. The bundled demo home JSON is no longer a runtime data source. Existing data-source/repository/use-case layers and dependency injection remain in use. Section cards open existing pooja, accommodation, transport and destination detail flows. Packages have a real public detail view through the same data/domain boundary.

The dashboard renders place, accommodation, pooja, transport, package, feed, update and event sections, including genuine empty states. Pull to refresh reloads the dashboard. See All uses authenticated `/api/v1/dashboard/sections/:type?page=...&limit=20`; pagination follows server totals. Public media paths resolve against the configured API origin, and missing/broken images use placeholders.

Favourites use the existing authenticated `/api/v1/profile/me/favorites` endpoints. A shared presentation controller loads owned saved items and updates hearts after successful server writes. Pooja, accommodation, transport, package and place categories are separate tabs. Saved items that are no longer public remain removable. New customer shells reset controller state and ignore earlier-session responses. Failed writes preserve selections and permit retry.

Apply the backend dashboard-content migration before running the updated API, then rebuild/restart the customer app using its existing flavour/environment configuration. No URLs or credentials were changed. Real feeds, updates and events require published administrator content; no sample records are inserted.

Validation on 14 October 2026: all 82 Flutter tests passed; analysis of changed features and tests was clean. No emulator/device run or remote backend deployment was performed.
