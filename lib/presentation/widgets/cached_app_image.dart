import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'loading_widget.dart';

class CachedAppImage extends StatelessWidget {
  const CachedAppImage({
    required this.imageUrl,
    required this.semanticLabel,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String imageUrl;
  final String semanticLabel;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        placeholder: (context, url) => const LoadingWidget(itemCount: 1),
        errorWidget: (context, url, error) => const Icon(Icons.broken_image),
      ),
    );
  }
}
