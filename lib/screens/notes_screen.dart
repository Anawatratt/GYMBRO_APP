import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note.dart';
import '../models/friend.dart';
import '../providers/auth_provider.dart';
import '../providers/note_provider.dart';
import '../providers/friend_provider.dart';

class NotesScreen extends ConsumerWidget {
  final String? viewUid;
  const NotesScreen({super.key, this.viewUid});

  bool get _isViewOnly => viewUid != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = _isViewOnly
        ? ref.watch(notesByUidProvider(viewUid!))
        : ref.watch(notesStreamProvider);
    final me = ref.watch(currentUserDocProvider).value;

    return Scaffold(
      appBar: _isViewOnly
          ? null
          : AppBar(
        title: const Text('Notes'),
        bottom: me != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(20),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "${me.displayName}'s Notes",
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notes) {
          if (notes.isEmpty) {
            return _isViewOnly
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sticky_note_2_outlined,
                            size: 56, color: Color(0xFF3A3A3C)),
                        SizedBox(height: 12),
                        Text('No notes yet',
                            style: TextStyle(
                                color: Color(0xFF6B6B6B), fontSize: 15)),
                      ],
                    ),
                  )
                : _EmptyState(
                    onAdd: () => _showNoteSheet(context, ref, me?.uid));
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: GridView.builder(
              itemCount: notes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, i) {
                final note = notes[i];
                return _NoteCard(
                  note: note,
                  onTap: _isViewOnly
                      ? () {}
                      : () => _showNoteSheet(context, ref, me?.uid, note: note),
                  onLongPress: _isViewOnly
                      ? () {}
                      : () => _confirmDelete(context, ref, me?.uid, note.id),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: _isViewOnly
          ? null
          : FloatingActionButton(
              onPressed: () => _showNoteSheet(context, ref, me?.uid),
              backgroundColor: const Color(0xFFE53935),
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String? uid, String noteId) {
    if (uid == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(noteServiceProvider).deleteNote(uid, noteId);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showNoteSheet(BuildContext context, WidgetRef ref, String? uid, {Note? note}) {
    if (uid == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _NoteEditorSheet(uid: uid, note: note, ref: ref),
    );
  }
}

// ── Empty state ─────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sticky_note_2_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No notes yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[500])),
          const SizedBox(height: 8),
          Text('Tap + to add your first note',
              style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('New Note'),
          ),
        ],
      ),
    );
  }
}

// ── Note card (post-it style) ────────────────────────────

const _noteColors = [
  Color(0xFFFFF9C4),
  Color(0xFFB3E5FC),
  Color(0xFFC8E6C9),
  Color(0xFFF8BBD0),
  Color(0xFFFFE0B2),
];

Color _noteColor(Note note) {
  final idx = note.id.hashCode.abs() % _noteColors.length;
  return _noteColors[idx];
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _NoteCard({required this.note, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final color = _noteColor(note);
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Friend tag badge
            if (note.hasTag) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, size: 11, color: Color(0xFF333333)),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        '@${note.taggedFriendName}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(note.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Expanded(
              child: Text(note.content,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 6),
            Text(
              '${note.updatedAt.day}/${note.updatedAt.month}/${note.updatedAt.year}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Note editor bottom sheet ──────────────────────────────

class _NoteEditorSheet extends StatefulWidget {
  final String uid;
  final Note? note;
  final WidgetRef ref;

  const _NoteEditorSheet({required this.uid, this.note, required this.ref});

  @override
  State<_NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<_NoteEditorSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  bool get _isEditing => widget.note != null;
  bool _saving = false;

  String? _taggedFriendUid;
  String? _taggedFriendName;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
    _contentCtrl = TextEditingController(text: widget.note?.content ?? '');
    _taggedFriendUid = widget.note?.taggedFriendUid;
    _taggedFriendName = widget.note?.taggedFriendName;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFriend() async {
    final friends = widget.ref.read(friendsStreamProvider).value ?? [];
    final accepted = friends.where((f) => f.status == 'accepted').toList();

    if (accepted.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No friends yet. Add friends first!')),
        );
      }
      return;
    }

    final picked = await showModalBottomSheet<Friend>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FriendPickerSheet(friends: accepted),
    );

    if (picked != null && mounted) {
      setState(() {
        _taggedFriendUid = picked.friendUid;
        _taggedFriendName = picked.displayName;
      });
    }
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
          Row(
            children: [
              Text(_isEditing ? 'Edit Note' : 'New Note',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              hintText: 'Title',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentCtrl,
            decoration: const InputDecoration(
              hintText: 'Write your note...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 12),

          // Tag friend row
          Row(
            children: [
              const Text('Tag:', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(width: 8),
              if (_taggedFriendUid != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3F51B5).withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF3F51B5).withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person, size: 13, color: Color(0xFF3F51B5)),
                      const SizedBox(width: 4),
                      Text(
                        '@$_taggedFriendName',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3F51B5),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() {
                          _taggedFriendUid = null;
                          _taggedFriendName = null;
                        }),
                        child: const Icon(Icons.close, size: 14, color: Color(0xFF3F51B5)),
                      ),
                    ],
                  ),
                )
              else
                GestureDetector(
                  onTap: _pickFriend,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.alternate_email, size: 14, color: Color(0xFF9E9E9E)),
                        const SizedBox(width: 4),
                        Text('Tag a friend',
                            style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_isEditing ? 'Update Note' : 'Save Note'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty && content.isEmpty) return;

    setState(() => _saving = true);
    try {
      final svc = widget.ref.read(noteServiceProvider);
      final t = title.isEmpty ? 'Untitled' : title;
      final clearTag = _taggedFriendUid == null && (widget.note?.taggedFriendUid != null);
      if (_isEditing) {
        await svc.updateNote(
          widget.uid, widget.note!.id, t, content,
          taggedFriendUid: _taggedFriendUid,
          taggedFriendName: _taggedFriendName,
          clearTag: clearTag,
        );
      } else {
        await svc.addNote(
          widget.uid, t, content,
          taggedFriendUid: _taggedFriendUid,
          taggedFriendName: _taggedFriendName,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _saving = false);
      }
    }
  }
}

// ── Friend picker sheet ──────────────────────────────────

class _FriendPickerSheet extends StatelessWidget {
  final List<Friend> friends;
  const _FriendPickerSheet({required this.friends});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A3C),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Tag a Friend',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Select a friend to tag in this note',
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 12),
          ...friends.map((f) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF3F51B5).withAlpha(40),
              child: Text(
                f.displayName.isNotEmpty ? f.displayName[0].toUpperCase() : '?',
                style: const TextStyle(color: Color(0xFF3F51B5), fontWeight: FontWeight.w700),
              ),
            ),
            title: Text(f.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text(f.email,
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            onTap: () => Navigator.pop(context, f),
          )),
        ],
      ),
    );
  }
}
