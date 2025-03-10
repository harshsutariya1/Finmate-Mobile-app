import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/home/Group%20screens/group_chats.dart';
import 'package:finmate/screens/home/Group%20screens/group_members.dart';
import 'package:finmate/widgets/other_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupOverview extends ConsumerStatefulWidget {
  const GroupOverview({super.key, required this.group});
  final Group group;

  @override
  ConsumerState<GroupOverview> createState() => _GroupOverviewState();
}

class _GroupOverviewState extends ConsumerState<GroupOverview> {
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
      bottom: TabBar(
        tabs: [
          Tab(
            text: "Overview",
          ),
          Tab(
            text: "Chat",
          ),
          Tab(
            text: "Members",
          ),
        ],
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: color3,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.normal,
          color: Colors.blueGrey,
        ),
        indicatorColor: color3,
      ),
    );
  }

  Widget _body() {
    return TabBarView(children: [
      GrpOverview(group: widget.group),
      GroupChats(group: widget.group),
      GroupMembers(group: widget.group),
    ]);
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
    final groupMembersData = ref.read(allAppUsers).whenData(
          (value) => value.where(
              (user) => widget.group.memberIds?.contains(user.uid) ?? false),
        );
    // final Transaction groupTransactions =  ;

    return Scaffold(
      backgroundColor: color4,
      body: ListView(
        children: [
          showBalanceContainer(widget.group, userData, groupMembersData),
          groupTransactionsBox(widget.group),
        ],
      ),
    );
  }

  Widget showBalanceContainer(
    Group groupData,
    UserData userData,
    AsyncValue<Iterable<UserData>> groupMembersData,
  ) {
    return Container(
      width: double.infinity,
      height: 300,
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
          groupMembersData.when(
            data: (members) => Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 10,
                  children: [
                    ...members.map((member) {
                      return Expanded(
                        child: Container(
                          height: double.infinity,
                          padding: EdgeInsets.all(2),
                          margin: EdgeInsets.only(top: 10, bottom: 0),
                          decoration: BoxDecoration(
                            color: color4,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Stack(
                            children: [
                              Container(
                                padding: EdgeInsets.all(5),
                                margin: EdgeInsets.only(top: 0),
                                decoration: BoxDecoration(
                                  color: color2,
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                height: double.infinity,
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: userProfilePicInCircle(
                                  imageUrl: member.pfpURL ?? '',
                                  outerRadius: 22,
                                  innerRadius: 20,
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
            ),
            loading: () => Center(child: CircularProgressIndicator.adaptive()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ],
      ),
    );
  }

  Widget groupTransactionsBox(Group group) {
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
            child: group.transactionIds!.isEmpty
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
                      ...group.listOfTransactions!.map((transaction) =>
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
