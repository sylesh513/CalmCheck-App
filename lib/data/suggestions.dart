/// Tappable starting points for the two hardest fields on a care card.
/// Someone writing a card at a kitchen table rarely knows where to begin —
/// these are common, plainly-worded steps they can add and then edit.
library;

import 'package:flutter/foundation.dart';

@immutable
class SuggestionGroup {
  const SuggestionGroup(this.label, this.items);

  final String label;
  final List<String> items;
}

const List<SuggestionGroup> doSuggestions = [
  SuggestionGroup('How to be with them', [
    'Keep your voice low and slow.',
    "Sit down so you're at eye level.",
    'Say your name and how you know them.',
    'Give it ten minutes before trying anything else.',
    'Stay where they can see you.',
  ]),
  SuggestionGroup('The room', [
    'Turn the overhead light off and use a lamp.',
    'Turn the television or radio down.',
    'Ask other people to step out.',
    'Open a window.',
  ]),
  SuggestionGroup('If they collapse or seize', [
    'Time it.',
    'Turn them on their side.',
    'Put something soft under their head.',
    'Stay until they are fully awake and tell them where they are.',
  ]),
];

const List<SuggestionGroup> dontSuggestions = [
  SuggestionGroup("Don't do", [
    "Don't hold them down.",
    "Don't put anything in their mouth.",
    "Don't move them to another room.",
    "Don't stand behind them.",
  ]),
  SuggestionGroup("Don't say", [
    "Don't correct them about the date or ask if they remember you.",
    "Don't ask questions that need more than a yes or no.",
    "Don't tell them to calm down.",
    "Don't rush them.",
  ]),
];
