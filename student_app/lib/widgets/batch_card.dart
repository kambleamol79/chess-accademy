import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/theme.dart';
import '../models/batch.dart';
import 'app_ui.dart';

class BatchCard extends StatelessWidget {
  const BatchCard({super.key, required this.batch, this.compact = false});

  final StudentBatch batch;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  batch.batch,
                  style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              const Spacer(),
              if (batch.module != null && batch.module!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    batch.module!,
                    style: const TextStyle(color: AppColors.accentOrange, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(icon: Icons.calendar_month_rounded, label: 'Schedule', value: '${batch.daysSummary} · ${batch.day1} / ${batch.day2}'),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.schedule_rounded, label: 'Time', value: batch.time),
          if (!compact) ...[
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.person_rounded, label: 'Coach', value: batch.coachesLabel),
            if (batch.notes != null && batch.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoRow(icon: Icons.sticky_note_2_outlined, label: 'Notes', value: batch.notes!),
            ],
            if (batch.zoomJoinUrl != null && batch.zoomJoinUrl!.isNotEmpty) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: AppPrimaryButton(
                  label: 'Launch Zoom',
                  icon: Icons.videocam_rounded,
                  gradient: true,
                  onPressed: () => _openZoom(context, batch.zoomJoinUrl!),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _copyZoomLink(context, batch.zoomJoinUrl!),
                  icon: const Icon(Icons.link_rounded, size: 18),
                  label: const Text('Copy link'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _openZoom(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Zoom on this device')),
      );
    }
  }

  Future<void> _copyZoomLink(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zoom link copied')),
      );
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIconBadge(icon: icon, color: AppColors.primaryBlue, size: 38),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }
}
