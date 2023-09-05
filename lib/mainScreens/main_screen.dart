import 'package:flutter/material.dart';
import '../tabpages/earning_driver_tab.dart';
import '../tabpages/profile_tab.dart';
import '../tabpages/counteroffer_tab.dart';
import '../tabpages/services_passenger_tab.dart';
import '../tabpages/chat_tab.dart';
import '../widgets/notification_indicator.dart';

class MainScreen extends StatefulWidget {
  final Widget body;
  final bool isDriver;

  MainScreen({required this.body, required this.isDriver});

  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  TabController? tabController;
  int selectedIndex = 0;
  Widget? currentBody;
  int counterOffersBadgeCount = 0;
  int messagesBadgeCount = 0;

  void initState() {
    super.initState();

    currentBody = widget.body;
    tabController = TabController(length: 5, vsync: this);
  }

  onItemClicked(int index) {
    setState(() {
      selectedIndex = index;
      tabController!.index = selectedIndex;
      if (selectedIndex == 0) {
        currentBody = widget.body;
      } else {
        switch (selectedIndex) {
          case 1:
            currentBody = widget.isDriver ? EarningsTabPage() : ServicesTab();
            break;
          case 2:
            currentBody = CounterOffersTab();
            counterOffersBadgeCount = 0;
            break;
          case 3:
            currentBody = ChatTab();
            messagesBadgeCount = 0;
            break;
          case 4:
            currentBody = ProfileTabPage();
            break;
        }
      }
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: currentBody ?? widget.body,
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(widget.isDriver ? Icons.credit_card : Icons.notifications),
            label: widget.isDriver ? "Ganancias" : "Servicios",
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(Icons.swap_horiz),
                if (counterOffersBadgeCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: NotificationIndicator(),
                  ),
              ],
            ),
            label: "Contraofertas",
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(Icons.message),
                if (messagesBadgeCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: NotificationIndicator(),
                  ),
              ],
            ),
            label: "Mensajes",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Cuenta"),
        ],
        unselectedItemColor: Colors.amber,
        selectedItemColor: Colors.white,
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 10),
        showUnselectedLabels: true,
        currentIndex: selectedIndex,
        onTap: onItemClicked,
      ),
    );
  }
}
