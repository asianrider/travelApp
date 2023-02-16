import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:travel_hour/blocs/ads_bloc.dart';
import 'package:travel_hour/blocs/notification_bloc.dart';
import 'package:travel_hour/pages/blogs.dart';
import 'package:travel_hour/pages/bookmark.dart';
import 'package:travel_hour/pages/explore.dart';
import 'package:travel_hour/pages/profile.dart';
import 'package:provider/provider.dart';
import 'package:travel_hour/pages/states.dart';
import 'package:travel_hour/services/app_service.dart';
import 'package:travel_hour/utils/snacbar.dart';
import 'package:easy_localization/easy_localization.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  PageController _pageController = PageController();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  List<IconData> iconList = [
    Feather.home,
    Feather.grid,
    Feather.list,
    Feather.bookmark,
    FontAwesome.map,
//    Feather.user
  ];

  void onTabTapped(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(index, curve: Curves.easeIn, duration: Duration(milliseconds: 300));
  }

  Future configureAds() async {
    await context.read<AdsBloc>().initiateAdsOnApp();
    context.read<AdsBloc>().loadAds();
  }

  @override
  void initState() {
    super.initState();
    AppService().checkInternet().then((hasInternet) {
      if (hasInternet == false) {
        context.openSnackBar('no internet'.tr());
      }
    });

    // Future.d(elayed(Duration(milliseconds: 0)).then((value) async {
    //   await context.read<NotificationBloc>().initFirebasePushNotification(context);
    //   await context.read<AdsBloc>().checkAdsEnable().then((isEnabled) async {
    //     if (isEnabled != null && isEnabled == true) {
    //       debugPrint('ads enabled true');
    //       configureAds(); /* enable this line to enable ads on the app */

    //     } else {
    //       debugPrint('ads enabled false');
    //     }
    //   });
    // });)
  }

  @override
  void dispose() {
    _pageController.dispose();
    context.read<AdsBloc>().dispose();
    super.dispose();
  }

  Future _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      _pageController.animateToPage(0, duration: Duration(milliseconds: 300), curve: Curves.easeIn);
    } else {
      await SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => await _onWillPop(),
      child: Scaffold(
        key: scaffoldKey,
        bottomNavigationBar: AnimatedBottomNavigationBar(
          icons: iconList,
          activeColor: Theme.of(context).primaryColor,
          gapLocation: GapLocation.none,
          activeIndex: _currentIndex,
          inactiveColor: Colors.grey[500],
          splashColor: Theme.of(context).primaryColor,
          iconSize: 22,
          onTap: (index) => onTabTapped(index),
        ),
        body: PageView(
          controller: _pageController,
          physics: NeverScrollableScrollPhysics(),
          children: <Widget>[
            Explore(),
            StatesPage(),
            BlogPage(),
            BookmarkPage(),
            DogName("Gâchette"),
//            ProfilePage(),
          ],
        ),
      ),
    );
  }
}

class DogName extends StatefulWidget {
  final String name;
  const DogName(this.name);
  @override
  DogState createState() {
    return DogState();
  }
}

class DogState extends State<DogName> with AutomaticKeepAliveClientMixin {
  final String token = 'sk.eyJ1IjoiYXNpYW5yaWRlciIsImEiOiJja3ZwMjN3eGQxb3Y5MnJvdTB5Z295ZXloIn0.Pcb1ygImlXoSJCrL9c_98w';
  final String streets_style = 'mapbox://styles/mapbox/streets-v11';
  final String outdoor_style = 'mapbox://styles/mapbox/outdoors-v11';
  final String style = 'http://127.0.0.1:8090/style.json';
  MapboxMap? mapboxMap;

  @override
  bool get wantKeepAlive => true;

  void _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: DecoratedBox(
            decoration: BoxDecoration(color: Colors.lightBlueAccent),
            child: MapWidget(
              key: ValueKey("mapWidget"),
              resourceOptions: ResourceOptions(accessToken: token),
              onMapCreated: _onMapCreated,
              styleUri: style,
            )));
  }
  // MapboxMap(
  //   accessToken: token,
  //   styleString: style,
  //   initialCameraPosition: CameraPosition(
  //     zoom: 5.0,
  //     target: LatLng(14.508, 46.048),
  //   ),
  // )));

}
