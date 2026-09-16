// lib/views/screens/upload_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../utils/app_constants.dart';
import '../widgets/shared_widgets.dart';
import 'candidate_detail_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UploadViewModel>().loadFiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width;
    final contentWidth = maxWidth > 600 ? 600.0 : maxWidth;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppTopBar(title: 'Upload Resume', showBack: false),
      body: Consumer<UploadViewModel>(builder: (_, vm, __) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: ListView(
              padding: const EdgeInsets.all(AppSpace.lg),
              children: [
                // ── Drop zone (single, consolidated upload action) ──
                _UploadZone(
                  isUploading: vm.isUploading,
                  isParsing: vm.isParsing,
                  onTap: () => _pickFile(context, vm),
                ),

                // ── Error ──────────────────────────
                if (vm.error != null) ...[
                  const SizedBox(height: AppSpace.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpace.md),
                    decoration: BoxDecoration(
                      color: AppColors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.red.withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      Icon(Icons.error_outline_rounded,
                          color: AppColors.red, size: 18),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                          child: Text(vm.error!,
                              style: AppText.body(13, color: AppColors.red))),
                    ]),
                  ),
                ],

                const SizedBox(height: AppSpace.xl),

                // ── Recent uploads ─────────────────
                const SectionTitle('Recently Uploaded'),
                const SizedBox(height: AppSpace.sm),
                if (vm.files.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.xl),
                    alignment: Alignment.center,
                    child: Text('Nothing uploaded yet',
                        style: AppText.caption(12, color: AppColors.ink3)),
                  )
                else
                  ...vm.files.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.sm),
                        child: _FileItem(file: f),
                      )),
              ],
            ),
          ),
        );
      }),
    );
  }

  Future<void> _pickFile(BuildContext context, UploadViewModel vm) async {
    final candidate = await vm.pickAndParseResume();
    if (candidate != null && mounted) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => CandidateDetailScreen(candidate: candidate)));
    }
  }
}

// ── Upload Zone widget — the single tap target for uploading ──
class _UploadZone extends StatelessWidget {
  final bool isUploading;
  final bool isParsing;
  final VoidCallback onTap;
  const _UploadZone({
    required this.isUploading,
    required this.isParsing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final busy = isUploading || isParsing;
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            vertical: AppSpace.xxl, horizontal: AppSpace.lg),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
              color:
                  busy ? AppColors.accent : AppColors.accent.withOpacity(0.25),
              width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Color(0x080A1F1D), blurRadius: 20, offset: Offset(0, 6)),
          ],
        ),
        child: busy
            ? Column(children: [
                const CircularProgressIndicator(color: AppColors.accent),
                const SizedBox(height: AppSpace.md),
                Text(isParsing ? 'Parsing with AI…' : 'Uploading…',
                    style: AppText.label(14, color: AppColors.accent)),
                const SizedBox(height: 4),
                Text('This usually takes a few seconds',
                    style: AppText.caption(11, color: AppColors.ink3)),
              ])
            : Column(children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.accent.withOpacity(0.12),
                            AppColors.amber.withOpacity(0.12)
                          ]),
                      borderRadius: BorderRadius.circular(AppRadius.lg)),
                  child: const Icon(Icons.upload_rounded,
                      color: AppColors.accent, size: 30),
                ),
                const SizedBox(height: AppSpace.md),
                Text('Tap to Upload a Resume', style: AppText.title(16)),
                const SizedBox(height: 6),
                Text('From your device or Google Drive',
                    textAlign: TextAlign.center,
                    style: AppText.caption(12, color: AppColors.ink3)),
                const SizedBox(height: AppSpace.md),
                Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: ['PDF', 'DOCX', 'DOC', 'TXT']
                        .map((f) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                  border: Border.all(color: AppColors.border2)),
                              child: Text(f, style: AppText.label(11)),
                            ))
                        .toList()),
              ]),
      ),
    );
  }
}

// ── File item row ────────────────────────────
class _FileItem extends StatelessWidget {
  final Map<String, String> file;
  const _FileItem({required this.file});

  IconData get _icon {
    switch (file['type']) {
      case 'PDF':
        return Icons.picture_as_pdf_rounded;
      case 'DOCX':
      case 'DOC':
        return Icons.description_rounded;
      case 'TXT':
        return Icons.article_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isParsed = file['status'] == 'parsed';
    final isPDF = file['type'] == 'PDF';
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md, vertical: AppSpace.md),
      decoration: AppDecor.card(radius: AppRadius.md),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: isPDF
                  ? AppColors.red.withOpacity(0.1)
                  : AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: Icon(_icon,
              size: 19, color: isPDF ? AppColors.red : AppColors.accent),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(file['name']!,
              style: AppText.label(13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('${file['size']} · ${file['time']}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption(11)),
        ])),
        const SizedBox(width: AppSpace.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: isParsed ? AppColors.scoreHighBg : AppColors.scoreMidBg,
              borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: Text(isParsed ? 'Parsed' : 'Parsing…',
              style: AppText.label(11,
                  color:
                      isParsed ? AppColors.scoreHighFg : AppColors.scoreMidFg)),
        ),
      ]),
    );
  }
}
