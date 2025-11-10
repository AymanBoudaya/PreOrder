import 'package:caferesto/features/shop/models/category_model.dart';
import 'package:flutter/material.dart';

import '../../../utils/constants/sizes.dart';
import '../images/circular_image.dart';
import '../products/product_cards/widgets/rounded_container.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.showBorder,
    this.onTap,
    required this.category,
  });

  final CategoryModel category;
  final bool showBorder;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TRoundedContainer(
        padding: const EdgeInsets.all(AppSizes.sm),
        showBorder: showBorder,
        backgroundColor: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// Icone
            CircularImage(
              isNetworkImage: true,
              image: category.image,
              backgroundColor: Colors.transparent,
              width: 50,
              height: 50,
              padding: 2,
            ),
            const SizedBox(width: AppSizes.spaceBtwItems / 2),

            /// Texte
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final textStyle = screenWidth < 400
                          ? Theme.of(context).textTheme.bodyMedium
                          : screenWidth < 600
                              ? Theme.of(context).textTheme.bodyLarge
                              : Theme.of(context).textTheme.titleMedium;

                      return SizedBox(
                        width: constraints.maxWidth,
                        child: Text(
                          category.name,
                          style: textStyle?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                  if (category.isFeatured) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Vedette',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.amber.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

