# More Widget Types

The MVP supports a tiny fixed vocabulary:

- `stack`
- `center`
- `aligned.<alignment>`
- `text`
- `button`

## Future widget support

- `row`, `column`, `listView`, `gridView`
- `textField`, `checkbox`, `switch`, `slider`
- `image`, `icon`, `spacer`, `divider`
- Layout widgets: `padding`, `sizedBox`, `expanded`, `flexible`
- Navigation widgets: `appBar`, `bottomNavigationBar`, `drawer`

## Design considerations

- Keep the YAML vocabulary small and framework-agnostic where possible.
- Map each vocabulary entry to a clear Flutter widget.
- Allow custom widgets by referencing other UI specs (already partially supported).
