import 'dart:async';

class _Timer implements Timer {
  final Timer delegate;
  final Disposable _handler;
  final Symbol? id;

  @override
  bool get isActive => delegate.isActive;

  @override
  int get tick => delegate.tick;

  void _rem() {
    if (id == null) {
      _handler._timers.remove(this);
    } else {
      _handler._uniqueTimers.remove(id);
    }
  }

  @override
  void cancel() {
    delegate.cancel();

    _rem();
  }

  _Timer(this._handler, this.delegate, this.id);
}

class _StreamSubscription<T> implements StreamSubscription<T> {
  final StreamSubscription<T> _delegate;
  final void Function() _cancel;

  @override
  Future<void> cancel() {
    _cancel();
    return _delegate.cancel();
  }

  @override
  void onData(void Function(T)? handleData) => _delegate.onData(handleData);

  @override
  void onError(Function? handleError) => _delegate.onError(handleError);

  @override
  void onDone(void Function()? handleDone) => _delegate.onDone(handleDone);

  @override
  void pause([Future<void>? resumeSignal]) => _delegate.pause(resumeSignal);

  @override
  void resume() => _delegate.resume();

  @override
  bool get isPaused => _delegate.isPaused;

  @override
  Future<E> asFuture<E>([E? futureValue]) => _delegate.asFuture(futureValue);

  _StreamSubscription(this._delegate, this._cancel);
}

abstract class Disposable {
  final _subs = <StreamSubscription>{};
  final _uniqueSubs = <Symbol, StreamSubscription>{};
  final _ctrls = <StreamController>{};
  final _timers = <_Timer>{};
  final _uniqueTimers = <Symbol, _Timer>{};

  /**
   * Listens and iterates through [stream] by calling [fn].
   * The listener is disposed in the [dispose] function.
   *
   * If you add a [uniqueId], it means that whenever you call [each],
   * we will make sure that clear any listener with the same [uniqueId].
   */
  StreamSubscription<T> each<T extends Object>(Stream<T> stream,
      void Function(T item) fn,
      {Symbol? uniqueId}) {
    late StreamSubscription<T> ret;

    if (uniqueId == null) {
      ret = _StreamSubscription(stream.listen(fn),
              () => _subs.remove(ret));
      _subs.add(ret);
    } else {
      ret = _StreamSubscription(stream.listen(fn),
              () => _uniqueSubs.remove(uniqueId));

      _uniqueSubs[uniqueId]?.cancel();

      _uniqueSubs[uniqueId] = ret;
    }

    return ret;
  }

  StreamController<T> controller<T extends Object>({bool broadcast = false}) {
    StreamController<T> ret;

    if (broadcast) {
      ret = StreamController<T>.broadcast();
    } else {
      ret = StreamController<T>();
    }

    _ctrls.add(ret);

    ret.onCancel = () {
      _ctrls.remove(ret);
    };

    return ret;
  }

  Future<void> dispose() => cancelBindings();

  Future<void> cancelBindings() async {
    for (final s in _subs.toList()) {
      await s.cancel();
    }
    assert(_subs.isEmpty);

    for (final s in _uniqueSubs.values.toList()) {
      await s.cancel();
    }
    assert(_uniqueSubs.isEmpty);

    for (final c in _ctrls.toList()) {
      await c.close();
    }
    assert(_ctrls.isEmpty);

    for (final t in _timers.toList()) {
      t.cancel();
    }
    assert(_timers.isEmpty);

    for (final t in _uniqueTimers.values.toList()) {
      t.cancel();
    }
    assert(_uniqueTimers.isEmpty);
  }

  Timer timer(Duration duration, Function() fn,
      {Symbol? unique}) {
    late _Timer ret;
    final tm = Timer(duration, () {
      ret._rem();
      fn();
    });
    ret = _timer(tm, unique: unique);

    return ret;
  }
  Timer periodic(Duration duration, Function(Timer) fn,
      {Symbol? unique}) {
    final tm = Timer.periodic(duration, (t) => fn(t));

    return _timer(tm, unique: unique);
  }

  _Timer _timer(Timer tm,
      {Symbol? unique}) {
    final ret = _Timer(this, tm, unique);

    if (unique != null) {
      _uniqueTimers[unique]?.cancel();
      _uniqueTimers[unique] = ret;
    } else {
      _timers.add(ret);
    }

    return ret;
  }
}