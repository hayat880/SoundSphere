import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/ambient_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class AmbientScreen extends StatelessWidget {
  const AmbientScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      Theme(data: AppTheme.dark, child: const _AmbientBody());
}

class _AmbientBody extends StatefulWidget {
  const _AmbientBody();

  @override
  State<_AmbientBody> createState() => _AmbientBodyState();
}

class _AmbientBodyState extends State<_AmbientBody> {
  late final AmbientController _controller;

  @override
  void initState() {
    super.initState();
    _controller = context.read<AmbientController>();
  }

  @override
  void dispose() {
    // Sounds picked here are previewed live; they stop when you leave unless
    // a focus session is running, and start again with the next session.
    _controller.stopPreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ambient = context.watch<AmbientController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Ambient Sounds')),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'Tap a sound to add it to your mix, then set its volume. '
                'You hear them while you are here, and they play during every focus session.',
                style: TextStyle(color: AppColors.sage),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final s in ambient.sounds)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.only(left: 14, right: 8),
                      decoration: BoxDecoration(
                        color: ambient.isOn(s.id)
                            ? const Color(0xFF2B4128)
                            : AppColors.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: ambient.isOn(s.id)
                              ? AppColors.terracotta
                              : AppColors.darkBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: InkWell(
                              onTap: () => ambient.toggle(s.id),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  children: [
                                    Icon(s.icon,
                                        color: ambient.isOn(s.id)
                                            ? AppColors.terracotta
                                            : AppColors.sage),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(s.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 15)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Slider(
                              value: ambient.volumeOf(s.id),
                              onChanged: (v) => ambient.setVolume(s.id, v),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Use in focus session'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
