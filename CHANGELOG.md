# 0.0.8
- Added `cancelBind` and `cancelTimer` that cancel unique bindings and timers.  
- Added `reusable` method that creates an instance of `Disposable` so you can create bindings, 
clear them and rebind again when need.
- Added an Angular base class to aid components:  
```dart
import 'package:dispose/angular.dart';

class MyComponent extends DisposableComponent {
  StreamController<int> _myCtrl; // this will be automatically freed on ngOnDestroy

  MyComponent() {
    _myCtrl = controller();
  }
}
```

# 0.0.7
Removed the `Object` in favor of `dynamic`. 

# 0.0.6
NNBD automatic migration

# 0.0.5
Some minor bug fixes

# 0.0.4
Added the disposable method.
It enables adding disposable objects to be disposed within another Disposable object.

# 0.0.3
Removed the NNBD stuff for now.

# 0.0.2
First try of the package with the wrappers:
* each: *Stream*
* controller: *StreamController*
* timer and periodic: *Timer*
