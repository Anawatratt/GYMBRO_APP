import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_state.dart';
import '../mock_data.dart';

class NotesScreen extends ConsumerWidget {
  /// If [viewUid] is set, shows notes in read-only mode for that user.
  final String? viewUid;
  const NotesScreen({super.key, this.viewUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = viewUid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    final readOnly = viewUid != null;
    final notesAsync = ref.watch(notesProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: readOnly
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.people_outline),
                  tooltip: 'Friends',
                  onPressed: () => _showFriendsSheet(context),
                ),
              ],
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notes) => notes.isEmpty
            ? _EmptyState(
                onAdd: readOnly ? null : () => _showNoteSheet(context, ref, uid))
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: GridView.builder(
                  itemCount: notes.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, i) {
                    final note = notes[i];
                    return _NoteCard(
                      note: note,
                      onTap: readOnly
                          ? () {}
                          : () => _showNoteSheet(context, ref, uid,
                              note: note),
                      onLongPress: readOnly
                          ? () {}
                          : () =>
                              _confirmDelete(context, ref, uid, note.id),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: readOnly
          ? null
          : FloatingActionButton(
              onPressed: () =>
                  _showNoteSheet(context, ref, uid),
              backgroundColor: const Color(0xFFE53935),
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, String uid, String noteId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              deleteNoteFs(uid, noteId);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showNoteSheet(BuildContext context, WidgetRef ref, String uid,
      {Note? note}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _NoteEditorSheet(note: note, uid: uid),
    );
  }

  void _showFriendsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _FriendsSheet(),
    );
  }
}

// ── Empty state ──────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback? onAdd;
  const _EmptyState({this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sticky_note_2_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No notes yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500])),
          const SizedBox(height: 8),
          if (onAdd != null)
            Text('Tap + to add your first note',
                style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        ],
      ),
    );
  }
}

// ── Note card ────────────────────────────────────────────

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _NoteCard(
      {required this.note, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: note.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(note.title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Expanded(
              child: Text(note.body,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 8),
            Text(
              '${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Note editor sheet ────────────────────────────────────

class _NoteEditorSheet extends StatefulWidget {
  final Note? note;
  final String uid;

  const _NoteEditorSheet({this.note, required this.uid});

  @override
  State<_NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<_NoteEditorSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late Color _selectedColor;
  bool _saving = false;
  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
    _bodyCtrl = TextEditingController(text: widget.note?.body ?? '');
    _selectedColor = widget.note?.color ?? noteColors[0];
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_isEditing ? 'Edit Note' : 'New Note',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              hintText: 'Title',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyCtrl,
            decoration: const InputDecoration(
              hintText: 'Write your note...',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 14),
          Row(
            children: noteColors
                .map((c) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedColor = c),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: c,
                          child: _selectedColor == c
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.black54)
                              : null,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(_isEditing ? 'Update' : 'Save Note'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty && body.isEmpty) return;

    setState(() => _saving = true);

    if (_isEditing) {
      await updateNoteFs(widget.uid, widget.note!.id,
          title: title, body: body, color: _selectedColor);
    } else {
      final note = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.isEmpty ? 'Untitled' : title,
        body: body,
        color: _selectedColor,
        createdAt: DateTime.now(),
      );
      await addNoteFs(widget.uid, note);
    }

    if (mounted) Navigator.pop(context);
  }
}

// ── Friends sheet ────────────────────────────────────────

class _FriendsSheet extends ConsumerStatefulWidget {
  const _FriendsSheet();

  @override
  ConsumerState<_FriendsSheet> createState() => _FriendsSheetState();
}

class _FriendsSheetState extends ConsumerState<_FriendsSheet> {
  final _searchCtrl = TextEditingController();
  String? _message;
  bool _messageIsError = false;
  bool _loading = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _addFriend() async {
    final username = _searchCtrl.text.trim();
    if (username.isEmpty) return;

    setState(() {
      _loading = true;
      _message = null;
    });

    final error =
        await ref.read(authNotifierProvider.notifier).addFriend(username);

    if (!mounted) return;
    setState(() {
      _loading = false;
      _messageIsError = error != null;
      _message = error ?? 'Friend added!';
    });

    if (error == null) _searchCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(userProfileProvider).value?.friends ?? [];
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Friends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),

          // Add friend row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _addFriend(),
                  decoration: InputDecoration(
                    hintText: 'Enter username',
                    prefixIcon: const Icon(Icons.person_search_outlined),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _addFriend,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Add'),
                ),
              ),
            ],
          ),

          if (_message != null) ...[
            const SizedBox(height: 8),
            Text(
              _message!,
              style: TextStyle(
                color:
                    _messageIsError ? Colors.red[400] : Colors.green[700],
                fontSize: 13,
              ),
            ),
          ],

          const SizedBox(height: 20),

          if (friends.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text('No friends yet',
                  style:
                      TextStyle(color: Colors.grey[400], fontSize: 14)),
            )
          else ...[
            Text(
              '${friends.length} friend${friends.length == 1 ? '' : 's'}',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: friends.length,
                itemBuilder: (ctx, i) => _FriendTile(uid: friends[i]),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// ── Friend tile (tappable → friend profile) ──────────────

class _FriendTile extends StatelessWidget {
  final String uid;
  const _FriendTile({required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final name = data?['name'] as String? ?? uid;
        final username = data?['username'] as String? ?? '';
        final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFE53935),
            child: Text(initials,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          title: Text(name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: username.isNotEmpty ? Text('@$username') : null,
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () {
            Navigator.pop(context); // close the sheet
            Navigator.pushNamed(
              context,
              '/friendProfile',
              arguments: {'uid': uid, 'name': name},
            );
          },
        );
      },
    );
  }
}
