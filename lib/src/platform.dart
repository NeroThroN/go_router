// TODO(johnpryan): Remove this API
export 'platform/path_strategy_nonweb.dart'
    if (dart.library.html) 'platform/path_strategy_web.dart';
export 'platform/url_path_strategy.dart';
