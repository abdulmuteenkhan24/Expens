import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/receipt_service.dart';

class ReceiptPicker extends StatelessWidget {
  final String? path;
  final ValueChanged<String?> onChanged;

  const ReceiptPicker({
    super.key,
    required this.path,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (file == null) return;
    final saved = await ReceiptService.saveReceipt(file.path);
    if (saved != null) {
      if (path != null && path!.isNotEmpty && path != saved) {
        await ReceiptService.deleteReceipt(path);
      }
      onChanged(saved);
    }
  }

  void _showSource(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(context, ImageSource.gallery);
              },
            ),
            if (path != null && path!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove receipt'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ReceiptService.deleteReceipt(path);
                  onChanged(null);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final has = path != null && path!.isNotEmpty && File(path!).existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Receipt',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        if (has)
          Stack(
            children: [
              GestureDetector(
                onTap: () {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => Dialog(
                      child: InteractiveViewer(
                        child: Image.file(File(path!)),
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(path!),
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                    onPressed: () => _showSource(context),
                  ),
                ),
              ),
            ],
          )
        else
          OutlinedButton.icon(
            onPressed: () => _showSource(context),
            icon: const Icon(Icons.attach_file_rounded),
            label: const Text('Attach receipt'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
      ],
    );
  }
}
