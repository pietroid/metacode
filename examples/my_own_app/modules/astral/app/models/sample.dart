// sample: test fixtures. `app` runs actions and values like the engine;
// `sample(...)` builds a State (every field has a default: born 12 August,
// the reading not started).
import '../../.generated/state.dart';
import '../../.generated/test_app.dart';

/// Runs actions and values through the compiled program, like the engine.
final app = TestApp();

Localized _l(String en, String ptBr) => Localized(en: en, ptBr: ptBr);

/// Four charts, one per week: chart i has wheel 'w<i>.webp', the moon i+1
/// signs on from the sun, rising i+2, Venus i, Mercury 0, Mars 6, fire
/// 0.1*(i+1), earth 0.2, air 0.3, water 0.4, theme 'Theme <i>' and insights
/// 'A<i>', 'B<i>', 'C<i>'.
List<AstralChart> sampleCharts() {
  final charts = <AstralChart>[];
  for (var i = 0; i < 4; i++) {
    charts.add(AstralChart(
      wheel: 'w$i.webp',
      moon: i + 1,
      rising: i + 2,
      venus: i,
      mercury: 0,
      mars: 6,
      fire: 0.1 * (i + 1),
      earth: 0.2,
      air: 0.3,
      water: 0.4,
      theme: _l('Theme $i', 'Tema $i'),
      insights: [_l('A$i', 'A$i PT'), _l('B$i', 'B$i PT'), _l('C$i', 'C$i PT')],
    ));
  }
  return charts;
}

/// Two courses: Sky (0) and Moon (1).
List<Course> sampleCourses() => [
  Course(
    title: _l('Sky', 'Céu'),
    level: _l('Advanced', 'Avançado'),
    summary: _l('All about the sky.', 'Tudo sobre o céu.'),
    length: _l('12 lessons', '12 aulas'),
    price: _l('\$290', 'R\$ 1.490'),
    image: 'sky.jpg',
  ),
  Course(
    title: _l('Moon', 'Lua'),
    level: _l('Beginner', 'Iniciante'),
    summary: _l('All about the moon.', 'Tudo sobre a lua.'),
    length: _l('6 lessons', '6 aulas'),
    price: _l('\$149', 'R\$ 790'),
    image: 'moon.jpg',
  ),
];

/// A small state to start tests from.
State sample({
  String birthDay = '12',
  String birthMonth = '8',
  bool dateInvalid = false,
  num readingStage = 0,
  num courseIndex = 0,
  num enrolledCourse = -1,
  num consultSlot = 0,
  bool consultBooked = false,
}) => State(
  birthDay: birthDay,
  birthMonth: birthMonth,
  dateInvalid: dateInvalid,
  readingStage: readingStage,
  charts: sampleCharts(),
  courses: sampleCourses(),
  courseIndex: courseIndex,
  enrolledCourse: enrolledCourse,
  consultSlot: consultSlot,
  consultBooked: consultBooked,
);
