import 'dart:ffi';
import 'dart:io';

typedef NativeCallback = Void Function(Int32 type, Int32 x, Int32 y);
typedef DartCallback = void Function(int type, int x, int y);

typedef StartHookFunc = Void Function();
typedef StartHookOnly = void Function();

typedef SetCallbackFunc =
    Void Function(Pointer<NativeFunction<NativeCallback>>);
typedef SetCallbackOnly =
    void Function(Pointer<NativeFunction<NativeCallback>>);

typedef SetCursorPosFunc = Void Function(Int32 x, Int32 y);
typedef SetCursorPosOnly = void Function(int x, int y);

class InputHookService {
  late DynamicLibrary _dylib;
  late StartHookOnly _startHook;
  late SetCallbackOnly _setCallback;
  late SetCursorPosOnly _setCursorPos;

  InputHookService() {
    _loadLibrary();
  }

  void _loadLibrary() {
    if (Platform.isWindows) {
      try {
        // User must copy the built dll to this location or we find it in target/release
        // For dev, assuming root/native/input_hook/target/release/input_hook.dll
        // But flutter run from root doesn't look there by default.
        // We'll try absolute path or relative.
        // For now, hardcode or expect 'input_hook.dll' next to executable.
        _dylib = DynamicLibrary.open('input_hook.dll');
      } catch (e) {
        // Fallback or rethrow
        print('Could not load input_hook.dll: $e');
        return;
      }

      _startHook = _dylib
          .lookup<NativeFunction<StartHookFunc>>('start_hook')
          .asFunction();
      _setCallback = _dylib
          .lookup<NativeFunction<SetCallbackFunc>>('set_callback')
          .asFunction();
      _setCursorPos = _dylib
          .lookup<NativeFunction<SetCursorPosFunc>>('remote_set_cursor_pos')
          .asFunction();
    }
  }

  void start() {
    if (Platform.isWindows) {
      _startHook();
    }
  }

  void setCallback(Pointer<NativeFunction<NativeCallback>> callback) {
    if (Platform.isWindows) {
      _setCallback(callback);
    }
  }

  void setCursorPos(int x, int y) {
    if (Platform.isWindows) {
      _setCursorPos(x, y);
    }
  }
}
