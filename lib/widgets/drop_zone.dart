import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pdf_service.dart';

class DropZone extends ConsumerWidget {
  const DropZone({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.picture_as_pdf_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Unsync Reader',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
          ),

          const SizedBox(height: 8),

          Text(
            'Your files. Your device. Nobody else.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                ),
          ),

          const SizedBox(height: 32),

          // Open button
          ElevatedButton.icon(
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('Open a PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: () => PdfService.openFile(ref, context),
          ),

          const SizedBox(height: 16),

          // Quick actions
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _QuickAction(
                icon: Icons.call_merge_outlined,
                label: 'Merge',
                onTap: () => PdfService.mergePdfs(ref),
              ),
              const SizedBox(width: 12),
              _QuickAction(
                icon: Icons.image_outlined,
                label: 'Images → PDF',
                onTap: () => PdfService.imagesToPdf(ref),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Privacy badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined,
                  size: 14, color: Colors.green),
              const SizedBox(width: 6),
              Text(
                '100% local · No internet · No tracking',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.green.withOpacity(0.8),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).dividerTheme.color!,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
