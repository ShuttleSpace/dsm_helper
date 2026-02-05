import 'package:garden/widgets/moments/category_item_widget.dart';
import 'package:flutter/material.dart';

class CategoryCardWidget extends StatelessWidget {
  final List photos;
  final String title;
  final double albumWidth;
  final VoidCallback? onTap;

  const CategoryCardWidget({
    super.key,
    required this.photos,
    required this.title,
    required this.albumWidth,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: albumWidth,
              height: albumWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Wrap(
                runSpacing: 2,
                spacing: 2,
                children: [
                  ...List.generate(4, (index) {
                    return CategoryItemWidget(
                      photos: photos,
                      index: index,
                      albumWidth: albumWidth,
                    );
                  })
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 14),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}