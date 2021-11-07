import 'dart:async';

import 'interval.dart';

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

class ControlledStreamSubscription<T> implements StreamSubscription<T> {
  final StreamSubscription<T> _delegate;
  final void Function() _cancel;

  @override
  Future<void> cancel() {
    _cancel();
    return _delegate.cancel();
  }

  @override
  void onData(void Function(T)? handleData) =>
      _delegate.onData(handleData);

  @override
  void onError(Function? handleError) =>
      _delegate.onError(handleError);

  @override
  void onDone(void Function()? handleDone) =>
      _delegate.onDone(handleDone);

  @override
  void pause([Future<void>? resumeSignal]) =>
      _delegate.pause(resumeSignal);

  @override
  void resume() => _delegate.resume();

  @override
  bool get isPaused => _delegate.isPaused;

  @override
  Future<E> asFuture<E>([E? futureValue]) =>
      _delegate.asFuture(futureValue);

  ControlledStreamSubscription(this._delegate, this._cancel);
}

abstract class Disposable {
  final _subs = <StreamSubscription>{};
  final _uniqueSubs = <Symbol, StreamSubscription>{};
  final _ctrls = <StreamController>{};
  final _timers = <_Timer>{};
  final _uniqueTimers = <Symbol, _Timer>{};
  final _disposables = <Disposable>{};
  Disposable? _parent;

  /// Listens and iterates through [stream] by calling [fn].
  /// The listener is disposed in the [dispose] function.
  ///
  /// If you add a [uniqueId], it means that whenever you call [each],
  /// we will make sure that clear any listener with the same [uniqueId].
  StreamSubscription<T> each<T extends Object?>(Stream<T> stream,
      void Function(T item) fn,
      {Symbol? uniqueId}) {
    late StreamSubscription<T> ret;

    if (uniqueId == null) {
      ret = ControlledStreamSubscription(stream.listen(fn),
              () => _subs.remove(ret));
      _subs.add(ret);
    } else {
      ret = ControlledStreamSubscription(stream.listen(fn),
              () => _uniqueSubs.remove(uniqueId));

      _uniqueSubs[uniqueId]?.cancel();

      _uniqueSubs[uniqueId] = ret;
    }

    return ret;
  }

  /// Creates a [StreamController] that is closed within [dispose].
  ///
  /// Set [broadcast] to true if you need a
  /// broadcasting controller as in [StreamController.broadcast].
  StreamController<T> controller<T extends Object>({
    bool broadcast = false,
    FutureOr<void> Function()? onCancel/*?*/
  }) {
    StreamController<T> ret;

    if (broadcast) {
      ret = StreamController<T>.broadcast(onCancel: onCancel);
    } else {
      ret = StreamController<T>(onCancel: onCancel);
    }
    ret.done.then((ev) => _ctrls.remove(ret));

    _ctrls.add(ret);

    return ret;
  }

  /// Binds another [Disposable] object to be disposed when this
  /// is disposed.
  void disposable(Disposable disposable) {
    disposable._parent = this;
    _disposables.add(disposable);
  }

  /// Cancel all active listeners, timers, close the controllers
  /// and disposes other disposables bound with [bind].
  ///
  /// You should not use this class after it's disposal.
  /// If you only want to cancel/clear stuff, use [cancelBindings].
  Future<void> dispose() async {
    if (_parent != null) {
      _parent!._disposables.remove(this);
    }

    for (var disposable in _disposables.toList()) {
      await disposable.dispose();
    }

    assert(_disposables.isEmpty);

    await cancelBindings(); // 15 9 9134 9888
  }

  /// Cancel all active listeners, timers and close the controllers.
  /// This *does not* dispose other disposables bound with [bind].
  ///
  /// [dispose] calls this function internally.
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

  /// Creates a [Timer] that gets cancelled within [dispose] if not executed.
  ///
  /// Set [uniqueId] to some [Symbol] to make this timer unique.
  /// This means that we will cancel the previous timer with same symbol
  /// before assigning a new one.
  Timer timer(Duration duration, Function() fn,
      {Symbol? uniqueId}) {
    late _Timer ret;
    final tm = Timer(duration, () {
      ret._rem();
      fn();
    });
    ret = _timer(tm, uniqueId: uniqueId);

    return ret;
  }

  /// Creates a periodic [Timer.periodic] that gets cancelled within [dispose].
  ///
  /// Set [uniqueId] to some [Symbol] to make this timer unique.
  /// This means that we will cancel the previous timer with same symbol
  /// before assigning a new one.
  Timer periodic(Duration duration, Function(Timer) fn,
      {Symbol? uniqueId}) {
    final tm = Timer.periodic(duration, (t) => fn(t));

    return _timer(tm, uniqueId: uniqueId);
  }

  Timer interval(Duration duration, Function() fn,
      {Symbol? uniqueId, bool execNow = true}) {
    final tm = IntervalTimer(fn, duration, execNow: execNow);

    return _timer(tm, uniqueId: uniqueId);
  }

  StreamedIntervalTimer streamedInterval<T, E>(Stream<T> valueStream,
      Duration duration, Function(T?) fn, {Symbol? uniqueId}) {
    final tm = StreamedIntervalTimer(fn, duration, execNow: true);

    each<T>(valueStream, (ev) {
      tm.add(ev);
    });

    _timer(tm, uniqueId: uniqueId);

    return tm;
  }

  _Timer _timer(Timer tm,
      {Symbol? uniqueId}) {
    final ret = _Timer(this, tm, uniqueId);

    if (uniqueId != null) {
      _uniqueTimers[uniqueId]?.cancel();
      _uniqueTimers[uniqueId] = ret;
    } else {
      _timers.add(ret);
    }

    return ret;
  }
}
