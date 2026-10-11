import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../shared/data/community_repository.dart';

class ProductReviews extends StatelessWidget {
  const ProductReviews({
    super.key,
    required this.repository,
    required this.productId,
  });
  final CommunityRepository repository;
  final String productId;

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: repository.productReviews(productId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Reviews are unavailable. Please try again.');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final reviews = snapshot.data!.docs.map((d) => d.data()).toList()
            ..sort(
              (a, b) => (b['createdAt'] as Timestamp? ?? Timestamp(0, 0))
                  .compareTo(a['createdAt'] as Timestamp? ?? Timestamp(0, 0)),
            );
          final average = reviews.isEmpty
              ? 0.0
              : reviews.fold<double>(
                      0,
                      (total, r) => total + (r['rating'] as num).toDouble(),
                    ) /
                    reviews.length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Customer reviews',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (reviews.isEmpty)
                const Text('No reviews yet.')
              else
                Text(
                  '★ ${average.toStringAsFixed(1)} · ${reviews.length} reviews',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              for (final review in reviews)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          for (var i = 1; i <= 5; i++)
                            Icon(
                              i <= (review['rating'] as num)
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 18,
                              color: const Color(0xFF91620E),
                            ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'Verified purchase',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(review['comment'] as String),
                      if (review['createdAt'] is Timestamp)
                        Text(
                          (review['createdAt'] as Timestamp)
                              .toDate()
                              .toLocal()
                              .toString()
                              .split(' ')
                              .first,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      const Divider(),
                    ],
                  ),
                ),
            ],
          );
        },
      );
}
