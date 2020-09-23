import 'package:angular/angular.dart';
import 'src/generic.dart';

abstract class DisposableComponent extends Disposable implements OnDestroy {
  @override
  void ngOnDestroy() => dispose();
}