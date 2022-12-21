import 'dart:io';

import 'package:calcupiano/design/dialog.dart';
import 'package:calcupiano/design/multiplatform.dart';
import 'package:calcupiano/events.dart';
import 'package:calcupiano/foundation.dart';
import 'package:calcupiano/platform/platform.dart';
import 'package:calcupiano/r.dart';
import 'package:calcupiano/ui/import.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:rettulf/rettulf.dart';

import '../db.dart';

const double _iconSize = 36;

class SoundpackPage extends StatefulWidget {
  const SoundpackPage({super.key});

  @override
  State<SoundpackPage> createState() => _SoundpackPageState();
}

class _SoundpackPageState extends State<SoundpackPage> with LockOrientationMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: "Soundpack".text(),
        centerTitle: context.isCupertino,
        actions: [
          PullDownButton(
            itemBuilder: (context) => [
              PullDownMenuItem(
                icon: Icons.create,
                title: 'Create Soundpack',
                onTap: () {},
              ),
              const PullDownMenuDivider(),
              PullDownMenuTitle(
                title: "Import Soundpack".text(),
              ),
              PullDownMenuActionsRow.medium(
                items: [
                  PullDownMenuItem(
                    enabled: false,
                    onTap: () {},
                    title: 'Link',
                    icon: Icons.link,
                  ),
                  if (!kIsWeb)
                    PullDownMenuItem(
                      onTap: () async {
                        await importSoundpackFromFilePicker();
                      },
                      title: 'Local File',
                      icon: Icons.storage,
                    )
                ],
              )
            ],
            position: PullDownMenuPosition.automatic,
            buttonBuilder: (context, showMenu) => IconButton(
              onPressed: showMenu,
              icon: const Icon(
                CupertinoIcons.ellipsis_circle,
                size: 28,
              ),
            ),
          )
        ],
      ),
      body: buildBody(),
    );
  }

  Future<void> importSoundpackFromFilePicker() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    final path = result?.files.single.path;
    if (path != null) {
      await context.showWaiting(after: Future.delayed(Duration(seconds: 5)),title: "Waiting");
    }
  }

  @ListenTo([K.customSoundpackIdList])
  Widget buildBody() {
    return H.listenToCustomSoundpackIdList() <<
        (ctx, _, c) {
          return buildSoundpackList(ctx);
        };
  }

  @ListenTo([K.customSoundpackIdList])
  Widget buildSoundpackList(BuildContext ctx) {
    const builtinList = R.builtinSoundpacks;
    final customList = H.customSoundpackIdList ?? const [];
    return ListView.builder(
      itemCount: builtinList.length + customList.length,
      physics: const RangeMaintainingScrollPhysics(),
      itemBuilder: (ctx, index) {
        if (index < builtinList.length) {
          return BuiltinSoundpackItem(
            soundpack: builtinList[index],
          );
        } else {
          return CustomSoundpackItem(id: customList[index - builtinList.length - 1]);
        }
      },
    );
  }
}

class BuiltinSoundpackItem extends StatefulWidget {
  final BuiltinSoundpack soundpack;

  const BuiltinSoundpackItem({
    super.key,
    required this.soundpack,
  });

  @override
  State<BuiltinSoundpackItem> createState() => _BuiltinSoundpackItemState();
}

class _BuiltinSoundpackItemState extends State<BuiltinSoundpackItem> {
  BuiltinSoundpack get soundpack => widget.soundpack;

  @override
  Widget build(BuildContext context) {
    return buildCardWithContextMenu(context);
  }

  @ListenTo([K.currentSoundpackID])
  Widget buildCardWithContextMenu(BuildContext ctx) {
    return H.listenToCurrentSoundpackID() <<
        (ctx, _, __) {
          final isSelected = H.currentSoundpackID == soundpack.id;
          return CupertinoContextMenu.builder(
              actions: [
                if (!isSelected)
                  CupertinoContextMenuAction(
                    trailingIcon: CupertinoIcons.checkmark,
                    child: "Use".text(),
                    onPressed: () {
                      ctx.navigator.pop();
                      eventBus.fire(SoundpackChangeEvent(soundpack));
                    },
                  ),
                CupertinoContextMenuAction(
                  trailingIcon: CupertinoIcons.ear,
                  child: "Preview".text(),
                ),
              ],
              builder: (ctx, anim) {
                return buildCard(ctx, isSelected);
              });
        };
  }

  @ListenTo([K.currentSoundpackID])
  Widget buildCard(BuildContext ctx, bool isSelected) {
    return ListTile(
      leading: _buildSoundpackSwitchIcon(isSelected, soundpack),
      selected: isSelected,
      titleTextStyle: ctx.textTheme.headlineSmall,
      title: soundpack.name.text(),
      subtitle: soundpack.description.text(),
      trailing: Icon(Icons.navigate_next_rounded),
    ).inCard();
  }
}

class CustomSoundpackItem extends StatefulWidget {
  final String id;

  const CustomSoundpackItem({
    super.key,
    required this.id,
  });

  @override
  State<CustomSoundpackItem> createState() => _CustomSoundpackItemState();
}

class _CustomSoundpackItemState extends State<CustomSoundpackItem> {
  ExternalSoundpackProtocol? _soundpack;

  @override
  void initState() {
    super.initState();
    _soundpack = H.soundpacks.getSoundpackById(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    final soundpack = _soundpack;
    if (soundpack != null) {
      return buildCardWithContextMenu(context, soundpack);
    } else {
      return buildCorruptedSoundpack(context);
    }
  }

  @ListenTo([K.currentSoundpackID])
  Widget buildCardWithContextMenu(BuildContext ctx, ExternalSoundpackProtocol soundpack) {
    return H.listenToCurrentSoundpackID() <<
        (ctx, _, __) {
          final isSelected = H.currentSoundpackID == soundpack.id;
          return CupertinoContextMenu.builder(
              actions: [
                if (!isSelected)
                  CupertinoContextMenuAction(
                    trailingIcon: CupertinoIcons.checkmark,
                    child: "Use".text(),
                    onPressed: () {
                      ctx.navigator.pop();
                      eventBus.fire(SoundpackChangeEvent(soundpack));
                    },
                  ),
                CupertinoContextMenuAction(
                  trailingIcon: CupertinoIcons.delete,
                  isDestructiveAction: true,
                  child: "Delete".text(),
                ),
                CupertinoContextMenuAction(
                  trailingIcon: CupertinoIcons.pencil,
                  isDestructiveAction: true,
                  child: "Edit".text(),
                ),
              ],
              builder: (ctx, anim) {
                return buildCard(ctx, isSelected, soundpack);
              });
        };
  }

  @ListenTo([K.currentSoundpackID])
  Widget buildCard(BuildContext ctx, bool isSelected, ExternalSoundpackProtocol soundpack) {
    return ListTile(
      leading: _buildSoundpackSwitchIcon(isSelected, soundpack),
      selected: isSelected,
      titleTextStyle: ctx.textTheme.headlineSmall,
      //title: soundpack.name.text(),
      // subtitle: soundpack.description.text(),
      trailing: Icon(Icons.navigate_next_rounded),
    ).inCard();
  }

  Widget buildCorruptedSoundpack(BuildContext ctx) {
    return ListTile(
      leading: Icon(Icons.sentiment_very_dissatisfied_outlined),
      title: "Corrupted Soundpack".text(),
    );
  }
}

Widget _buildSoundpackSwitchIcon(bool isSelected, SoundpackProtocol soundpack) {
  return AnimatedSwitcher(
    duration: const Duration(milliseconds: 500),
    switchInCurve: Curves.fastLinearToSlowEaseIn,
    child: isSelected
        ? const Icon(Icons.done, size: _iconSize)
        : const Icon(
            Icons.radio_button_off_rounded,
            size: _iconSize,
          ).onTap(() {
            eventBus.fire(SoundpackChangeEvent(soundpack));
          }),
  );
}
