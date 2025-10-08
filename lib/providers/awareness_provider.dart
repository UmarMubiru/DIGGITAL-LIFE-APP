import 'package:flutter/foundation.dart';

class AwarenessTopic {
  final String title;
  final String content;
  final List<String> myths;
  final List<String> symptoms;
  AwarenessTopic({required this.title, required this.content, required this.myths, required this.symptoms});
}

class AwarenessProvider extends ChangeNotifier {
  final List<AwarenessTopic> _topics = [
    AwarenessTopic(
      title: 'HIV',
      content: 'Basics about HIV prevention and treatment.',
      myths: ['You can get HIV from hugging (False)', 'Only certain people are at risk (False)'],
      symptoms: ['Fever', 'Sore throat', 'Fatigue'],
    ),
    AwarenessTopic(
      title: 'Syphilis',
      content: 'Recognize stages and testing importance.',
      myths: ['It goes away on its own (False)'],
      symptoms: ['Sores', 'Rash', 'Fever'],
    ),
  ];

  String _query = '';

  List<AwarenessTopic> get topics {
    if (_query.isEmpty) return List.unmodifiable(_topics);
    return _topics.where((t) => t.title.toLowerCase().contains(_query.toLowerCase())).toList(growable: false);
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }
}


