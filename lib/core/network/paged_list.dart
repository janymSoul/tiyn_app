import 'package:tiyn_app/core/network/api_client.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/network/json.dart';

/// Page size asked of the backend. ADR-0002 caps `limit` at 100.
const pageLimit = 100;

/// Hard stop for [PagedListReader.readAll]: 20 x 100 rows is far beyond what
/// today's lists hold (caps of 100-200), so reaching it means a loop or a
/// runaway list, not a real user.
const maxPages = 20;

class PagedListReader {
  const PagedListReader(this._api);

  final ApiClient _api;

  /// Reads every page of a list endpoint and returns all items.
  ///
  /// Works against both response shapes (ADR-0002 cutover): a bare array is a
  /// single page; `{items, nextCursor}` is followed until `nextCursor` is
  /// absent. The same [query] filters go on every page request. A 422
  /// `invalid_cursor` restarts the walk from the first page once; a second one
  /// is rethrown. More than [maxPages] pages is `too_many_pages`.
  Future<List<T>> readAll<T>(
    String path, {
    Map<String, Object?> query = const {},
    required T Function(Object? json) decodeItem,
  }) async {
    var restarted = false;
    while (true) {
      try {
        return await _walk(path, query, decodeItem);
      } on ApiException catch (e) {
        if (e.code != 'invalid_cursor' || restarted) rethrow;
        restarted = true;
      }
    }
  }

  Future<List<T>> _walk<T>(
    String path,
    Map<String, Object?> query,
    T Function(Object? json) decodeItem,
  ) async {
    final items = <T>[];
    String? cursor;
    for (var page = 0; page < maxPages; page++) {
      final result = await _api.get(
        path,
        query: {...query, 'limit': pageLimit, 'cursor': ?cursor},
        decode: (json) => _decodePage(json, decodeItem),
      );
      items.addAll(result.items);
      cursor = result.nextCursor;
      if (cursor == null) return items;
    }
    throw const ApiException(code: 'too_many_pages');
  }
}

typedef _Page<T> = ({List<T> items, String? nextCursor});

_Page<T> _decodePage<T>(Object? json, T Function(Object? json) decodeItem) {
  if (json is List<Object?>) {
    return (items: json.map(decodeItem).toList(), nextCursor: null);
  }
  final map = asMap(json);
  final cursor = optString(map, 'nextCursor');
  if (cursor != null && cursor.isEmpty) {
    throw const ApiException(code: 'invalid_response');
  }
  return (
    items: asList(map['items']).map(decodeItem).toList(),
    nextCursor: cursor,
  );
}
