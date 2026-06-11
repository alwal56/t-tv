import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/channels_provider.dart';
import '../services/ocr_service.dart';
import '../theme/app_theme.dart';

/// يفتح نافذة إضافة مصدر (M3U أو Xtream) مع حقل اسم المجلد.
Future<void> showAddSourceSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.cardBg,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _AddSourceSheet(),
  );
}

class _AddSourceSheet extends StatefulWidget {
  const _AddSourceSheet();

  @override
  State<_AddSourceSheet> createState() => _AddSourceSheetState();
}

class _AddSourceSheetState extends State<_AddSourceSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _folder = TextEditingController();
  final _m3u = TextEditingController();
  final _server = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _ocrBusy = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  // ── قراءة البيانات من صورة (OCR) ──
  Future<void> _readFromImage() async {
    setState(() => _ocrBusy = true);
    final result = await OcrService.pickAndRead();
    if (!mounted) return;
    setState(() => _ocrBusy = false);

    if (result == null) {
      _snack('تعذّر تشغيل قارئ الصور');
      return;
    }
    if (result.rawText.trim().isEmpty) {
      _snack('لم يتم اختيار صورة أو لم يُقرأ نص');
      return;
    }

    final detected = <String>[];
    // Xtream له أولوية إذا وُجد مستخدم/كلمة مرور
    if (result.hasXtream) {
      _tab.animateTo(1);
      if (result.server != null) {
        _server.text = result.server!;
        detected.add('الخادم');
      }
      if (result.username != null) {
        _user.text = result.username!;
        detected.add('المستخدم');
      }
      if (result.password != null) {
        _pass.text = result.password!;
        detected.add('كلمة المرور');
      }
    } else if (result.m3uUrl != null) {
      _tab.animateTo(0);
      _m3u.text = result.m3uUrl!;
      detected.add('رابط M3U');
    }

    if (detected.isEmpty) {
      _snack('قُرئت الصورة لكن لم أتعرّف على بيانات مصدر واضحة');
    } else {
      _snack('تم استخراج: ${detected.join('، ')}');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    _folder.dispose();
    _m3u.dispose();
    _server.dispose();
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _submitM3u() {
    final url = _m3u.text.trim();
    if (url.isEmpty) return;
    final folder = _folder.text.trim();
    context.read<ChannelsProvider>().loadPlaylist(
          url,
          groupName: folder.isEmpty ? null : folder,
        );
    _done(folder);
  }

  void _submitXtream() {
    final s = _server.text.trim();
    final u = _user.text.trim();
    final p = _pass.text.trim();
    if (s.isEmpty || u.isEmpty || p.isEmpty) return;
    final folder = _folder.text.trim();
    context.read<ChannelsProvider>().loadXtream(
          server: s,
          username: u,
          password: p,
          groupName: folder.isEmpty ? null : folder,
        );
    _done(folder);
  }

  void _done(String folder) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(folder.isEmpty
            ? 'جاري إضافة المصدر... ستظهر القنوات في «قنوات متنوعة»'
            : 'جاري إضافة المصدر تحت مجلد «$folder»'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline_rounded,
                    color: AppTheme.accent, size: 22),
                SizedBox(width: 10),
                Text('إضافة مصدر قنوات',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),

            // ── حقل اسم المجلد (مشترك) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _folder,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'مثال: قنواتي الرياضية',
                  labelText: 'اسم المجلد (اختياري)',
                  prefixIcon: Icon(Icons.create_new_folder_rounded,
                      color: AppTheme.accent, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── قراءة البيانات من صورة (OCR) ──
            if (kIsWeb)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _ocrBusy ? null : _readFromImage,
                    icon: _ocrBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.accent),
                          )
                        : const Icon(Icons.image_search_rounded, size: 18),
                    label: Text(_ocrBusy
                        ? 'جاري قراءة الصورة...'
                        : 'رفع صورة وقراءة البيانات تلقائياً'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accent,
                      side: BorderSide(color: AppTheme.accent.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            if (kIsWeb) const SizedBox(height: 6),
            if (kIsWeb)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'ارفع صورة فيها الرابط أو بيانات Xtream وسيملأ الحقول تلقائياً',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 14),

            // ── التبويبات ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textSecondary,
                dividerColor: Colors.transparent,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(text: 'رابط M3U'),
                  Tab(text: 'Xtream Codes'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 230,
              child: TabBarView(
                controller: _tab,
                children: [_m3uTab(), _xtreamTab()],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _m3uTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          TextField(
            controller: _m3u,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'https://example.com/playlist.m3u',
              labelText: 'رابط M3U / M3U8',
              prefixIcon: Icon(Icons.link_rounded,
                  color: AppTheme.textSecondary, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.download_rounded),
              label: const Text('إضافة وتشغيل'),
              onPressed: _submitM3u,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'يدعم أي رابط M3U من أي مصدر',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _xtreamTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          TextField(
            controller: _server,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'http://server.com:8080',
              labelText: 'رابط الخادم',
              prefixIcon: Icon(Icons.dns_rounded,
                  color: AppTheme.textSecondary, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _user,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'username',
                    labelText: 'المستخدم',
                    prefixIcon: Icon(Icons.person_rounded,
                        color: AppTheme.textSecondary, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _pass,
                  obscureText: _obscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'password',
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(Icons.lock_rounded,
                        color: AppTheme.textSecondary, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppTheme.textSecondary,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.login_rounded),
              label: const Text('تسجيل الدخول وتشغيل'),
              onPressed: _submitXtream,
            ),
          ),
        ],
      ),
    );
  }
}
