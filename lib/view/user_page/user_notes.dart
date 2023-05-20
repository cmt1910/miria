import 'package:flutter/material.dart';
import 'package:miria/providers.dart';
import 'package:miria/view/common/account_scope.dart';
import 'package:miria/view/common/misskey_notes/misskey_note.dart';
import 'package:miria/view/common/pushable_listview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:misskey_dart/misskey_dart.dart';

class UserNotes extends ConsumerStatefulWidget {
  final String userId;

  const UserNotes({super.key, required this.userId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => UserNotesState();
}

class UserNotesState extends ConsumerState<UserNotes> {
  final notes = <Note>[];

  Misskey get misskey => ref.read(misskeyProvider(AccountScope.of(context)));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future(() async {
      notes
        ..clear()
        ..addAll(await misskey.users
            .notes(UsersNotesRequest(userId: widget.userId)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return PushableListView<Note>(initializeFuture: () async {
      final notes =
          await misskey.users.notes(UsersNotesRequest(userId: widget.userId));
      if (!mounted) return [];
      ref.read(notesProvider(AccountScope.of(context))).registerAll(notes);
      return notes.toList();
    }, nextFuture: (lastElement) async {
      final notes = await misskey.users.notes(
          UsersNotesRequest(userId: widget.userId, untilId: lastElement.id));
      if (!mounted) return [];
      ref.read(notesProvider(AccountScope.of(context))).registerAll(notes);
      return notes.toList();
    }, itemBuilder: (context, element) {
      return MisskeyNote(note: element);
    });
  }
}