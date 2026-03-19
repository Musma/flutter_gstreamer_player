import 'package:flutter/services.dart';
import 'package:flutter_gstreamer_player/flutter_gstreamer_player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_gstreamer_player');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'position') {
          return 42000; // 42초
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('position returns Duration', () async {
    final controller = GstPlayerTextureController();
    final duration = await controller.position();
    expect(duration, const Duration(milliseconds: 42000));
  });
}
