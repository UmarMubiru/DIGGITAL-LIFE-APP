import 'package:digital_life_care_app/providers/awareness_provider.dart';
import 'package:digital_life_care_app/widgets/app_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AwarenessHomeScreen extends StatelessWidget {
  const AwarenessHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Awareness'), actions: const [Padding(padding: EdgeInsets.only(right: 12.0), child: AppBrand.compact(logoSize: 28))]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search topics'),
              onChanged: (v) => context.read<AwarenessProvider>().setQuery(v),
            ),
          ),
          Expanded(
            child: Consumer<AwarenessProvider>(
              builder: (context, provider, _) => GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 4 / 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: provider.topics.length,
                itemBuilder: (context, index) {
                  final t = provider.topics[index];
                  return InkWell(
                    onTap: () => Navigator.of(context).pushNamed('/awareness/detail', arguments: t),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.title, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Expanded(child: Text(t.content, maxLines: 3, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}


