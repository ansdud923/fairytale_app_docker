
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FeatureCard extends StatelessWidget {
  final Color color;
  final String iconPath;
  final String title;
  final VoidCallback onPressed;
  final bool isWide;
  final bool isDark;

  const FeatureCard({
    required this.color,
    required this.iconPath,
    required this.title,
    required this.onPressed,
    this.isWide = false,
    this.isDark = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: isWide
            ? Row(
          children: [
            Expanded(
              child: Image.asset(
                iconPath,
                width: 48,
                height: 48,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      isDark ? Colors.white24 : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      minimumSize: Size(64, 32),
                      padding: EdgeInsets.zero,
                      elevation: 0,
                    ),
                    child: Text(
                      'START',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              iconPath,
              width: 48,
              height: 48,
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                isDark ? Colors.white24 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                minimumSize: Size(64, 32),
                padding: EdgeInsets.zero,
                elevation: 0,
              ),
              child: Text(
                'START',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}