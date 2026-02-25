import 'dart:async';

class NoteTagMutationQueue {
  final Set<String> _inFlightAtomIds = <String>{};
  final Map<String, Future<void>> _queuedByAtomId = <String, Future<void>>{};

  bool hasPendingFor(String atomId) {
    return _inFlightAtomIds.contains(atomId) ||
        _queuedByAtomId.containsKey(atomId);
  }

  void beginInFlight(String atomId) {
    _inFlightAtomIds.add(atomId);
  }

  void endInFlight(String atomId) {
    _inFlightAtomIds.remove(atomId);
  }

  Future<bool> enqueue({
    required String atomId,
    required Future<bool> Function() mutation,
  }) {
    final previous = _queuedByAtomId[atomId] ?? Future<void>.value();
    final completer = Completer<bool>();
    late final Future<void> queued;
    queued = previous
        .catchError((_) {})
        .then((_) async {
          try {
            completer.complete(await mutation());
          } catch (error, stackTrace) {
            completer.completeError(error, stackTrace);
          }
        })
        .whenComplete(() {
          if (identical(_queuedByAtomId[atomId], queued)) {
            _queuedByAtomId.remove(atomId);
          }
        });
    _queuedByAtomId[atomId] = queued;
    return completer.future;
  }

  Future<void> waitForAtom(String atomId) async {
    while (true) {
      final queued = _queuedByAtomId[atomId];
      if (queued != null) {
        try {
          await queued;
        } catch (_) {}
        continue;
      }
      if (_inFlightAtomIds.contains(atomId)) {
        await Future<void>.delayed(const Duration(milliseconds: 12));
        continue;
      }
      return;
    }
  }

  Future<void> waitForAll() async {
    while (true) {
      final snapshot = _queuedByAtomId.values.toList();
      if (snapshot.isEmpty) {
        if (_inFlightAtomIds.isEmpty) {
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 12));
        continue;
      }
      await Future.wait(snapshot.map((future) => future.catchError((_) {})));
    }
  }

  void clearForAtom(String atomId) {
    _inFlightAtomIds.remove(atomId);
    _queuedByAtomId.remove(atomId);
  }

  void reset() {
    _inFlightAtomIds.clear();
    _queuedByAtomId.clear();
  }
}
