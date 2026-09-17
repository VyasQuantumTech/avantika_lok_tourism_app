import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/provider_kyc.dart';
import '../../domain/usecases/manage_provider_kyc.dart';

class ProviderKycPage extends StatefulWidget {
  const ProviderKycPage({super.key});

  @override
  State<ProviderKycPage> createState() => _ProviderKycPageState();
}

class _ProviderKycPageState extends State<ProviderKycPage> {
  final ImagePicker _picker = ImagePicker();
  late Future<ProviderKycSnapshot> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = getIt<ManageProviderKyc>().load();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  void _continueToProviderDashboard(ProviderKycSnapshot snapshot) {
    final providerType = snapshot.providerType
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    String route;
    switch (providerType) {
      case 'pandit':
      case 'priest':
      case 'pujari':
        route = RouteNames.panditDashboard;
        break;

      case 'hotel_manager':
      case 'hotel':
      case 'accommodation':
      case 'accommodation_provider':
      case 'accommodation_owner':
      case 'hotel_owner':
        route = RouteNames.accommodationDashboard;
        break;

      case 'vehicle_owner':
      case 'transport':
      case 'transport_provider':
      case 'transport_owner':
      case 'vehicle':
      case 'cab':
      case 'taxi':
        route = RouteNames.transportDashboard;
        break;

      default:
        // Fall back to the authoritative gate if a future provider type is
        // introduced that this mobile build does not know yet.
        route = RouteNames.providerGate;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
  }

  Future<void> _addEvidence(ProviderKycRequirement requirement) async {
    if (_busy || requirement.acceptedTypes.isEmpty) return;

    var documentType = requirement.acceptedTypes.first;
    final numberController = TextEditingController();
    var side = 'single';

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add ${_pretty(requirement.key)}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: documentType,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Document type'),
                  items: requirement.acceptedTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(_pretty(type)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => documentType = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: numberController,
                  decoration: const InputDecoration(
                    labelText: 'Document number (optional)',
                    helperText: 'Only the last 4 characters and a secure hash are stored.',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: side,
                  decoration: const InputDecoration(labelText: 'Document side'),
                  items: const [
                    DropdownMenuItem(value: 'single', child: Text('Single / full page')),
                    DropdownMenuItem(value: 'front', child: Text('Front')),
                    DropdownMenuItem(value: 'back', child: Text('Back')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => side = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Choose image')),
          ],
        ),
      ),
    );

    if (proceed != true || !mounted) {
      numberController.dispose();
      return;
    }

    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file == null) {
      numberController.dispose();
      return;
    }

    setState(() => _busy = true);
    try {
      final bytes = await file.readAsBytes();
      await getIt<ManageProviderKyc>().addDocument(
        bytes: bytes,
        fileName: file.name,
        mimeType: file.mimeType ?? _mimeFromName(file.name),
        category: requirement.category,
        documentType: documentType,
        documentNumber: numberController.text,
        documentSide: side,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KYC evidence uploaded successfully.')),
      );
      await _refresh();
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) _showError('Unable to upload KYC evidence.');
    } finally {
      numberController.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteDocument(ProviderKycDocument document) async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove KYC evidence?'),
        content: Text('Remove ${_pretty(document.documentType)} from this application?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await getIt<ManageProviderKyc>().deleteDocument(document.id);
      await _refresh();
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit(ProviderKycSnapshot snapshot) async {
    if (_busy || !snapshot.canSubmit) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit KYC for review?'),
        content: const Text('After submission, your evidence is locked until an administrator completes review or requests resubmission.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await getIt<ManageProviderKyc>().submit();
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KYC submitted for administrative review.')),
        );
      }
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Provider KYC'),
        backgroundColor: AppColors.onPrimary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: FutureBuilder<ProviderKycSnapshot>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError || snapshot.data == null) {
            final message = snapshot.error is ApiException
                ? (snapshot.error! as ApiException).message
                : 'Unable to load KYC information.';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _refresh, child: const Text('Retry')),
                ]),
              ),
            );
          }

          final kyc = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _StatusCard(snapshot: kyc),
                if (kyc.reviewReason?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Administrator note',
                    text: kyc.reviewReason!,
                  ),
                ],
                const SizedBox(height: 18),
                const Text('Required evidence', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ...kyc.requirements.map((requirement) => Card(
                      child: ListTile(
                        leading: Icon(
                          requirement.satisfied ? Icons.check_circle : Icons.pending_outlined,
                          color: requirement.satisfied ? AppColors.success : AppColors.primary,
                        ),
                        title: Text(_pretty(requirement.key), style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          requirement.satisfied
                              ? '${requirement.matchingDocumentCount} document(s) supplied'
                              : 'Accepted: ${requirement.acceptedTypes.map(_pretty).join(', ')}',
                        ),
                        trailing: kyc.canEdit && !requirement.satisfied
                            ? TextButton(onPressed: _busy ? null : () => _addEvidence(requirement), child: const Text('Add'))
                            : null,
                      ),
                    )),
                const SizedBox(height: 18),
                const Text('Uploaded documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                if (kyc.documents.isEmpty)
                  const _InfoCard(icon: Icons.description_outlined, title: 'No evidence yet', text: 'Add the required documents above to complete your KYC application.')
                else
                  ...kyc.documents.map((document) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: Text(_pretty(document.documentType), style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text([
                            document.originalFileName,
                            if (document.documentNumberLast4 != null) '•••• ${document.documentNumberLast4}',
                          ].whereType<String>().join('\n')),
                          trailing: kyc.canEdit
                              ? IconButton(
                                  onPressed: _busy ? null : () => _deleteDocument(document),
                                  icon: const Icon(Icons.delete_outline),
                                )
                              : const Icon(Icons.lock_outline),
                        ),
                      )),
                const SizedBox(height: 20),
                if (kyc.canEdit)
                  FilledButton.icon(
                    onPressed: _busy || !kyc.canSubmit ? null : () => _submit(kyc),
                    icon: _busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.verified_user_outlined),
                    label: Text(kyc.complete ? 'Submit KYC for review' : 'Complete all required evidence'),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                  ),
                if (kyc.isApproved)
                  FilledButton.icon(
                    onPressed: () => _continueToProviderDashboard(kyc),
                    icon: const Icon(Icons.dashboard_outlined),
                    label: const Text('Continue to provider dashboard'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.snapshot});
  final ProviderKycSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final approved = snapshot.isApproved;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: (approved ? AppColors.success : AppColors.primary).withOpacity(0.1),
          child: Icon(approved ? Icons.verified : Icons.verified_user_outlined, color: approved ? AppColors.success : AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_pretty(snapshot.status), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(_statusMessage(snapshot.status)),
        ])),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(text),
            ])),
          ]),
        ),
      );
}

String _pretty(String value) => value
    .split('_')
    .map((e) => e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1)}')
    .join(' ');

String _statusMessage(String status) {
  switch (status) {
    case 'not_submitted': return 'Upload the required evidence and submit your application.';
    case 'pending': return 'Your KYC is waiting in the administrative review queue.';
    case 'under_review': return 'An administrator is currently reviewing your evidence.';
    case 'approved': return 'Your provider identity is verified and service access is enabled.';
    case 'resubmission_required': return 'Update the requested evidence and submit KYC again.';
    case 'rejected': return 'This KYC application was rejected. Contact support if you need further review.';
    case 'suspended': return 'KYC approval is suspended. Review the administrator note or contact support.';
    default: return 'KYC status is being processed.';
  }
}

String _mimeFromName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  return 'image/jpeg';
}
