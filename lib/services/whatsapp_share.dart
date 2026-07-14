import 'package:flutter/services.dart';

class WhatsAppShare {
  WhatsAppShare._();

  static const _channel = MethodChannel('com.example.movie_app/whatsapp');

  static Future<bool> share(String message) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'share',
        {'message': message},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}