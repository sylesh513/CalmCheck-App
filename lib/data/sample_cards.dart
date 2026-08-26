/// Sample card content — the same two cards used in every mockup. Card 1 seeds
/// a first-run library so the concept lands before anyone has typed anything.
library;

import '../models/care_card.dart';

CareCardData get ravi => CareCardData(
  id: 'sample-ravi',
  name: 'Ravi',
  relation: 'grandfather',
  livesWith: 'Vascular dementia. Gets disoriented in the late afternoon.',
  doThis: const [
    'Keep your voice low and slow.',
    "Sit down so you're at eye level.",
    'Say your name and how you know him.',
    'Put the radio on — cricket commentary settles him.',
    'Give it ten minutes before trying anything else.',
  ],
  dontDo: const [
    "Don't correct him about the year or ask if he remembers you.",
    "Don't stand behind him.",
    "Don't turn the overhead lights on after dark — use the lamp.",
  ],
  call: const [
    CareContact(
      name: 'Priya',
      relationship: 'daughter',
      number: '07700 900 118',
    ),
    CareContact(name: 'Dr Menon', relationship: 'GP', number: '020 7946 0231'),
  ],
  medications: 'Amlodipine 5 mg, morning. Atorvastatin 20 mg, night.',
  triggers:
      'Late afternoon light. Being rushed. More than one person talking at once.',
  notes:
      'Keys live in the bowl by the door. He will ask for them; he isn’t going out.',
  version: 3,
  preparedAt: DateTime(2026, 3, 4),
);

CareCardData get aanya => CareCardData(
  id: 'sample-aanya',
  name: 'Aanya',
  relation: 'age 9',
  doThis: const [
    'Time the seizure.',
    'Turn her on her side.',
    'Put something soft under her head.',
    "Stay until she's fully awake and tell her where she is.",
  ],
  dontDo: const [
    "Don't hold her down.",
    "Don't put anything in her mouth.",
    "Don't give food or water until she's fully alert.",
  ],
  call: const [
    CareContact(name: 'Mum', relationship: 'Sonia', number: '07700 900 461'),
    CareContact(name: 'Dad', relationship: 'Vik', number: '07700 900 887'),
    CareContact(
      name: 'School nurse',
      relationship: 'Brookmead Primary',
      number: '020 7946 0410',
    ),
  ],
  version: 2,
  preparedAt: DateTime(2026, 2, 19),
);

/// What a brand-new install starts with. Nothing is invented for the user —
/// these are examples they can read, edit, or delete.
List<CareCardData> starterCards() => [ravi, aanya];
