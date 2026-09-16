import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/pooja_entities.dart';
import '../../domain/usecases/pooja_actions.dart';

class PanditPoojaFormPage extends StatefulWidget {
  const PanditPoojaFormPage({this.offering, super.key});
  final PanditOffering? offering;

  @override
  State<PanditPoojaFormPage> createState() => _PanditPoojaFormPageState();
}

class _PanditPoojaFormPageState extends State<PanditPoojaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _name;
  late final TextEditingController _shortDescription;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _duration;
  late final TextEditingController _notes;
  final List<XFile> _newImages = <XFile>[];
  String _serviceMode = 'flexible';
  bool _saving = false;

  bool get _editing => widget.offering != null;

  @override
  void initState() {
    super.initState();
    final o = widget.offering;
    _name = TextEditingController(text: o?.name ?? '');
    _shortDescription = TextEditingController(text: o?.shortDescription ?? '');
    _description = TextEditingController(text: o?.description ?? '');
    _price = TextEditingController(
      text: o == null ? '' : o.priceAmount.toStringAsFixed(0),
    );
    _duration = TextEditingController(
      text: o?.durationMinutes?.toString() ?? '60',
    );
    _notes = TextEditingController();
    _serviceMode = o?.serviceMode ?? 'flexible';
  }

  @override
  void dispose() {
    _name.dispose();
    _shortDescription.dispose();
    _description.dispose();
    _price.dispose();
    _duration.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_saving) return;
    final files = await _picker.pickMultiImage(imageQuality: 88);
    if (!mounted || files.isEmpty) return;
    final existingCount = widget.offering?.media.length ?? 0;
    final maxNewImages = (8 - existingCount).clamp(0, 8);
    setState(() {
      for (final file in files) {
        if (_newImages.length >= maxNewImages) break;
        if (_newImages.every((item) => item.path != file.path)) {
          _newImages.add(file);
        }
      }
    });
  }

  String _mimeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }

  String _normalizedMimeType(XFile image) {
    final raw = image.mimeType?.trim().toLowerCase();
    if (raw == null || raw.isEmpty) return _mimeFromName(image.name);
    if (raw == 'image/jpg' || raw == 'image/pjpeg') return 'image/jpeg';
    if (raw == 'image/x-png') return 'image/png';
    return raw;
  }

  Future<List<String>> _uploadSelectedImages(PanditPoojaActions actions) async {
    final ids = <String>[];
    for (final image in _newImages) {
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) {
        throw const ApiException('One of the selected images is empty.');
      }
      final id = await actions.uploadImage(
        bytes: bytes,
        fileName: image.name,
        mimeType: _normalizedMimeType(image),
      );
      ids.add(id);
    }
    return ids;
  }

  Future<void> _cleanupUploadedImages(
    PanditPoojaActions actions,
    Iterable<String> ids,
  ) async {
    for (final id in ids) {
      try {
        await actions.deleteUploadedImage(id);
      } catch (_) {
        // Cleanup is best-effort. Preserve the original save error.
      }
    }
  }

  String _apiErrorMessage(ApiException error) {
    if (error.details.isNotEmpty) {
      return error.details.map((detail) {
        final field = detail.field.trim();
        return field.isEmpty ? detail.message : '$field: ${detail.message}';
      }).join('\n');
    }
    return error.message;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final actions = getIt<PanditPoojaActions>();
    final uploadedIds = <String>[];

    try {
      uploadedIds.addAll(await _uploadSelectedImages(actions));

      final existingIds = widget.offering?.media
              .map((item) => item.id.trim())
              .where((id) => id.isNotEmpty)
              .toList(growable: false) ??
          const <String>[];

      final mediaAssetIds = <String>{...existingIds, ...uploadedIds}
          .toList(growable: false);

      final priceAmount = double.parse(_price.text.trim());
      final durationMinutes = int.parse(_duration.text.trim());

      if (_editing) {
        await actions.updateOffering(
          offeringId: widget.offering!.id,
          name: _name.text.trim(),
          shortDescription: _shortDescription.text.trim(),
          description: _description.text.trim(),
          priceAmount: priceAmount,
          currency: 'INR',
          durationMinutes: durationMinutes,
          serviceMode: _serviceMode,
          notes: _notes.text.trim(),
          mediaAssetIds: mediaAssetIds,
        );
      } else {
        await actions.createOffering(
          name: _name.text.trim(),
          shortDescription: _shortDescription.text.trim(),
          description: _description.text.trim(),
          priceAmount: priceAmount,
          currency: 'INR',
          durationMinutes: durationMinutes,
          serviceMode: _serviceMode,
          notes: _notes.text.trim(),
          mediaAssetIds: mediaAssetIds,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      await _cleanupUploadedImages(actions, uploadedIds);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_apiErrorMessage(error))),
      );
    } catch (_) {
      await _cleanupUploadedImages(actions, uploadedIds);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save the Pooja. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingMedia = widget.offering?.media ?? const <PoojaMedia>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit Pooja Offering' : 'Add Pooja Offering'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_editing)
              Card(
                child: ListTile(
                  title: Text('Approval: ${widget.offering!.approvalStatus}'),
                  subtitle: widget.offering!.moderationNote == null
                      ? const Text(
                          'Changing commercial/content terms sends the offering back for admin approval.',
                        )
                      : Text(widget.offering!.moderationNote!),
                ),
              ),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Pooja name'),
              validator: (v) => (v?.trim().length ?? 0) < 2
                  ? 'Enter a valid name'
                  : null,
            ),
            TextFormField(
              controller: _shortDescription,
              decoration: const InputDecoration(labelText: 'Short description'),
            ),
            TextFormField(
              controller: _description,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (v) => (v?.trim().length ?? 0) < 10
                  ? 'Description must be at least 10 characters'
                  : null,
            ),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (INR)'),
              validator: (v) {
                final value = double.tryParse(v?.trim() ?? '');
                if (value == null) return 'Enter a valid price';
                if (value <= 0) return 'Price must be greater than 0';
                return null;
              },
            ),
            TextFormField(
              controller: _duration,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Duration (minutes)'),
              validator: (v) {
                final value = int.tryParse(v?.trim() ?? '');
                if (value == null) return 'Enter duration';
                if (value <= 0) return 'Duration must be greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _serviceMode,
              decoration: const InputDecoration(labelText: 'Service mode'),
              items: const [
                DropdownMenuItem(value: 'temple', child: Text('Temple')),
                DropdownMenuItem(value: 'home', child: Text('Home')),
                DropdownMenuItem(value: 'online', child: Text('Online')),
                DropdownMenuItem(value: 'flexible', child: Text('Flexible')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _serviceMode = value);
              },
            ),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Provider notes'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pooja Images',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _saving || existingMedia.length + _newImages.length >= 8
                      ? null
                      : _pickImages,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Add images'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'You can add up to 8 images. The first image is used as the primary image when the backend does not provide a separate cover.',
              style: TextStyle(fontSize: 12),
            ),
            if (existingMedia.isNotEmpty || _newImages.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 92,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ...existingMedia.map(
                      (media) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            media.url,
                            width: 92,
                            height: 92,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 92,
                              height: 92,
                              alignment: Alignment.center,
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      ),
                    ),
                    ..._newImages.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: FutureBuilder<Uint8List>(
                                future: entry.value.readAsBytes(),
                                builder: (context, snapshot) {
                                  final bytes = snapshot.data;
                                  if (bytes == null) {
                                    return Container(
                                      width: 92,
                                      height: 92,
                                      alignment: Alignment.center,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    );
                                  }
                                  return Image.memory(
                                    bytes,
                                    width: 92,
                                    height: 92,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: IconButton.filledTonal(
                                visualDensity: VisualDensity.compact,
                                iconSize: 16,
                                onPressed: _saving
                                    ? null
                                    : () => setState(() => _newImages.removeAt(entry.key)),
                                icon: const Icon(Icons.close),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
