import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/home/Group%20screens/group_chats.dart';
import 'package:finmate/screens/home/Group%20screens/group_members.dart';
import 'package:finmate/screens/home/Group%20screens/group_settings.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/other_widgets.dart';
import 'package:finmate/widgets/transaction_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupOverview extends ConsumerStatefulWidget {
  const GroupOverview({super.key, required this.group});
  final Group group;

  @override
  ConsumerState<GroupOverview> createState() => _GroupOverviewState();
}

class _GroupOverviewState extends ConsumerState<GroupOverview> {
  bool isOverviewTabSelected = true;
  bool isChatTabSelected = false;
  bool isMembersTabSelected = false;
  int _selectedIndex = 0;
  List<String> tabTitles = ["Overview", "Chats", "Members"];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: 0,
      child: Scaffold(
        backgroundColor: color4,
        appBar: _appBar(),
        body: _body(),
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: color4,
      centerTitle: true,
      title: Text(widget.group.name ?? "Group Overview"),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: CustomTabBar(
          selectedIndex: _selectedIndex,
          tabTitles: tabTitles,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigate().push(GroupSettings(group: widget.group));
          },
          icon: Icon(Icons.settings),
        ),
        sbw10,
      ],
    );
  }

  Widget _body() {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        GrpOverview(group: widget.group),
        GroupChats(group: widget.group),
        GroupMembers(group: widget.group),
      ],
    );
  }
}

// __________________________________________________________________________ //

class GrpOverview extends ConsumerStatefulWidget {
  const GrpOverview({super.key, required this.group});
  final Group group;

  @override
  ConsumerState<GrpOverview> createState() => _GrpOverviewState();
}

class _GrpOverviewState extends ConsumerState<GrpOverview> {
  @override
  Widget build(BuildContext context) {
    final UserData userData = ref.watch(userDataNotifierProvider);
    final List<UserData>? groupMembersData = widget.group.listOfMembers;

    return Scaffold(
      backgroundColor: color4,
      body: SingleChildScrollView(
        child: Column(
          children: [
            showBalanceContainer(widget.group, userData, groupMembersData),
            groupTransactionsBox(widget.group),
          ],
        ),
      ),
    );
  }

  Widget showBalanceContainer(
    Group groupData,
    UserData userData,
    List<UserData>? groupMembersData,
  ) {
    rightMarginAmount(UserData member) {
      return (1 -
              (double.parse(groupData.membersBalance?[member.uid] ?? "0.0") /
                  double.parse(groupData.totalAmount ?? "0.0"))) *
          (MediaQuery.of(context).size.width * .8);
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        vertical: 25,
        horizontal: 20,
      ),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color2.withAlpha(180),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: TextStyle(
                  color: color4,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Text(
                '${groupData.totalAmount} ₹',
                style: TextStyle(
                  color: color4,
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              ),
            ],
          ),
          Container(
            margin: EdgeInsets.only(top: 10),
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 10,
              children: [
                ...groupMembersData!.map((member) {
                  final memberBalance =
                      groupData.membersBalance?[member.uid] ?? "0.0";
                  // member horizontal bars
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      height: 60,
                      width: double.infinity,
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: groupMemberBarColor.withAlpha(104),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: (double.parse(memberBalance) <= 0)
                                ? Colors.red
                                : color4),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // balance bar
                          Container(
                            height: double.infinity,
                            width: double.infinity,
                            alignment: Alignment.centerLeft,
                            margin: EdgeInsets.only(
                              right: rightMarginAmount(member),
                              left: 10,
                            ),
                            decoration: BoxDecoration(
                              color: groupMemberBarColor,
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          // member image
                          Align(
                            alignment: Alignment.centerLeft,
                            child: userProfilePicInCircle(
                              imageUrl: member.pfpURL ?? '',
                              outerRadius: 28,
                              innerRadius: 25,
                            ),
                          ),
                          // member balance
                          Text(
                            "$memberBalance ₹",
                            style: TextStyle(
                              color: (double.parse(memberBalance) <= 0)
                                  ? Colors.red
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget groupTransactionsBox(Group group) {
    List<Transaction>? listOfTransactions = group.listOfTransactions;
    // Sort transactions by date and time in descending order
    listOfTransactions?.sort((a, b) {
      int dateComparison = b.date!.compareTo(a.date!);
      if (dateComparison != 0) {
        return dateComparison;
      } else {
        return b.time!.format(context).compareTo(a.time!.format(context));
      }
    });

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 25),
      child: Stack(
        children: [
          Container(
            alignment: Alignment.center,
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            margin: EdgeInsets.symmetric(
              vertical: 10,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            child: group.listOfTransactions!.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "No Transactions Found ❗",
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Column(
                    spacing: 10,
                    children: [
                      ...listOfTransactions!.take(4).map((transaction) =>
                          transactionTile(context, transaction, ref)),
                    ],
                  ),
          ),
          Container(
            color: color4,
            padding: EdgeInsets.symmetric(horizontal: 10),
            margin: EdgeInsets.only(left: 15),
            child: Text(
              "Recent Transactions",
              style: TextStyle(
                color: color3,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
