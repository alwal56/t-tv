/// واجهة موحّدة لوظائف الويب — تختار التنفيذ المناسب حسب المنصّة.
/// على الويب: dart:html / dart:js. على الأصلي: بدائل فارغة.
export 'web_interop_stub.dart' if (dart.library.html) 'web_interop_web.dart';
