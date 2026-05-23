import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/home/home_page.dart';

import '../../../helper/helper.dart';

void main() {
  late MockHomeBloc homeBloc;

  setUp(() {
    homeBloc = MockHomeBloc();
    when(() => homeBloc.state).thenReturn(const HomeState());
  });

  Widget buildSubject() => BlocProvider<HomeBloc>.value(
        value: homeBloc,
        child: const HomePage(),
      );

  group('$HomePage', () {
    goldenTest(
      'default state',
      fileName: 'home_page_default',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(buildSubject()),
    );
  });
}
