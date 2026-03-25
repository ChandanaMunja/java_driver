import 'package:flutter/material.dart';

class ExpandableAddressText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const ExpandableAddressText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  State<ExpandableAddressText> createState() =>
      _ExpandableAddressTextState();
}

class _ExpandableAddressTextState extends State<ExpandableAddressText> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: isExpanded ? null : 2,
          overflow:
          isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: widget.style,
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
          child: Text(
            isExpanded ? 'See less' : 'See more',
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}