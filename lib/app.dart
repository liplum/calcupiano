import 'package:animations/animations.dart';
import 'package:calcupiano/design/animated.dart';
import 'package:calcupiano/design/multiplatform.dart';
import 'package:calcupiano/theme/theme.dart';
import 'package:calcupiano/ui/piano.dart';
import 'package:calcupiano/ui/screen.dart';
import 'package:calcupiano/ui/settings.dart';
import 'package:calcupiano/ui/soundpack.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:rettulf/rettulf.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'db.dart';

class CalcuPianoApp extends StatefulWidget {
  const CalcuPianoApp({super.key});

  @override
  State<StatefulWidget> createState() => CalcuPianoAppState();
}

class CalcuPianoAppState extends State<CalcuPianoApp> {
  bool? isDarkModeInitial;

  @override
  void initState() {
    super.initState();
    final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
    final isSystemDarkMode = brightness == Brightness.dark;
    isDarkModeInitial = H.isDarkMode ?? isSystemDarkMode;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CalcuPianoThemeModel>(
            create: (_) => CalcuPianoThemeModel(CalcuPianoThemeData.isDarkMode(isDarkModeInitial))),
      ],
      child: Consumer<CalcuPianoThemeModel>(
        builder: (_, model, __) {
          return MaterialApp(
            theme: bakeTheme(context, ThemeData.light(), model.data),
            darkTheme: bakeTheme(context, ThemeData.dark(), model.data),
            themeMode: model.resolveThemeMode(),
            home: const CalcuPianoHomePage(),
          );
        },
      ),
    );
  }

  ThemeData bakeTheme(BuildContext ctx, ThemeData raw, CalcuPianoThemeData theme) {
    return raw.copyWith(
      cardTheme: raw.cardTheme.copyWith(
        shape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.transparent), //the outline color
            borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      appBarTheme: const AppBarTheme(elevation: 0),
      splashColor: theme.enableRipple ? null : Colors.transparent,
      highlightColor: theme.enableRipple ? null : Colors.transparent,
      // TODO: Temporarily debug Visual effects on iOS.
      //  platform: TargetPlatform.iOS,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: SharedAxisPageTransitionsBuilder(transitionType: SharedAxisTransitionType.horizontal),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}

class CalcuPianoHomePage extends StatefulWidget {
  const CalcuPianoHomePage({super.key});

  @override
  State<CalcuPianoHomePage> createState() => _CalcuPianoHomePageState();
}

class _CalcuPianoHomePageState extends State<CalcuPianoHomePage> {
  @override
  Widget build(BuildContext context) {
    return context.isPortrait ? const HomePortrait() : const HomeLandscape();
  }
}

class HomePortrait extends StatefulWidget {
  const HomePortrait({super.key});

  @override
  State<StatefulWidget> createState() => _HomePortraitState();
}

class _HomePortraitState extends State<HomePortrait> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AnimationController ctrl;
  bool _isDrawerOpen = false;

  @override
  void initState() {
    super.initState();
    ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 500),
    );
  }

  @override
  void didUpdateWidget(covariant HomePortrait oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isOpen = _scaffoldKey.currentState?.isDrawerOpen;
    if (isOpen != null && isOpen != _isDrawerOpen) {
      setState(() {
        _isDrawerOpen = isOpen;
      });
    }
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _closeDrawer(BuildContext ctx) {
    ctx.navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final fullSize = MediaQuery.of(context).size;
    return Scaffold(
      key: _scaffoldKey,
      drawer: CalcuPianoDrawer(
        onCloseDrawer: () {
          _closeDrawer(context);
        },
      ),
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          ctrl.forward();
        } else {
          ctrl.reverse();
        }
        if (isOpened != _isDrawerOpen) {
          setState(() {
            _isDrawerOpen = isOpened;
          });
        }
      },
      body: AnimatedScale(
        scale: _isDrawerOpen ? 0.96 : 1,
        curve: Curves.fastLinearToSlowEaseIn,
        duration: Duration(milliseconds: 1000),
        child: [
          buildMain(context, ctrl, _isDrawerOpen),
          AnimatedBlur(
            blur: _isDrawerOpen ? 3 : 0,
            curve: Curves.fastLinearToSlowEaseIn,
            duration: Duration(milliseconds: 1000),
            child: SizedBox(
              width: fullSize.width,
              height: fullSize.height,
            ),
          ),
        ].stack(),
      ),
    );
  }

  Widget buildMain(BuildContext ctx, AnimationController ctrl, bool isDrawerOpen) {
    return Scaffold(
      body: [
        IconButton(
          icon: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: CurveTween(curve: Curves.easeIn).animate(ctrl),
          ),
          onPressed: () {
            if (ctrl.isCompleted) {
              ctrl.reverse();
            } else {
              ctrl.forward().then((value) {
                _openDrawer();
              });
            }
          },
        ).safeArea(),
        [
          const Screen().expanded(),
          // Why doesn't the constraint apply on this?
          const PianoKeyboard().expanded(),
        ]
            .column(
              mas: MainAxisSize.min,
              maa: MainAxisAlignment.center,
            )
            .safeArea()
      ].stack(),
    );
  }
}

class HomeLandscape extends StatefulWidget {
  const HomeLandscape({super.key});

  @override
  State<HomeLandscape> createState() => _HomeLandscapeState();
}

class _Page {
  const _Page._();

  static const piano = 0;
  static const settings = 0;
}

class _HomeLandscapeState extends State<HomeLandscape> {
  int _curPage = _Page.piano;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: [
        NavigationRail(
          minWidth: 30,
          selectedIndex: _curPage,
          onDestinationSelected: (dest) {
            setState(() {
              _curPage = dest;
            });
          },
          groupAlignment: 1.0,
          labelType: NavigationRailLabelType.all,
          destinations: [
            NavigationRailDestination(
              icon: const Icon(Icons.piano_outlined),
              selectedIcon: const Icon(Icons.piano),
              label: "Music".text(),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: "Settings".text(),
            ),
          ],
        ),
        const VerticalDivider(thickness: 1, width: 1),
        AnimatedSwitcher(
          duration: Duration(milliseconds: 200),
          child: routePage(),
        ).expanded(),
      ].row(),
    );
  }

  Widget buildBody() {
    return [
      const Screen().expanded(),
      // Why doesn't the constraint apply on this?
      const PianoKeyboard().expanded(),
    ]
        .row(
          mas: MainAxisSize.min,
          maa: MainAxisAlignment.center,
        )
        .safeArea();
  }

  Widget routePage() {
    switch (_curPage) {
      case _Page.piano:
        return buildBody();
      default:
        return const SettingsPage();
    }
  }
}

class CalcuPianoDrawer extends HookWidget {
  final VoidCallback? onCloseDrawer;

  const CalcuPianoDrawer({super.key, this.onCloseDrawer});

  void closeDrawer() {
    onCloseDrawer?.call();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Drawer(
        child: [
          Column(
            children: [
              DrawerHeader(child: SizedBox()).flexible(flex: 1),
              ListTile(
                leading: Icon(Icons.music_note),
                title: Text('Soundpack'),
                trailing: Icon(Icons.navigate_next),
                onTap: () {
                  closeDrawer();
                  context.navigator.push(MaterialPageRoute(builder: (ctx) => SoundpackPage()));
                },
              )
            ],
          ).expanded(),
          Spacer(),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              closeDrawer();
              context.navigator.push(MaterialPageRoute(builder: (ctx) => SettingsPage()));
            },
          ),
        ].column(),
      ),
    );
  }
}
