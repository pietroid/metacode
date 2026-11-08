// sample: test fixtures. `app` runs actions and values like the engine;
// `sample(...)` builds a State (every field has a default).
import '../../.generated/state.dart';
import '../../.generated/test_app.dart';

/// Runs actions and values through the compiled program, like the engine.
final app = TestApp();

Localized _l(String en, String ptBr) => Localized(en: en, ptBr: ptBr);

Program _sampleProgram(
  String title,
  ProgramKind kind,
  num cost,
  String code,
  String image,
) => Program(
  time: '10:00',
  title: _l(title, '$title PT'),
  place: _l('Somewhere', 'Algum lugar'),
  kind: kind,
  cost: cost,
  image: image,
  ticketCode: code,
  ticketDetail: _l('Seat 1A', 'Assento 1A'),
  ticketNote: _l('Be early', 'Chegue cedo'),
);

/// Two trips; the first has two days: day 1 in Sintra (food 40) with a train
/// (5), a palace (20) and a free walk with no photo; day 2 in Porto (food 30)
/// with a flight (70). The second has one day (food 12.5) and no plans.
List<Trip> sampleTrips() => [
  Trip(
    name: _l('Portugal', 'Portugal PT'),
    places: _l('Lisbon · Sintra', 'Lisboa · Sintra'),
    dates: _l('Nov 15 – 16', '15 a 16 de nov'),
    cover: 'cover.jpg',
    days: [
      TripDay(
        city: _l('Sintra', 'Sintra'),
        date: _l('Sat, Nov 15', 'Sáb, 15 de nov'),
        dayOfMonth: 15,
        image: 'sintra.jpg',
        food: 40,
        programs: [
          _sampleProgram('Train', ProgramKind.transport, 5, 'CP-1', 'sintra.jpg'),
          _sampleProgram('Palace', ProgramKind.attraction, 20, 'PENA-1', 'pena.jpg'),
          _sampleProgram('Walk', ProgramKind.attraction, 0, '', ''),
        ],
      ),
      TripDay(
        city: _l('Porto', 'Porto'),
        date: _l('Sun, Nov 16', 'Dom, 16 de nov'),
        dayOfMonth: 16,
        image: 'porto.jpg',
        food: 30,
        programs: [
          _sampleProgram('Flight', ProgramKind.transport, 70, 'FR-1', 'porto.jpg'),
        ],
      ),
    ],
  ),
  Trip(
    name: _l('Kyoto', 'Quioto'),
    places: _l('Kyoto', 'Quioto'),
    dates: _l('Apr 3', '3 de abr'),
    cover: 'kyoto.jpg',
    days: [
      TripDay(
        city: _l('Kyoto', 'Quioto'),
        date: _l('Fri, Apr 3', 'Sex, 3 de abr'),
        dayOfMonth: 3,
        image: 'kyoto.jpg',
        food: 12.5,
        programs: [],
      ),
    ],
  ),
];

/// A small state to start tests from.
State sample({
  List<Trip>? trips,
  num tripIndex = 0,
  num dayIndex = 0,
  ProgramFilter filter = ProgramFilter.all,
  num programIndex = 0,
  String budgetDraft = '',
}) => State(
  trips: trips ?? sampleTrips(),
  tripIndex: tripIndex,
  dayIndex: dayIndex,
  filter: filter,
  programIndex: programIndex,
  budgetDraft: budgetDraft,
);
