import 'ui.dart';
import 'widgets/app_bar.dart';
import 'widgets/center.dart';
import 'widgets/checkbox.dart';
import 'widgets/choice_chip.dart';
import 'widgets/column.dart';
import 'widgets/elevated_button.dart';
import 'widgets/expanded.dart';
import 'widgets/floating_action_button.dart';
import 'widgets/icon.dart';
import 'widgets/icon_button.dart';
import 'widgets/if_widget.dart';
import 'widgets/list_tile.dart';
import 'widgets/list_view.dart';
import 'widgets/padding.dart';
import 'widgets/row.dart';
import 'widgets/scaffold.dart';
import 'widgets/sized_box.dart';
import 'widgets/text.dart';
import 'widgets/text_button.dart';
import 'widgets/text_field.dart';
import 'widgets/wrap.dart';

/// Catalog widget name -> builder. Every key of `widgetCatalog` (spec.dart)
/// must be here, and vice versa (enforced by test/catalog_test.dart).
const widgetBuilders = <String, UiWidgetBuilder>{
  // Layout
  'scaffold': buildScaffold,
  'appBar': buildAppBar,
  'column': buildColumn,
  'row': buildRow,
  'wrap': buildWrap,
  'expanded': buildExpanded,
  'center': buildCenter,
  'padding': buildPadding,
  'sizedBox': buildSizedBox,

  // Content
  'text': buildText,
  'icon': buildIcon,
  'listView': buildListView,
  'listTile': buildListTile,
  'if': buildIf,

  // Input
  'textField': buildTextField,
  'checkbox': buildCheckbox,
  'choiceChip': buildChoiceChip,
  'iconButton': buildIconButton,
  'textButton': buildTextButton,
  'elevatedButton': buildElevatedButton,
  'floatingActionButton': buildFloatingActionButton,
};
