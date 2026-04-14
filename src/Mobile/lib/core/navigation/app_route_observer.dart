import 'package:flutter/material.dart';

/// [MaterialApp.router] / [GoRouter] ile aynı Navigator’a bağlanır;
/// alt sayfadan (oda/konu sohbeti vb.) dönünce [RouteAware.didPopNext] tetiklenir.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
