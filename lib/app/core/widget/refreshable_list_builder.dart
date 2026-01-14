import 'package:baby_vax/app/config/constant/app_constant.dart';
import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class RefreshableListBuilder extends StatelessWidget {
  final ScrollPhysics? physics;
  final Future<void> Function()? onRefresh;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;
  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;

  const RefreshableListBuilder(
      {super.key,
      required this.itemBuilder,
      required this.itemCount,
      this.physics,
      this.shrinkWrap = true,
      this.onRefresh,
      this.padding});

  @override
  Widget build(BuildContext context) {
    final scrollView = CustomScrollView(
      physics: physics,
      shrinkWrap: shrinkWrap,
      slivers: [
        if (defaultTargetPlatform == TargetPlatform.iOS &&
            onRefresh != null) ...[
          CupertinoSliverRefreshControl(onRefresh: onRefresh!)
        ],
        SliverPadding(
          padding: padding ?? AppConstant.columnPadding,
          sliver: SliverList(
              delegate: SliverChildBuilderDelegate(itemBuilder,
                  childCount: itemCount)),
        )
      ],
    );
    if (defaultTargetPlatform == TargetPlatform.android && onRefresh != null) {
      return RefreshIndicator(onRefresh: onRefresh!, child: scrollView);
    }
    return scrollView;
  }
}
