import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miria/extensions/text_editing_controller_extension.dart';
import 'package:miria/model/account.dart';
import 'package:miria/model/misskey_emoji_data.dart';
import 'package:miria/providers.dart';
import 'package:miria/view/common/misskey_notes/custom_emoji.dart';
import 'package:miria/view/reaction_picker_dialog/reaction_picker_dialog.dart';

final _filteredEmojisProvider = NotifierProvider.autoDispose.family<
    _FilteredEmojis, List<MisskeyEmojiData>, (Account, TextEditingController)>(
  _FilteredEmojis.new,
);

class _FilteredEmojis extends AutoDisposeFamilyNotifier<List<MisskeyEmojiData>,
    (Account, TextEditingController)> {
  @override
  List<MisskeyEmojiData> build((Account, TextEditingController) arg) {
    _controller.addListener(_updateEmojis);
    ref.onDispose(() {
      _controller.removeListener(_updateEmojis);
    });
    return ref.read(emojiRepositoryProvider(_account)).defaultEmojis();
  }

  Account get _account {
    return arg.$1;
  }

  TextEditingController get _controller {
    return arg.$2;
  }

  void _updateEmojis() async {
    state = await ref
        .read(emojiRepositoryProvider(_account))
        .searchEmojis(_controller.emojiSearchValue);
  }
}

class EmojiKeyboard extends ConsumerWidget {
  const EmojiKeyboard({
    super.key,
    required this.account,
    required this.controller,
    required this.focusNode,
  });

  final Account account;
  final TextEditingController controller;
  final FocusNode focusNode;

  void insertEmoji(MisskeyEmojiData emoji, WidgetRef ref) {
    final currentPosition = controller.selection.base.offset;
    final text = controller.text;

    final beforeSearchText =
        text.substring(0, text.substring(0, currentPosition).lastIndexOf(":"));

    final after = (currentPosition == text.length || currentPosition == -1)
        ? ""
        : text.substring(currentPosition, text.length);

    switch (emoji) {
      case CustomEmojiData():
        controller.value = TextEditingValue(
          text: "$beforeSearchText:${emoji.baseName}:$after",
          selection: TextSelection.collapsed(
            offset: beforeSearchText.length + emoji.baseName.length + 2,
          ),
        );
        break;
      case UnicodeEmojiData():
        controller.value = TextEditingValue(
          text: "$beforeSearchText${emoji.char}$after",
          selection: TextSelection.collapsed(offset: emoji.char.length),
        );
        break;
      default:
        return;
    }
    focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredEmojis =
        ref.watch(_filteredEmojisProvider((account, controller)));

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (final emoji in filteredEmojis)
          GestureDetector(
            onTap: () => insertEmoji(emoji, ref),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: SizedBox(
                height: 32 * MediaQuery.of(context).textScaleFactor,
                child: CustomEmoji(emojiData: emoji),
              ),
            ),
          ),
        TextButton.icon(
          onPressed: () async {
            final selected = await showDialog(
              context: context,
              builder: (context2) => ReactionPickerDialog(
                account: account,
                isAcceptSensitive: true,
              ),
            );
            if (selected != null) {
              insertEmoji(selected, ref);
            }
          },
          icon: const Icon(Icons.add_reaction_outlined),
          label: const Text("他のん"),
        ),
      ],
    );
  }
}
