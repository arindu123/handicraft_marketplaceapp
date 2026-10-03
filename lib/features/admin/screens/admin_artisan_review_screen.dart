import '../../../shared/data/marketplace_repository.dart';
import 'package:flutter/material.dart';

import '../models/admin_demo_store.dart';
import '../widgets/admin_widgets.dart';

class AdminArtisanReviewScreen extends StatelessWidget {
  const AdminArtisanReviewScreen({
    super.key,
    required this.store,
    required this.artisan,
  });
  final AdminDemoStore store;
  final AdminDirectoryItem artisan;

  Future<void> _action(BuildContext context, {required bool verify}) async {
    final confirmed = await confirmAdminAction(
      context,
      verify
          ? 'Verify ${artisan.name}?'
          : artisan.active
          ? 'Pause ${artisan.name}?'
          : 'Reactivate ${artisan.name}?',
      MarketplaceBackend.enabled ? 'This updates the selected Firestore record.' : 'This updates only the selected sample profile in this preview session.',
    );
    if (!context.mounted || !confirmed) return;
    if (verify) {
      store.verifyArtisan(artisan);
    } else {
      store.toggleItem(artisan);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminStyle.cream,
    appBar: AppBar(
      title: const Text(
        'Artisan profile review',
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
      ),
      backgroundColor: AdminStyle.cream,
      foregroundColor: AdminStyle.navy,
      surfaceTintColor: Colors.transparent,
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              if (!artisan.isArtisan || !store.users.contains(artisan)) {
                return const AdminEmptyState(
                  'This record is not an artisan profile.',
                );
              }
              final applications = store.approvals.where(
                (a) => a.type == 'Artisan' && a.name == artisan.name,
              );
              final application = applications.isEmpty
                  ? null
                  : applications.first;
              final products = store.products
                  .where(
                    (p) => p.detail.split('·').first.trim() == artisan.name,
                  )
                  .toList();
              final location = artisan.detail
                  .split('·')
                  .skip(1)
                  .join('·')
                  .trim();
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    MarketplaceBackend.enabled ? 'ADMIN WORKSPACE' : 'DEMO WORKSPACE',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      color: AdminStyle.clay,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    MarketplaceBackend.enabled ? 'Changes are saved to the shared marketplace.' : 'Sample data only. Changes last for this preview session.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AdminStyle.muted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AdminPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 28,
                              backgroundColor: AdminStyle.cream,
                              foregroundColor: AdminStyle.clay,
                              child: Icon(Icons.person_outline, size: 30),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                artisan.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AdminStyle.navy,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _field('Shop / studio', artisan.name),
                        if (location.isNotEmpty) _field('Location', location),
                        const Text(
                          'Verification status',
                          style: TextStyle(
                            fontSize: 12,
                            color: AdminStyle.muted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AdminStatus(artisan.verification),
                        const SizedBox(height: 16),
                        const Text(
                          'Account status',
                          style: TextStyle(
                            fontSize: 12,
                            color: AdminStyle.muted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AdminStatus(artisan.active ? 'Active' : 'Paused'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  AdminPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AdminSectionHeading('Studio summary'),
                        const SizedBox(height: 14),
                        Text(
                          application?.description ?? 'Artisan studio listed in the Craftisan demo directory.',
                          style: const TextStyle(
                            color: AdminStyle.muted,
                            height: 1.5,
                          ),
                        ),
                        if (application != null) ...[
                          const SizedBox(height: 14),
                          _field(
                            'Application',
                            '${application.id} · ${application.status}',
                          ),
                        ],
                        const SizedBox(height: 14),
                        Text(
                          '${products.length} products in demo catalogue',
                          style: const TextStyle(
                            color: AdminStyle.navy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        for (final p in products)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              p.name,
                              style: const TextStyle(color: AdminStyle.muted),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (artisan.verification != 'Approved')
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AdminStyle.sage,
                          ),
                          onPressed: () => _action(context, verify: true),
                          child: const Text('Verify artisan'),
                        ),
                      TextButton(
                        onPressed: () => _action(context, verify: false),
                        child: Text(
                          artisan.active
                              ? 'Pause in demo'
                              : 'Reactivate in demo',
                          style: const TextStyle(color: AdminStyle.clay),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Users'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );

  Widget _field(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AdminStyle.muted),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(color: AdminStyle.navy, height: 1.5),
        ),
      ],
    ),
  );
}
