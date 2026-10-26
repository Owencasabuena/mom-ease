/// Represents a gentle journaling prompt to inspire postpartum reflection.
class JournalPrompt {
  final String id;
  final String textEn;
  final String textTl;
  final String category;
  final List<String> moodTags;

  const JournalPrompt({
    required this.id,
    required this.textEn,
    required this.textTl,
    required this.category,
    required this.moodTags,
  });

  String localizedText(String lang) => lang == 'tl' ? textTl : textEn;

  Map<String, dynamic> toMap() => {
        'id': id,
        'textEn': textEn,
        'textTl': textTl,
        'category': category,
        'moodTags': moodTags,
      };

  factory JournalPrompt.fromMap(Map<String, dynamic> map) => JournalPrompt(
        id: map['id'] as String,
        textEn: map['textEn'] as String,
        textTl: map['textTl'] as String,
        category: map['category'] as String,
        moodTags: List<String>.from(map['moodTags'] ?? []),
      );
}

/// Built-in prompts covering reflection, gratitude, self-care, support, and recovery.
const List<JournalPrompt> kDefaultJournalPrompts = [
  // General & Reflection
  JournalPrompt(
    id: 'prompt_001',
    textEn: 'What made today a little easier?',
    textTl: 'Ano ang nakatulong para maging mas magaan ang araw mo?',
    category: 'reflection',
    moodTags: ['happy', 'neutral'],
  ),
  JournalPrompt(
    id: 'prompt_002',
    textEn: 'What felt difficult today?',
    textTl: 'Ano ang naging mahirap para sa iyo ngayon?',
    category: 'reflection',
    moodTags: ['sad', 'verySad'],
  ),
  JournalPrompt(
    id: 'prompt_003',
    textEn: 'What do you need most right now?',
    textTl: 'Ano ang pinaka-kailangan mo ngayon?',
    category: 'self-care',
    moodTags: ['neutral', 'sad', 'verySad'],
  ),
  JournalPrompt(
    id: 'prompt_004',
    textEn: 'What is one thing you are proud of today?',
    textTl: 'Ano ang isang bagay na ipinagmamalaki mo ngayong araw?',
    category: 'gratitude',
    moodTags: ['veryHappy', 'happy'],
  ),
  JournalPrompt(
    id: 'prompt_005',
    textEn: 'Who supported you today?',
    textTl: 'Sino ang sumuporta sa iyo ngayon?',
    category: 'support',
    moodTags: ['happy', 'neutral', 'sad'],
  ),
  JournalPrompt(
    id: 'prompt_006',
    textEn: 'What helped you feel calm?',
    textTl: 'Ano ang nakatulong para kumalma ka?',
    category: 'self-care',
    moodTags: ['neutral', 'sad', 'verySad'],
  ),
  JournalPrompt(
    id: 'prompt_007',
    textEn: 'What would you like to remember about today?',
    textTl: 'Ano ang gusto mong maalala tungkol sa araw na ito?',
    category: 'bonding',
    moodTags: ['veryHappy', 'happy'],
  ),
  JournalPrompt(
    id: 'prompt_008',
    textEn: 'What is one small thing you can do for yourself tomorrow?',
    textTl: 'Ano ang maliit na bagay na maaari mong gawin para sa sarili mo bukas?',
    category: 'self-care',
    moodTags: ['neutral', 'sad'],
  ),

  // Mood-Specific Suggestions
  JournalPrompt(
    id: 'prompt_vh_01',
    textEn: 'What made today meaningful?',
    textTl: 'Ano ang nagbigay-kahulugan sa araw na ito?',
    category: 'reflection',
    moodTags: ['veryHappy'],
  ),
  JournalPrompt(
    id: 'prompt_h_01',
    textEn: 'What went well today?',
    textTl: 'Ano ang naging maganda ngayong araw?',
    category: 'gratitude',
    moodTags: ['happy'],
  ),
  JournalPrompt(
    id: 'prompt_h_02',
    textEn: 'What are you grateful for right now?',
    textTl: 'Ano ang ipinagpapasalamat mo ngayon?',
    category: 'gratitude',
    moodTags: ['happy', 'veryHappy'],
  ),
  JournalPrompt(
    id: 'prompt_n_01',
    textEn: 'How would you describe your day in a few words?',
    textTl: 'Paano mo ilalarawan ang iyong araw sa ilang salita?',
    category: 'reflection',
    moodTags: ['neutral'],
  ),
  JournalPrompt(
    id: 'prompt_s_01',
    textEn: 'Who could support you today if you reach out?',
    textTl: 'Sino ang maaaring sumuporta sa iyo kung lalapit ka ngayon?',
    category: 'support',
    moodTags: ['sad'],
  ),
  JournalPrompt(
    id: 'prompt_vs_01',
    textEn: 'What feels heaviest right now? Let it out here.',
    textTl: 'Ano ang pinakamabigat na nararamdaman mo ngayon? Ilabas mo rito.',
    category: 'support',
    moodTags: ['verySad'],
  ),
  JournalPrompt(
    id: 'prompt_vs_02',
    textEn: 'Is there someone you trust that you could talk to today?',
    textTl: 'May mapagkakatiwalaan ka bang tao na maaari mong makausap ngayon?',
    category: 'support',
    moodTags: ['verySad'],
  ),
];
