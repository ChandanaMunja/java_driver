import 'package:jippydriver_driver/controllers/play_integrity_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PlayIntegrityStatusWidget extends StatelessWidget {
  const PlayIntegrityStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PlayIntegrityController>(
      init: PlayIntegrityController(),
      builder: (controller) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: controller.isIntegrityVerified.value 
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            border: Border.all(
              color: controller.isIntegrityVerified.value 
                  ? Colors.green 
                  : Colors.red,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    controller.isIntegrityVerified.value 
                        ? Icons.security 
                        : Icons.security_outlined,
                    color: controller.isIntegrityVerified.value 
                        ? Colors.green 
                        : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Play Integrity',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: controller.isIntegrityVerified.value 
                          ? Colors.green 
                          : Colors.red,
                    ),
                  ),
                  const Spacer(),
                  if (controller.isLoading.value)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Status: ${controller.integrityStatus.value}',
                style: const TextStyle(fontSize: 12),
              ),
              if (controller.isIntegrityVerified.value && 
                  controller.lastToken.value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Token: ${controller.lastToken.value.substring(0, 20)}...',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value 
                          ? null 
                          : () => controller.checkIntegrity(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text('Check', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value 
                          ? null 
                          : () => controller.refreshIntegrity(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text('Refresh', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
} 