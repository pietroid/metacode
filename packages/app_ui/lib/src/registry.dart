import 'package:flutter/widgets.dart';

import 'clickable.dart';
import 'ui.dart';
import 'widgets/app_bar.dart';
import 'widgets/avatar.dart';
import 'widgets/card.dart';
import 'widgets/center.dart';
import 'widgets/checkbox.dart';
import 'widgets/choice_chip.dart';
import 'widgets/column.dart';
import 'widgets/container.dart';
import 'widgets/divider.dart';
import 'widgets/dropdown.dart';
import 'widgets/elevated_button.dart';
import 'widgets/expanded.dart';
import 'widgets/filled_button.dart';
import 'widgets/floating_action_button.dart';
import 'widgets/grid_view.dart';
import 'widgets/icon.dart';
import 'widgets/icon_button.dart';
import 'widgets/if_widget.dart';
import 'widgets/image.dart';
import 'widgets/list_tile.dart';
import 'widgets/list_view.dart';
import 'widgets/marquee.dart';
import 'widgets/match.dart';
import 'widgets/module.dart';
import 'widgets/navigation_bar.dart';
import 'widgets/outlined_button.dart';
import 'widgets/padding.dart';
import 'widgets/progress.dart';
import 'widgets/responsive.dart';
import 'widgets/row.dart';
import 'widgets/scaffold.dart';
import 'widgets/scroll.dart';
import 'widgets/sized_box.dart';
import 'widgets/slider.dart';
import 'widgets/spacer.dart';
import 'widgets/stack.dart';
import 'widgets/tappable.dart';
import 'widgets/text.dart';
import 'widgets/text_button.dart';
import 'widgets/text_field.dart';
import 'widgets/toggle.dart';
import 'widgets/wrap.dart';

/// Catalog widget name -> builder. Every key of `widgetCatalog` (spec.dart)
/// must be here, and vice versa (enforced by test/catalog_test.dart).
const widgetBuilders = <String, UiWidgetBuilder>{
  // Layout
  'scaffold': buildScaffold,
  'appBar': buildAppBar,
  'column': buildColumn,
  'row': buildRow,
  'stack': buildStack,
  'wrap': buildWrap,
  'expanded': buildExpanded,
  'spacer': buildSpacer,
  'center': buildCenter,
  'padding': buildPadding,
  'sizedBox': buildSizedBox,
  'container': buildContainer,
  'responsive': buildResponsive,
  'module': buildModule,
  'card': buildCard,
  'scroll': buildScroll,
  'divider': buildDivider,

  // Navigation
  'match': buildMatch,
  'navigationBar': buildNavigationBar,

  // Content
  'text': buildText,
  'icon': buildIcon,
  'image': buildImage,
  'avatar': buildAvatar,
  'marquee': buildMarquee,
  'progress': buildProgress,
  'listView': buildListView,
  'gridView': buildGridView,
  'listTile': buildListTile,
  'if': buildIf,

  // Input
  'textField': buildTextField,
  'checkbox': buildCheckbox,
  'toggle': buildToggle,
  'slider': buildSlider,
  'dropdown': buildDropdown,
  'choiceChip': buildChoiceChip,
  'iconButton': buildIconButton,
  'filledButton': buildFilledButton,
  'outlinedButton': buildOutlinedButton,
  'textButton': buildTextButton,
  'elevatedButton': buildElevatedButton,
  'floatingActionButton': buildFloatingActionButton,
  'tappable': buildTappable,
};

/// Builds the catalog widget [type] (null when there is none); a clickable
/// one (see [isClickable]) gets a pointer cursor and keeps its text out of
/// the text selection ([Clickable]). Engines build every widget with this.
Widget? buildCatalogWidget(Ui ui, String type, Map<String, dynamic> props) {
  final builder = widgetBuilders[type];
  if (builder == null) return null;
  final widget = builder(ui, props);
  return isClickable(ui, type, props) ? Clickable(child: widget) : widget;
}
