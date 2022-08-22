import 'configuration.dart';
import 'match.dart';
import 'path_utils.dart';

/// Converts a location into a list of [RouteMatch] objects.
class RouteMatcher {
  /// [RouteMatcher] constructor.
  RouteMatcher(this.configuration);

  /// The route configuration.
  final RouteConfiguration configuration;

  /// Finds the routes that matched the given URL.
  RouteMatchList findMatch(String location, {Object? extra}) {
    final String canonicalLocation = canonicalUri(location);
    final List<RouteMatch> matches =
        _getLocRouteMatches(canonicalLocation, extra);
    return RouteMatchList(matches);
  }

  List<RouteMatch> _getLocRouteMatches(String location, Object? extra) {
    final Uri uri = Uri.parse(location);
    final List<RouteMatch> result = _getLocRouteRecursively(
      loc: uri.path,
      restLoc: uri.path,
      routes: configuration.routes,
      parentFullpath: '',
      parentSubloc: '',
      queryParams: uri.queryParameters,
      extra: extra,
    );

    if (result.isEmpty) {
      throw MatcherError('no routes for location', location);
    }

    return result;
  }
}

/// The list of [RouteMatch] objects.
class RouteMatchList {
  /// RouteMatchList constructor.
  RouteMatchList(this._matches);

  /// Constructs an empty matches object.
  factory RouteMatchList.empty() => RouteMatchList(<RouteMatch>[]);

  final List<RouteMatch> _matches;

  /// Returns true if there are no matches.
  bool get isEmpty => _matches.isEmpty;

  /// Returns true if there are matches.
  bool get isNotEmpty => _matches.isNotEmpty;

  /// The original URL that was matched.
  Uri get location =>
      _matches.isEmpty ? Uri() : Uri.parse(_matches.last.fullUriString);

  /// Pushes a match onto the list of matches.
  void push(RouteMatch match) {
    _matches.add(match);
  }

  /// Removes the last match.
  void pop() {
    _matches.removeLast();
    assert(
        _matches.isNotEmpty,
        'You have popped the last page off of the stack,'
        ' there are no pages left to show');
  }

  /// Returns true if [pop] can safely be called.
  bool canPop() {
    return _matches.length > 1;
  }

  /// An optional object provided by the app during navigation.
  Object? get extra => _matches.last.extra;

  /// The last matching route.
  RouteMatch get last => _matches.last;

  /// The route matches.
  List<RouteMatch> get matches => _matches;

  /// Returns true if the current match intends to display an error screen.
  bool get isError => matches.length == 1 && matches.first.error != null;

  /// Returns the error that this match intends to display.
  Exception? get error => matches.first.error;
}

/// An error that occurred during matching.
class MatcherError extends Error {
  /// Constructs a [MatcherError].
  MatcherError(String message, this.location)
      : message = message + ': $location';

  /// The error message.
  final String message;

  /// The location that failed to match.
  final String location;

  @override
  String toString() {
    return message;
  }
}

List<RouteMatch> _getLocRouteRecursively({
  required String loc,
  required String restLoc,
  required String parentSubloc,
  required List<GoRoute> routes,
  required String parentFullpath,
  required Map<String, String> queryParams,
  required Object? extra,
}) {
  bool debugGatherAllMatches = false;
  assert(() {
    debugGatherAllMatches = true;
    return true;
  }());
  final List<List<RouteMatch>> result = <List<RouteMatch>>[];
  // find the set of matches at this level of the tree
  for (final GoRoute route in routes) {
    final String fullpath = concatenatePaths(parentFullpath, route.path);
    final RouteMatch? match = RouteMatch.match(
      route: route,
      restLoc: restLoc,
      parentSubloc: parentSubloc,
      fullpath: fullpath,
      queryParams: queryParams,
      extra: extra,
    );

    if (match == null) {
      continue;
    }
    if (match.subloc.toLowerCase() == loc.toLowerCase()) {
      // If it is a complete match, then return the matched route
      // NOTE: need a lower case match because subloc is canonicalized to match
      // the path case whereas the location can be of any case and still match
      result.add(<RouteMatch>[match]);
    } else if (route.routes.isEmpty) {
      // If it is partial match but no sub-routes, bail.
      continue;
    } else {
      // Otherwise, recurse
      final String childRestLoc =
          loc.substring(match.subloc.length + (match.subloc == '/' ? 0 : 1));
      assert(loc.startsWith(match.subloc));
      assert(restLoc.isNotEmpty);

      final List<RouteMatch> subRouteMatch = _getLocRouteRecursively(
        loc: loc,
        restLoc: childRestLoc,
        parentSubloc: match.subloc,
        routes: route.routes,
        parentFullpath: fullpath,
        queryParams: queryParams,
        extra: extra,
      ).toList();

      // If there's no sub-route matches, there is no match for this location
      if (subRouteMatch.isEmpty) {
        continue;
      }
      result.add(<RouteMatch>[match, ...subRouteMatch]);
    }
    // Should only reach here if there is a match.
    if (debugGatherAllMatches) {
      continue;
    } else {
      break;
    }
  }

  if (result.isEmpty) {
    return <RouteMatch>[];
  }

  // If there are multiple routes that match the location, returning the first one.
  // To make predefined routes to take precedence over dynamic routes eg. '/:id'
  // consider adding the dynamic route at the end of the routes
  return result.first;
}
