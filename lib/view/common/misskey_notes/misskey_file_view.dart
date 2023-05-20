import 'package:flutter/material.dart';
import 'package:misskey_dart/misskey_dart.dart';

import 'network_image.dart';

class MisskeyFileView extends StatelessWidget {
  final List<DriveFile> files;

  final double height;

  const MisskeyFileView({
    super.key,
    required this.files,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final targetFiles = files.where((e) => e.thumbnailUrl != null);

    if (targetFiles.isEmpty) {
      return Container();
    } else if (targetFiles.length == 1) {
      final targetFile = targetFiles.first;
      return Center(
        child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: height),
            child: MisskeyImage(
              isSensitive: targetFile.isSensitive,
              url: targetFile.url.toString(),
              thumbnailUrl:
                  (targetFile.thumbnailUrl ?? targetFile.url).toString(),
            )),
      );
    } else {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final targetFile in targetFiles)
            SizedBox(
              height: height,
              child: MisskeyImage(
                isSensitive: targetFile.isSensitive,
                url: targetFile.url.toString(),
                //mimeType: targetFile.type,
                thumbnailUrl:
                    (targetFile.thumbnailUrl ?? targetFile.url).toString(),
              ),
            ),
        ],
      );
    }
  }
}

class MisskeyImage extends StatefulWidget {
  final bool isSensitive;
  final String thumbnailUrl;
  final String url;
  //final String mimeType;

  const MisskeyImage({
    super.key,
    required this.isSensitive,
    required this.thumbnailUrl,
    required this.url,
    //required this.mimeType,
  });

  @override
  State<MisskeyImage> createState() => MisskeyImageState();
}

class MisskeyImageState extends State<MisskeyImage> {
  var nsfwAccepted = false;
  Widget? cachedWidget;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: () {
      if (widget.isSensitive && !nsfwAccepted) {
        setState(() {
          nsfwAccepted = true;
        });
        return;
      } else {
        showDialog(
            context: context,
            builder: (context) => ImageDialog(imageUrl: widget.url));
      }
    }, child: Builder(
      builder: (context) {
        if (widget.isSensitive && !nsfwAccepted) {
          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: Container(
              decoration: const BoxDecoration(color: Colors.black54),
              width: double.infinity,
              child: Center(
                  child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_rounded, color: Colors.white),
                  const Padding(padding: EdgeInsets.only(left: 5)),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "閲覧注意",
                        style: TextStyle(color: Colors.white),
                      ),
                      Text(
                        "タップして表示",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.fontSize),
                      )
                    ],
                  ),
                ],
              )),
            ),
          );
        }

        if (cachedWidget != null) {
          return cachedWidget!;
        }

        return FutureBuilder(
          future: Future.delayed(Duration(milliseconds: 100)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              cachedWidget = SizedBox(
                height: 200,
                child: NetworkImageView(
                  url: widget.thumbnailUrl,
                  type: ImageType.imageThumbnail,
                  loadingBuilder: (context, widget, chunkEvent) => SizedBox(
                    width: double.infinity,
                    height: 200,
                    child: widget,
                  ),
                ),
              );
              return cachedWidget!;
            }
            return Container();
          },
        );
      },
    ));
  }
}

class ImageDialog extends StatelessWidget {
  final String imageUrl;

  const ImageDialog({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      titlePadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      actionsPadding: EdgeInsets.zero,
      insetPadding: EdgeInsets.zero,
      title: Container(
        decoration:
            BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.close))
          ],
        ),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.95,
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}