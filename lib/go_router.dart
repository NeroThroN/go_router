/// A declarative router for Flutter based on Navigation 2 supporting
/// deep linking, data-driven routes and more.
library go_router;

export 'src/configuration.dart' show GoRouterState, GoRoute;
export 'src/misc/extensions.dart';
export 'src/misc/inherited_router.dart';
export 'src/misc/refresh_stream.dart';
export 'src/pages/custom_transition_page.dart';
export 'src/platform.dart' show UrlPathStrategy;
export 'src/route_data.dart' show GoRouteData, TypedGoRoute;
export 'src/router.dart';
export 'src/typedefs.dart' show GoRouterPageBuilder, GoRouterRedirect;
