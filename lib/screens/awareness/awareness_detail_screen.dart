import 'package:digital_life_care_app/providers/awareness_provider.dart';
import 'package:digital_life_care_app/widgets/app_brand.dart';
import 'package:flutter/material.dart';

class AwarenessDetailScreen extends StatefulWidget {
  const AwarenessDetailScreen({super.key});

  @override
  State<AwarenessDetailScreen> createState() => _AwarenessDetailScreenState();
}

class _AwarenessDetailScreenState extends State<AwarenessDetailScreen> {
  int _score = 0;

  @override
  Widget build(BuildContext context) {
    final topic = ModalRoute.of(context)!.settings.arguments as AwarenessTopic;
    return Scaffold(
      appBar: AppBar(
        title: Text(topic.title),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: AppBrand.compact(logoSize: 28),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(topic.content),
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('Symptoms'),
              children: topic.symptoms
                  .map((e) => ListTile(title: Text(e)))
                  .toList(),
            ),
            ExpansionTile(
              title: const Text('Common Myths'),
              children: topic.myths
                  .map((e) => ListTile(title: Text(e)))
                  .toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final result = await showDialog<int>(
                  context: context,
                  builder: (ctx) {
                    int localScore = 0;
                    int selected = -1;
                    return StatefulBuilder(
                      builder: (ctx, setState) {
                        return AlertDialog(
                          title: const Text('Quick Quiz'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'HIV can be transmitted through casual contact?',
                              ),
                              RadioListTile<int>(
                                value: 0,
                                groupValue: selected,
                                onChanged: (v) => setState(() => selected = v!),
                                title: const Text('True'),
                              ),
                              RadioListTile<int>(
                                value: 1,
                                groupValue: selected,
                                onChanged: (v) => setState(() => selected = v!),
                                title: const Text('False'),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: selected == -1
                                  ? null
                                  : () {
                                      if (selected == 1)
                                        localScore = 1; // correct
                                      Navigator.pop(ctx, localScore);
                                    },
                              child: const Text('Submit'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
                if (result != null) {
                  if (!mounted) return;
                  setState(() => _score = result);
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    SnackBar(content: Text('Score: $_score/1')),
                  );
                }
              },
              child: const Text('Take Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
