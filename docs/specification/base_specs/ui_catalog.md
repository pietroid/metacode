# Common UI

Catalog of UI elements that is used on metacode for now.

This catalog follows the UI spec format: each component is a key, its value is a nested mapping, and the `child` / `children` syntax sugars apply whenever possible.

## Components

| Symbol | Flutter widget | Default content | Common props |
|---|---|---|---|
| `appBar` | AppBar | `title` | `actions`, `leading` |
| `scaffold` | Scaffold | `body` | `appBar`, `body`, `floatingActionButton`, `bottomNavigationBar`, `drawer` |
| `text` | Text | `data` | — |
| `elevatedButton` | ElevatedButton | `child` | `onPressed` |
| `textButton` | TextButton | `child` | `onPressed` |
| `iconButton` | IconButton | `icon` | `onPressed`, `tooltip` |
| `floatingActionButton` | FloatingActionButton | `child` | `onPressed`, `tooltip` |
| `card` | Card | `child` | — |
| `listTile` | ListTile | `title` | `leading`, `subtitle`, `trailing`, `onTap` |
| `listView` | ListView | `children` | `scrollDirection`, `shrinkWrap`; or `items`, `item` |
| `column` | Column | `children` | `mainAxisAlignment`, `crossAxisAlignment` |
| `row` | Row | `children` | `mainAxisAlignment`, `crossAxisAlignment` |
| `stack` | Stack | `children` | `alignment` |
| `container` | Container | `child` | `width`, `height`, `padding`, `margin` |
| `padding` | Padding | `child` | `padding` |
| `center` | Center | `child` | — |
| `sizedBox` | SizedBox | `child` | `width`, `height` |
| `expanded` | Expanded | `child` | `flex` |
| `icon` | Icon | `icon` | `size`, `color` |
| `image` | Image | `image` / `src` | `width`, `height`, `fit` |
| `textField` | TextField | — | `controller`, `onChanged`, `decoration`, `obscureText`, `keyboardType` |
| `checkbox` | Checkbox | — | `value`, `onChanged` |
| `radio` | Radio | — | `value`, `groupValue`, `onChanged` |
| `switch` | Switch | — | `value`, `onChanged` |
| `slider` | Slider | — | `value`, `min`, `max`, `onChanged` |
| `dropdownButton` | DropdownButton | — | `value`, `items`, `onChanged`, `hint` |
| `bottomNavigationBar` | BottomNavigationBar | — | `currentIndex`, `onTap`, `items` |
| `tabBar` | TabBar | — | `tabs`, `controller` |
| `alertDialog` | AlertDialog | `content` | `title`, `actions` |
| `circularProgressIndicator` | CircularProgressIndicator | — | `value` |

## Prop types

Every prop in the catalog declares what it holds, and a variable written under
that prop takes its type. This is what tells a generator that `value: taskDone`
on a checkbox is a boolean and `onChanged: taskToggled` is a handler, instead of
assuming a bare name is text.

| Type | Holds |
|---|---|
| `text` | a string |
| `boolean` | true or false |
| `number` | a number |
| `list` | a collection |
| `widget` / `widgets` | one widget, or a list of them |
| `icon` | a name from the icon vocabulary |
| `any` | anything the target accepts |
| `callback` | an event handler taking nothing |
| `callback(text)`, `callback(boolean)`, `callback(number)`, `callback(any)` | a handler carrying that value |

A bare name under a widget prop is text, because it renders as text. The one
exception is a variable a behavior compares to a widget, which holds a widget.

The type of each prop lives with its catalog entry in
`engine/internal/specs/ui/catalog/definitions.go`.

## Icons

Icons are their own vocabulary, written `icons.<name>`. The names are Metacode's
own: where one matches Material that is a coincidence worth keeping, and where
it does not, the mapping column is what moves. A second target changes the
mapping and leaves every spec alone.

| Symbol | Flutter |
|---|---|
| `icons.add` | Icons.add |
| `icons.remove` | Icons.remove |
| `icons.close` | Icons.close |
| `icons.check` | Icons.check |
| `icons.success` | Icons.check_circle |
| `icons.cancel` | Icons.cancel |
| `icons.edit` | Icons.edit |
| `icons.delete` | Icons.delete |
| `icons.save` | Icons.save |
| `icons.copy` | Icons.content_copy |
| `icons.send` | Icons.send |
| `icons.share` | Icons.share |
| `icons.search` | Icons.search |
| `icons.filter` | Icons.filter_list |
| `icons.sort` | Icons.sort |
| `icons.refresh` | Icons.refresh |
| `icons.menu` | Icons.menu |
| `icons.home` | Icons.home |
| `icons.settings` | Icons.settings |
| `icons.person` | Icons.person |
| `icons.login` | Icons.login |
| `icons.logout` | Icons.logout |
| `icons.lock` | Icons.lock |
| `icons.favorite` | Icons.favorite |
| `icons.star` | Icons.star |
| `icons.visible` | Icons.visibility |
| `icons.hidden` | Icons.visibility_off |
| `icons.notification` | Icons.notifications |
| `icons.mail` | Icons.mail |
| `icons.phone` | Icons.phone |
| `icons.camera` | Icons.camera_alt |
| `icons.image` | Icons.image |
| `icons.attachment` | Icons.attach_file |
| `icons.download` | Icons.download |
| `icons.upload` | Icons.upload |
| `icons.calendar` | Icons.calendar_today |
| `icons.clock` | Icons.access_time |
| `icons.location` | Icons.location_on |
| `icons.cart` | Icons.shopping_cart |
| `icons.play` | Icons.play_arrow |
| `icons.pause` | Icons.pause |
| `icons.stop` | Icons.stop |
| `icons.warning` | Icons.warning |
| `icons.error` | Icons.error |
| `icons.info` | Icons.info |
| `icons.help` | Icons.help |
| `icons.arrowBack` | Icons.arrow_back |
| `icons.arrowForward` | Icons.arrow_forward |
| `icons.arrowUp` | Icons.arrow_upward |
| `icons.arrowDown` | Icons.arrow_downward |
| `icons.chevronLeft` | Icons.chevron_left |
| `icons.chevronRight` | Icons.chevron_right |
| `icons.moreVertical` | Icons.more_vert |
| `icons.moreHorizontal` | Icons.more_horiz |

## Usage notes

- **Symbol** is the key used in the UI spec. It maps to a Flutter Material widget.
- **Default content** means a direct child (`widget`) or list (`- widget`) can be written as syntax sugar for that prop. For example:
  ```yaml
  text: "Hello"
  ```
  is sugar for:
  ```yaml
  text:
    data: "Hello"
  ```
  and:
  ```yaml
  column:
    - text: "A"
    - text: "B"
  ```
  is sugar for:
  ```yaml
  column:
    children:
      - text:
          data: "A"
      - text:
          data: "B"
  ```
- Only functional / layout props are listed.
- Styling props (`style`, `theme`, `colors`, `elevation`, etc.) are intentionally omitted; they should come from another spec.
- An `icon` prop takes a name from the icon vocabulary below, qualified with `icons.`. A bare name stays what it is everywhere else in the spec, a variable, so `icon: icons.add` is the Material add icon and `icon: currentIcon` is something to bind. An unqualified or unknown name is an error. To put an icon in a button, nest it in the child slot:
  ```yaml
  addTaskButton:
    floatingActionButton:
      child:
        icon: icons.add
  ```
- A `listView` is either static or dynamic. Static means `children`, a list of widgets. Dynamic means `items`, the variable holding the collection, plus `item`, the widget built once per element:
  ```yaml
  taskList:
    listView:
      items: visibleTasks
      item: taskTile
  ```
  The names follow the pair the spec already has: `child` is one widget, `children` is many widgets, `items` is many values, `item` is the one widget per value. There is no `itemCount`, because the count is the length of `items` and stating it would state the same fact twice. A row is addressed from a behavior by `.first` or `.last`.
- Prefer the simplest constructor form when possible (`Image.network(...)`, `ListView(children: ...)`, etc.).
