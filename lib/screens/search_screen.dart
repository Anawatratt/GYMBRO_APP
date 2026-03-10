import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../utils/storage_image.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF111111),
        appBar: AppBar(
          title: const Text('Search'),
          bottom: const TabBar(
            labelColor: Color(0xFFE53935),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFE53935),
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            tabs: [
              Tab(
                icon: Icon(Icons.fitness_center, size: 20),
                text: 'Exercises',
              ),
              Tab(
                icon: Icon(Icons.precision_manufacturing, size: 20),
                text: 'Machines',
              ),
            ],
          ),
        ),
        body: const TabBarView(children: [_ExercisesTab(), _MachinesTab()]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Exercises Tab
// ═══════════════════════════════════════════════════════════

class _ExercisesTab extends StatefulWidget {
  const _ExercisesTab();

  @override
  State<_ExercisesTab> createState() => _ExercisesTabState();
}

class _ExercisesTabState extends State<_ExercisesTab> {
  String _query = '';
  String? _selectedMuscleGroup;
  String? _selectedDifficulty;
  String? _selectedMovement;

  late final Stream<QuerySnapshot> _stream =
      FirebaseFirestore.instance.collection('exercises').snapshots();

  List<QueryDocumentSnapshot>? _cachedDocs;
  bool _preloading = false;
  int _preloadDone = 0;
  int _preloadTotal = 0;

  Future<void> _preload(List<QueryDocumentSnapshot> docs) async {
    if (_preloading || _cachedDocs != null) return;
    setState(() {
      _preloading = true;
      _preloadTotal = docs.length;
      _preloadDone = 0;
    });
    final urls = await Future.wait(docs.map((d) => getStorageUrl(exerciseImagePath(d.id))));
    if (!mounted) return;
    await Future.wait(urls.map((url) async {
      if (url != null) await DefaultCacheManager().getSingleFile(url);
      if (mounted) setState(() => _preloadDone++);
    }));
    if (mounted) setState(() { _cachedDocs = docs; _preloading = false; });
  }

  final _muscleGroups = [
    'All',
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Legs',
    'Core',
  ];
  final _difficulties = ['All', 'beginner', 'intermediate', 'advanced'];
  final _movements = ['All', 'compound', 'isolated'];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: _SearchBar(
              hint: 'Search exercises...',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 10),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: 'Muscle',
                    icon: Icons.sports_gymnastics,
                    items: _muscleGroups,
                    selected: _selectedMuscleGroup,
                    onChanged: (v) => setState(() => _selectedMuscleGroup = v),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Difficulty',
                    icon: Icons.speed,
                    items: _difficulties,
                    selected: _selectedDifficulty,
                    onChanged: (v) => setState(() => _selectedDifficulty = v),
                    displayTransform: _capitalize,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Movement',
                    icon: Icons.swap_horiz,
                    items: _movements,
                    selected: _selectedMovement,
                    onChanged: (v) => setState(() => _selectedMovement = v),
                    displayTransform: _capitalize,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Results
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _cachedDocs == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No exercises found'));
                }

                // Trigger preload once
                if (_cachedDocs == null && !_preloading) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _preload(snapshot.data!.docs),
                  );
                }

                // Show preload progress
                if (_preloading || _cachedDocs == null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 160,
                          child: LinearProgressIndicator(
                            value: _preloadTotal > 0
                                ? _preloadDone / _preloadTotal
                                : null,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Loading images... $_preloadDone / $_preloadTotal',
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                final docs = _cachedDocs!.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['exercise_name'] ?? '') as String;
                  final matchQuery =
                      _query.isEmpty ||
                      name.toLowerCase().contains(_query.toLowerCase());

                  final muscles =
                      data['muscle_involvements'] as List<dynamic>? ?? [];
                  final primaryMuscleNames = muscles
                      .where((m) => m['involvement_type'] == 'primary')
                      .map((m) => (m['muscle_name'] as String).toLowerCase())
                      .toList();
                  final matchMuscle =
                      _selectedMuscleGroup == null ||
                      _selectedMuscleGroup == 'All' ||
                      _muscleInGroup(primaryMuscleNames, _selectedMuscleGroup!);

                  final matchDiff =
                      _selectedDifficulty == null ||
                      _selectedDifficulty == 'All' ||
                      data['difficulty_level'] == _selectedDifficulty;

                  final matchMove =
                      _selectedMovement == null ||
                      _selectedMovement == 'All' ||
                      data['movement_type'] == _selectedMovement;

                  return matchQuery && matchMuscle && matchDiff && matchMove;
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No matching exercises',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _ExerciseCard(data: data, docId: doc.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _muscleInGroup(List<String> muscleNames, String group) {
    const groupMap = {
      'Chest': ['pectoralis major', 'pectoralis minor'],
      'Back': ['latissimus dorsi', 'trapezius', 'rhomboids', 'erector spinae'],
      'Shoulders': ['anterior deltoid', 'lateral deltoid', 'posterior deltoid'],
      'Arms': [
        'biceps brachii',
        'triceps brachii',
        'brachialis',
        'forearm flexors',
        'forearm extensors',
      ],
      'Legs': ['quadriceps', 'hamstrings', 'glutes', 'calves', 'adductors'],
      'Core': ['rectus abdominis', 'obliques', 'transverse abdominis'],
    };
    final names = groupMap[group] ?? [];
    return muscleNames.any((n) => names.contains(n));
  }
}

// ═══════════════════════════════════════════════════════════
// Machines Tab
// ═══════════════════════════════════════════════════════════

class _MachinesTab extends StatefulWidget {
  const _MachinesTab();

  @override
  State<_MachinesTab> createState() => _MachinesTabState();
}

class _MachinesTabState extends State<_MachinesTab> {
  String _query = '';
  String? _selectedMachineType;

  late final Stream<QuerySnapshot> _stream =
      FirebaseFirestore.instance.collection('machines').snapshots();

  List<QueryDocumentSnapshot>? _cachedDocs;
  bool _preloading = false;
  int _preloadDone = 0;
  int _preloadTotal = 0;

  Future<void> _preload(List<QueryDocumentSnapshot> docs) async {
    if (_preloading || _cachedDocs != null) return;
    setState(() {
      _preloading = true;
      _preloadTotal = docs.length;
      _preloadDone = 0;
    });
    final urls = await Future.wait(docs.map((d) => getStorageUrl(machineImagePath(d.id))));
    if (!mounted) return;
    await Future.wait(urls.map((url) async {
      if (url != null) await DefaultCacheManager().getSingleFile(url);
      if (mounted) setState(() => _preloadDone++);
    }));
    if (mounted) setState(() { _cachedDocs = docs; _preloading = false; });
  }

  final _machineTypes = [
    'All',
    'free_weight',
    'machine',
    'cable',
    'bodyweight',
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: _SearchBar(
              hint: 'Search machines...',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 10),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: 'Type',
                    icon: Icons.category,
                    items: _machineTypes,
                    selected: _selectedMachineType,
                    onChanged: (v) => setState(() => _selectedMachineType = v),
                    displayTransform: _formatSnakeCase,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Results
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _cachedDocs == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No machines found'));
                }

                if (_cachedDocs == null && !_preloading) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _preload(snapshot.data!.docs),
                  );
                }

                if (_preloading || _cachedDocs == null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 160,
                          child: LinearProgressIndicator(
                            value: _preloadTotal > 0
                                ? _preloadDone / _preloadTotal
                                : null,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Loading images... $_preloadDone / $_preloadTotal',
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                final docs = _cachedDocs!.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['equipment_name'] ?? '') as String;
                  final matchQuery =
                      _query.isEmpty ||
                      name.toLowerCase().contains(_query.toLowerCase());

                  final matchType =
                      _selectedMachineType == null ||
                      _selectedMachineType == 'All' ||
                      data['equipment_type'] == _selectedMachineType;

                  return matchQuery && matchType;
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No matching machines',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _MachineCard(data: data, docId: doc.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Shared Widgets
// ═══════════════════════════════════════════════════════════

class _SearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
          filled: true,
          fillColor: const Color(0xFF1C1C1E),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<String> items;
  final String? selected;
  final ValueChanged<String?> onChanged;
  final String Function(String)? displayTransform;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.items,
    required this.selected,
    required this.onChanged,
    this.displayTransform,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = selected != null && selected != 'All';
    return PopupMenuButton<String>(
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => items
          .map(
            (item) => PopupMenuItem(
              value: item,
              child: Text(
                displayTransform != null ? displayTransform!(item) : item,
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE53935) : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFFE53935) : const Color(0xFF2C2C2E),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : Colors.grey[500],
            ),
            const SizedBox(width: 6),
            Text(
              isActive
                  ? (displayTransform != null
                        ? displayTransform!(selected!)
                        : selected!)
                  : label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.grey[400],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: isActive ? Colors.white : Colors.grey[500],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Exercise Card
// ═══════════════════════════════════════════════════════════

class _ExerciseCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _ExerciseCard({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final name = data['exercise_name'] ?? '';
    final diff = data['difficulty_level'] ?? '';
    final moveType = data['movement_type'] ?? '';
    final isCompound = data['is_compound'] == true;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _showExerciseDetail(context);
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Left: image
            SizedBox(
              width: 110,
              height: 100,
              child: StorageImage(
                key: ValueKey(docId),
                storagePath: exerciseImagePath(docId),
                width: 110,
                height: 100,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                cropTop: 20,
                placeholder: Container(
                  color: const Color(0xFF252525),
                  child: Icon(
                    isCompound ? Icons.fitness_center : Icons.track_changes,
                    size: 32,
                    color: const Color(0xFF6B6B6B),
                  ),
                ),
              ),
            ),
            // Right: info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (diff.isNotEmpty) _pill(_capitalize(diff)),
                        if (moveType.isNotEmpty) _pill(_capitalize(moveType)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF9E9E9E),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _mutedPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF9E9E9E),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showExerciseDetail(BuildContext context) {
    final name = data['exercise_name'] ?? '';
    final desc = data['description'] ?? '';
    final diff = data['difficulty_level'] ?? '';
    final pattern = data['movement_pattern'] ?? '';
    final muscles = data['muscle_involvements'] as List<dynamic>? ?? [];
    final equipment = data['equipment'] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3C),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(desc, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              children: [
                _mutedPill(_capitalize(diff)),
                const SizedBox(width: 8),
                _mutedPill(_formatSnakeCase(pattern)),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Muscles',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...muscles.map((m) {
              final pct = (m['activation_percentage'] ?? 0) as num;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        m['muscle_name'] ?? '',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct / 100,
                          minHeight: 8,
                          backgroundColor: const Color(0xFF2C2C2E),
                          valueColor: AlwaysStoppedAnimation(
                            _involvementColor(m['involvement_type'] ?? ''),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$pct%',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }),
            if (equipment.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Equipment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: equipment.map<Widget>((e) {
                  final name = e['equipment_name'] as String? ?? '';
                  return Chip(
                    label: Text(name, style: const TextStyle(fontSize: 13)),
                    backgroundColor: const Color(0xFF252525),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _involvementColor(String involvement) {
    switch (involvement) {
      case 'primary':
        return const Color(0xFFE53935);
      case 'secondary':
        return const Color(0xFF00897B);
      case 'stabilizer':
        return const Color(0xFFFF9800);
      default:
        return Colors.grey;
    }
  }
}

// ═══════════════════════════════════════════════════════════
// Machine Card
// ═══════════════════════════════════════════════════════════

class _MachineCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _MachineCard({required this.data, required this.docId});

  IconData _typeIcon(String type) {
    switch (type) {
      case 'free_weight':
        return Icons.fitness_center;
      case 'machine':
        return Icons.precision_manufacturing;
      case 'cable':
        return Icons.cable;
      case 'bodyweight':
        return Icons.self_improvement;
      default:
        return Icons.devices_other;
    }
  }


  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF9E9E9E),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = data['equipment_name'] ?? '';
    final type = data['equipment_type'] ?? '';

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // Left: image
          SizedBox(
            width: 110,
            height: 100,
            child: StorageImage(
              key: ValueKey(docId),
              storagePath: machineImagePath(docId),
              width: 110,
              height: 100,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              cropTop: 20,
              placeholder: Container(
                color: const Color(0xFF252525),
                child: Icon(_typeIcon(type), size: 32, color: const Color(0xFF6B6B6B)),
              ),
            ),
          ),
          // Right: info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (type.isNotEmpty) _pill(_formatSnakeCase(type)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _formatSnakeCase(String s) {
  if (s == 'All') return s;
  return s
      .split('_')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}
