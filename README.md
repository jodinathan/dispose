
# Are you tired of having to cancel subscriptions, timers and close controllers?    
  
Have you ever created an Angular Component or Flutter Widget that has some *Stream* being listened or *Timer* that are still executed after the component or widget destruction?     
  
Then you have to bind a variable to the subscription so you can cancel it on the component destruction?     
  
Not to mention that if your Timer/Stream is unique you have to cancel it before reassigning it again.  
  
This all happens because there isn't really a connection between your component/widget to the stream/timer/controller.   
  
Well, this package aims to help you with that.  
  
The package exposes a ```Disposable``` class that has a ```dispose()``` function that clears any listeners, timers, controllers etc that were created within it. You can make the objects unique by setting a paramater ```Symbol uniqueId``` in your calls.  
    
There is also a ```Angular``` class that already disposes stuff on OnDestroy (```package:dispose/angular.dart```).  
  
In the examples below you have to call the ```dispose()``` method of ```SomeClass``` somewhere. Usually in widget/component destruction.  
  
Examples:  
  
```dart  
import 'package:dispose/dispose.dart';  
```  
    
# each  
It iterates through the stream and disposes the listener within ```dispose()```.  
Example:   
```dart  
  
class SomeClass extends Disposable {  
  void listenToInts(Stream<int> myIntStream) {  
    each(myIntStream, (int value) {  
      print('someInt $value');  
    }, uniqueId: #MyUniqueListener);  
  }  
}  
```  
# controller  
It creates a ```StreamController<T>``` that is closed within  ```dispose()```.  
Example:   
```dart  
  
class SomeClass extends Disposable {  
  late StreamController<int> _intController;  
    
  SomeClass() {  
    _intController = controller(broadcast: false);  
  }  
}  
```  
# timer  
It creates a ```Timer``` that is cancelled within  ```dispose()``` if it wasn't already executed.  
Example:   
```dart  
  
class SomeClass extends Disposable {  
  void method() {  
    timer(Duration(seconds: 5), () => print('Executed!'));  
    // the above timer will be free in dispose() if not executed  
  }  
}  
```  
# periodic  
It creates a ```Timer.periodic``` that is cancelled within  ```dispose()```.  
Example:   
```dart  
  
class SomeClass extends Disposable {  
  void method() {  
    var x = 0;  
    periodic(Duration(seconds: 5), ()   
      => print('Executed ${++x}'));  
  }  
}  
```
# bind  
Binds another ```Disposable``` object that will be freed along in  ```dispose()```.  
Example:   
```dart  

class SomeOtherClass extends Disposable {
  Timer myPeriodic;
  SomeOtherClass() {
    myPeriodic = periodic(Duration(seconds: 30));
  }
}  
class SomeClass extends Disposable {  
  final prop = SomeOtherClass();

  SomeClass() {
    // prop will be disposed in SomeClass.dispose() if
    // it wasn't already.
    bind(prop);
  }
}  
```

# cancelBind & cancelTimer  
Use these methods to cancel unique bindings and timers.
