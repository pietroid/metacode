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
| `listView` | ListView | `children` | `scrollDirection`, `shrinkWrap`; or `itemBuilder`, `itemCount` |
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
- Prefer the simplest constructor form when possible (`Image.network(...)`, `ListView(children: ...)`, etc.).
