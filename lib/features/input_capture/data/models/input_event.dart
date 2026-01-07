import 'dart:typed_data';

enum InputEventType {
  mouseMove(1),
  mouseDown(2),
  mouseUp(3),
  keyDown(4),
  keyUp(5);

  final int value;
  const InputEventType(this.value);
}

class InputEventSerializer {
  static Uint8List serializeMouseMove(int deltaX, int deltaY) {
    final data = ByteData(5);
    data.setUint8(0, InputEventType.mouseMove.value);
    data.setInt16(1, deltaX, Endian.little);
    data.setInt16(3, deltaY, Endian.little);
    return data.buffer.asUint8List();
  }

  static Uint8List serializeMouseButton(bool isDown, int button) {
    final data = ByteData(3);
    data.setUint8(
      0,
      isDown ? InputEventType.mouseDown.value : InputEventType.mouseUp.value,
    );
    data.setUint8(1, button); // 0=Left, 1=Right, 2=Middle
    return data.buffer.asUint8List();
  }

  static Map<String, dynamic>? deserialize(Uint8List data) {
    if (data.isEmpty) return null;

    final buffer = ByteData.sublistView(data);
    final type = buffer.getUint8(0);

    switch (type) {
      case 1: // MouseMove
        if (data.length >= 5) {
          return {
            'type': 'mouseMove',
            'deltaX': buffer.getInt16(1, Endian.little),
            'deltaY': buffer.getInt16(3, Endian.little),
          };
        }
        break;
      case 2: // MouseDown
      case 3: // MouseUp
        if (data.length >= 2) {
          return {
            'type': type == 2 ? 'mouseDown' : 'mouseUp',
            'button': buffer.getUint8(1),
          };
        }
        break;
    }
    return null;
  }
}
