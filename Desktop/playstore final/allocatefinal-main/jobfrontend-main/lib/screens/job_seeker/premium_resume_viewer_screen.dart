import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../utils/screenshot_protection.dart';
import '../../services/app_session.dart';
import '../../services/job_seeker_api_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/seeker_html_template_swatch.dart';
import 'resume_html_preview_screen.dart';

/// Full-screen premium resume viewer with hardware-level screenshot and screen recording protection.
class PremiumResumeViewerScreen extends StatefulWidget {
  final String userId;
  final String token;
  final String templateKey;
  final int demoVariant;
  final String? resumeTitle;

  const PremiumResumeViewerScreen({
    super.key,
    required this.userId,
    required this.token,
    required this.templateKey,
    this.demoVariant = 0,
    this.resumeTitle,
  });

  @override
  State<PremiumResumeViewerScreen> createState() => _PremiumResumeViewerScreenState();
}

class _PremiumResumeViewerScreenState extends State<PremiumResumeViewerScreen> with WidgetsBindingObserver {
  late final WebViewController _web;
  bool _loading = true;
  String? _error;
  String _htmlContent = '';
  bool _appIsBackgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Enable screenshot & recording protection immediately upon entry
    ScreenshotProtection.enable();

    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _loading = false);
            }
          },
        ),
      );

    _loadResume();
  }

  @override
  void dispose() {
    // Disable restriction on exit so it doesn't affect other screens
    ScreenshotProtection.disable();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      setState(() => _appIsBackgrounded = true);
    } else if (state == AppLifecycleState.resumed) {
      setState(() => _appIsBackgrounded = false);
      // Re-enable protection just in case Android cleared the flag
      ScreenshotProtection.enable();
    }
  }

  Future<void> _loadResume() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final api = JobSeekerApiService.instance;
      final response = await api.previewResumeHtml(
        templateKey: widget.templateKey,
        demoVariant: widget.demoVariant,
      );

      _htmlContent = response;
      await _web.loadHtmlString(_htmlContent, baseUrl: 'https://joballocate.tech/');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _exportPdf() async {
    if (_htmlContent.isEmpty) return;
    await Printing.layoutPdf(
      onLayout: (format) => Printing.convertHtml(
        format: format,
        html: _htmlContent,
        baseUrl: 'https://joballocate.tech/',
      ),
    );
  }

  Future<void> _sharePdf() async {
    if (_htmlContent.isEmpty) return;
    try {
      final pdfBytes = await Printing.convertHtml(
        format: PdfPageFormat.a4,
        html: _htmlContent,
        baseUrl: 'https://joballocate.tech/',
      );
      final filename = '${widget.resumeTitle ?? "My_Resume"}.pdf';
      await Share.shareXFiles(
        [XFile.fromData(pdfBytes, mimeType: 'application/pdf', name: filename)],
        text: 'Sharing my resume generated via JobAllocate.',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share PDF: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.resumeTitle ?? seekerHtmlTemplateLabel(widget.templateKey);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          titleText,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded, color: Colors.white70),
            tooltip: 'Print Resume',
            onPressed: _loading ? null : _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white70),
            tooltip: 'Share PDF',
            onPressed: _loading ? null : _sharePdf,
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white70),
            tooltip: 'Download PDF',
            onPressed: _loading ? null : _exportPdf,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Main Interactive Viewer supporting Zoom & Pan
          InteractiveViewer(
            minScale: 0.8,
            maxScale: 3.0,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
                child: Container(
                  width: kResumeHtmlA4WidthPx,
                  height: kResumeHtmlCanvasHeightPx,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: IgnorePointer(
                    ignoring: true, // Disable internal text selection / tap inside WebView
                    child: WebViewWidget(controller: _web),
                  ),
                ),
              ),
            ),
          ),

          // Loading indicator
          if (_loading)
            Container(
              color: const Color(0xFF0F172A).withOpacity(0.9),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
                    SizedBox(height: 16),
                    Text(
                      'Rendering secure document preview...',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

          // Error view
          if (_error != null)
            Container(
              color: const Color(0xFF0F172A),
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadResume,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),

          // App Switcher/Background Blur protection overlay
          if (_appIsBackgrounded)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_rounded, color: Colors.white70, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'Content Hidden for Security',
                          style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quick applied with your premium resume!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
        label: const Text('Quick Apply', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 6,
      ),
    );
  }
}
