import 'package:flutter/material.dart';

class CustomPlanScreen extends StatefulWidget {
  const CustomPlanScreen({super.key});

  @override
  State<CustomPlanScreen> createState() => _CustomPlanScreenState();
}

class _CustomPlanScreenState extends State<CustomPlanScreen> {
  final TextEditingController _nameController = TextEditingController();
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  int _selectedDay = 0;

  final List<Map<String, String>> _exercises = [
    {'name': 'Plank', 'sets': '3 x 60s', 'muscle': 'Core'},
    {'name': 'Dumbbell Rows', 'sets': '3 x 10', 'muscle': 'Back'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Plan')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Create and customize your own workout program',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Plan name',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _days.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == _selectedDay;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDay = index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFE53935)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            _days[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: _exercises.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _exercises[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name']!,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE53935)
                                            .withAlpha(25),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        item['muscle']!,
                                        style: const TextStyle(
                                          color: Color(0xFFE53935),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      item['sets']!,
                                      style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon:
                                Icon(Icons.edit, color: Colors.grey[400], size: 20),
                          ),
                          IconButton(
                            onPressed: () =>
                                setState(() => _exercises.removeAt(index)),
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent, size: 20),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _exercises.add({
                          'name': 'New Exercise',
                          'sets': '3 x 8',
                          'muscle': 'Core',
                        }));
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text('+ Add Exercise',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text('Save Plan',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
